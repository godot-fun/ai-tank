#!/usr/bin/env python3
"""Batch convert video files to OGV (Theora + Vorbis) using FFmpeg."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

VIDEO_EXTENSIONS = {
    ".mp4",
    ".mkv",
    ".mov",
    ".avi",
    ".webm",
    ".wmv",
    ".flv",
    ".m4v",
    ".mpeg",
    ".mpg",
    ".ts",
    ".mts",
    ".m2ts",
    ".3gp",
    ".ogv",
    ".ogg",
}

DEFAULT_VIDEO_QUALITY = 6
DEFAULT_AUDIO_QUALITY = 6
MAX_QUALITY = 10
GAME_STANDARD_SAMPLE_RATE = 48000
THEORA_CODEC = "libtheora"
VORBIS_CODEC = "libvorbis"
LOSSLESS_VIDEO_CODEC = "ffv1"
LOSSLESS_AUDIO_CODEC = "flac"
LOSSLESS_CONTAINER = ".mkv"
THEORA_BITRATE_MULTIPLIER = 1.5
NULL_SINK = "NUL" if sys.platform == "win32" else "/dev/null"

LOSSLESS_VIDEO_CODECS = {
    "ffv1",
    "huffyuv",
    "ffvhuff",
    "utvideo",
    "rawvideo",
    "vble",
    "magicyuv",
}
LOSSLESS_AUDIO_CODECS = {
    "flac",
    "pcm_s16le",
    "pcm_s24le",
    "pcm_s32le",
    "pcm_f32le",
    "pcm_s16be",
    "pcm_s24be",
    "pcm_s32be",
    "pcm_f32be",
}


def find_repo_root(start: Path) -> Path | None:
    for parent in [start.resolve(), *start.resolve().parents]:
        if (parent / ".dependency" / "manifest.json").is_file():
            return parent
    return None


def resolve_executable(path: Path) -> Path:
    if path.is_file():
        return path
    if sys.platform == "win32" and path.suffix.lower() != ".exe":
        candidate = path.with_name(f"{path.name}.exe")
        if candidate.is_file():
            return candidate
    raise FileNotFoundError(path)


def resolve_tool_bin(repo_root: Path, tool_name: str) -> Path:
    manifest_path = repo_root / ".dependency" / "manifest.json"
    entry = json.loads(manifest_path.read_text(encoding="utf-8")).get(tool_name)
    if not entry:
        print(
            f"Tool '{tool_name}' not found in .dependency/manifest.json. "
            "See .cursor/rules/skill-dependency-manager.md",
            file=sys.stderr,
        )
        sys.exit(1)
    if not entry.get("populated", False):
        print(
            f"Tool '{tool_name}' is not populated. "
            f"Install it under {repo_root / '.dependency' / tool_name} and set populated: true "
            "in .dependency/manifest.json.",
            file=sys.stderr,
        )
        sys.exit(1)

    bin_rel = entry["bin"]
    if isinstance(bin_rel, list):
        bin_rel = bin_rel[0]
    try:
        return resolve_executable(repo_root / bin_rel)
    except FileNotFoundError:
        print(
            f"Executable for '{tool_name}' not found at {repo_root / bin_rel}. "
            "Check .dependency/manifest.json bin path.",
            file=sys.stderr,
        )
        sys.exit(1)


def resolve_ffmpeg() -> Path:
    repo_root = find_repo_root(Path(__file__))
    if repo_root is None:
        print(
            "Could not find .dependency/manifest.json by walking up from this script. "
            "Run from a repo that follows .cursor/rules/skill-dependency-manager.md.",
            file=sys.stderr,
        )
        sys.exit(1)
    return resolve_tool_bin(repo_root, "ffmpeg")


def resolve_ffprobe(ffmpeg: Path) -> Path:
    name = "ffprobe.exe" if sys.platform == "win32" else "ffprobe"
    candidate = ffmpeg.with_name(name)
    if candidate.is_file():
        return candidate
    raise FileNotFoundError(candidate)


def get_video_files(path: Path, recurse: bool) -> list[Path]:
    if path.is_file():
        if path.suffix.lower() not in VIDEO_EXTENSIONS:
            print(f"Not a supported video file: {path}", file=sys.stderr)
            sys.exit(1)
        return [path.resolve()]

    if not path.is_dir():
        print(f"Input path not found: {path}", file=sys.stderr)
        sys.exit(1)

    if recurse:
        candidates = path.rglob("*")
    else:
        candidates = path.iterdir()

    files = [
        item.resolve()
        for item in candidates
        if item.is_file() and item.suffix.lower() in VIDEO_EXTENSIONS
    ]
    return sorted(files)


def relative_path(file_path: Path, input_root: Path) -> str:
    try:
        return file_path.relative_to(input_root).as_posix()
    except ValueError:
        return file_path.name


def filter_output_files(files: list[Path], output_dir: Path) -> list[Path]:
    out = output_dir.resolve()
    kept: list[Path] = []
    for file_path in files:
        try:
            file_path.resolve().relative_to(out)
        except ValueError:
            kept.append(file_path)
    return kept


def find_source_collisions(
    files: list[Path], input_root: Path, output_dir: Path
) -> list[tuple[Path, Path]]:
    collisions: list[tuple[Path, Path]] = []
    for file_path in files:
        rel = relative_path(file_path, input_root)
        out_rel = Path(rel).with_suffix(".ogv").as_posix()
        out_path = output_dir / out_rel
        if out_path.resolve() == file_path.resolve():
            collisions.append((file_path, out_path))
    return collisions


def output_rel_path(file_path: Path, input_root: Path) -> str:
    rel = relative_path(file_path, input_root)
    return Path(rel).with_suffix(".ogv").as_posix()


def parse_bitrate(value: object) -> int | None:
    if value is None:
        return None
    try:
        rate = int(value)
    except (TypeError, ValueError):
        return None
    return rate if rate > 0 else None


def probe_streams(ffprobe: Path, file_path: Path) -> dict:
    result = subprocess.run(
        [
            str(ffprobe),
            "-v",
            "quiet",
            "-print_format",
            "json",
            "-show_streams",
            str(file_path),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return {"video": {}, "audio": {}}

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"video": {}, "audio": {}}

    video: dict = {}
    audio: dict = {}
    for stream in payload.get("streams") or []:
        codec_type = stream.get("codec_type")
        if codec_type == "video" and not video:
            video = {
                "codec": stream.get("codec_name", ""),
                "width": stream.get("width"),
                "height": stream.get("height"),
                "bit_rate": parse_bitrate(stream.get("bit_rate")),
            }
        elif codec_type == "audio" and not audio:
            sample_rate = stream.get("sample_rate")
            try:
                sample_rate = int(sample_rate) if sample_rate else None
            except (TypeError, ValueError):
                sample_rate = None
            channels = stream.get("channels")
            try:
                channels = int(channels) if channels is not None else None
            except (TypeError, ValueError):
                channels = None
            audio = {
                "codec": stream.get("codec_name", ""),
                "sample_rate": sample_rate,
                "channels": channels,
                "bit_rate": parse_bitrate(stream.get("bit_rate")),
            }

    return {"video": video, "audio": audio}


def is_lossless_source(probe: dict) -> bool:
    video = probe.get("video") or {}
    if not video:
        return False
    if video.get("codec") not in LOSSLESS_VIDEO_CODECS:
        return False
    audio = probe.get("audio") or {}
    if not audio:
        return True
    return audio.get("codec") in LOSSLESS_AUDIO_CODECS


def lossless_rel_path(file_path: Path, input_root: Path) -> str:
    rel = relative_path(file_path, input_root)
    return Path(rel).with_suffix(LOSSLESS_CONTAINER).as_posix()


def export_lossless_intermediate(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    probe: dict,
    sample_rate: int | None,
    channels: int | None,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
        "-map",
        "0:v:0",
        "-c:v",
        LOSSLESS_VIDEO_CODEC,
        "-level",
        "3",
        "-pix_fmt",
        "yuv420p",
    ]

    audio = probe.get("audio") or {}
    if audio:
        cmd.extend(["-map", "0:a:0"])
        if sample_rate is not None:
            cmd.extend(["-ar", str(sample_rate)])
        if channels is not None:
            cmd.extend(["-ac", str(channels)])
        cmd.extend(["-c:a", LOSSLESS_AUDIO_CODEC, "-compression_level", "0"])
    else:
        cmd.append("-an")

    cmd.append(str(out_path))
    run_ffmpeg(cmd, file_path, "lossless export")


def resolve_encode_source(
    ffmpeg: Path,
    ffprobe: Path,
    file_path: Path,
    input_root: Path,
    lossless_dir: Path,
    source_probe: dict,
    sample_rate: int | None,
    channels: int | None,
    use_lossless_intermediate: bool,
    overwrite: bool,
    dry_run: bool,
) -> tuple[Path, dict, str]:
    if not use_lossless_intermediate or is_lossless_source(source_probe):
        return file_path, source_probe, ""

    intermediate_rel = lossless_rel_path(file_path, input_root)
    intermediate_path = lossless_dir / intermediate_rel
    note = f"via {intermediate_rel}"

    if intermediate_path.exists() and not overwrite:
        if dry_run:
            return intermediate_path, source_probe, f"reuse {intermediate_rel}"
        intermediate_probe = probe_streams(ffprobe, intermediate_path)
        if intermediate_probe.get("video"):
            print(f"[reuse] {intermediate_rel}")
            return intermediate_path, intermediate_probe, note

    if dry_run:
        return intermediate_path, source_probe, f"export {intermediate_rel}"

    print(f"[lossless] {relative_path(file_path, input_root)} -> {intermediate_rel}")
    export_lossless_intermediate(
        ffmpeg,
        file_path,
        intermediate_path,
        source_probe,
        sample_rate,
        channels,
    )
    intermediate_probe = probe_streams(ffprobe, intermediate_path)
    return intermediate_path, intermediate_probe, note


def can_stream_copy(
    file_path: Path,
    probe: dict,
    sample_rate: int | None,
    channels: int | None,
    match_source: bool,
) -> bool:
    if match_source:
        return False
    if sample_rate is not None or channels is not None:
        return False
    if file_path.suffix.lower() not in {".ogv", ".ogg"}:
        return False
    video = probe.get("video") or {}
    audio = probe.get("audio") or {}
    if video.get("codec") != "theora":
        return False
    if not audio:
        return True
    return audio.get("codec") == "vorbis"


def build_ffmpeg_args(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    probe: dict,
    sample_rate: int | None,
    video_quality: int,
    audio_quality: int,
    channels: int | None,
    stream_copy: bool,
) -> list[str]:
    cmd = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
    ]
    if stream_copy:
        cmd.extend(["-c", "copy", str(out_path)])
        return cmd

    cmd.extend(["-c:v", THEORA_CODEC, "-q:v", str(video_quality)])

    audio = probe.get("audio") or {}
    if audio:
        if sample_rate is not None:
            cmd.extend(["-ar", str(sample_rate)])
        if channels is not None:
            cmd.extend(["-ac", str(channels)])
        cmd.extend(["-c:a", VORBIS_CODEC, "-q:a", str(audio_quality)])
    else:
        cmd.append("-an")

    cmd.append(str(out_path))
    return cmd


def run_ffmpeg(cmd: list[str], file_path: Path, phase: str) -> None:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(
            f"FFmpeg {phase} failed for: {file_path}"
            + (f"\n{detail}" if detail else "")
        )


def cleanup_passlog(prefix: str) -> None:
    for suffix in ("-0.log", "-0.log.mbtree"):
        path = Path(f"{prefix}{suffix}")
        if path.is_file():
            path.unlink()


def match_source_targets(probe: dict) -> tuple[int | None, int | None]:
    video = probe.get("video") or {}
    audio = probe.get("audio") or {}
    video_bps = video.get("bit_rate")
    audio_bps = audio.get("bit_rate")
    if video_bps:
        video_bps = int(video_bps * THEORA_BITRATE_MULTIPLIER)
    return video_bps, audio_bps


def convert_file_match_source(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    probe: dict,
    sample_rate: int | None,
    channels: int | None,
    video_bps: int | None,
    audio_bps: int | None,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    passlog_prefix = str(out_path.with_suffix(".pass"))

    if not video_bps:
        convert_file(
            ffmpeg,
            file_path,
            out_path,
            probe,
            sample_rate,
            MAX_QUALITY,
            MAX_QUALITY,
            channels,
            False,
        )
        return

    video_k = max(round(video_bps / 1000), 500)
    audio_k = max(round(audio_bps / 1000), 64) if audio_bps else None

    pass1 = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
        "-c:v",
        THEORA_CODEC,
        "-b:v",
        f"{video_k}k",
        "-pass",
        "1",
        "-passlogfile",
        passlog_prefix,
        "-an",
        "-f",
        "ogv",
        NULL_SINK,
    ]
    run_ffmpeg(pass1, file_path, "pass 1")

    pass2 = [
        str(ffmpeg),
        "-hide_banner",
        "-nostats",
        "-y",
        "-i",
        str(file_path),
        "-c:v",
        THEORA_CODEC,
        "-b:v",
        f"{video_k}k",
        "-pass",
        "2",
        "-passlogfile",
        passlog_prefix,
    ]

    audio = probe.get("audio") or {}
    if audio:
        if sample_rate is not None:
            pass2.extend(["-ar", str(sample_rate)])
        if channels is not None:
            pass2.extend(["-ac", str(channels)])
        if audio_k:
            pass2.extend(["-c:a", VORBIS_CODEC, "-b:a", f"{audio_k}k"])
        else:
            pass2.extend(["-c:a", VORBIS_CODEC, "-q:a", str(MAX_QUALITY)])
    else:
        pass2.append("-an")

    pass2.append(str(out_path))
    try:
        run_ffmpeg(pass2, file_path, "pass 2")
    finally:
        cleanup_passlog(passlog_prefix)


def convert_file(
    ffmpeg: Path,
    file_path: Path,
    out_path: Path,
    probe: dict,
    sample_rate: int | None,
    video_quality: int,
    audio_quality: int,
    channels: int | None,
    stream_copy: bool,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = build_ffmpeg_args(
        ffmpeg,
        file_path,
        out_path,
        probe,
        sample_rate,
        video_quality,
        audio_quality,
        channels,
        stream_copy,
    )
    run_ffmpeg(cmd, file_path, "convert")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Batch convert video files to OGV (Theora + Vorbis)."
    )
    parser.add_argument("input", help="Path to a single video file or directory")
    parser.add_argument(
        "-o",
        "--output-dir",
        default="",
        help="Output directory (must not overwrite sources; default: <input>/ogv)",
    )
    parser.add_argument(
        "-r", "--recurse", action="store_true", help="Process subdirectories"
    )
    parser.add_argument(
        "-s",
        "--sample-rate",
        type=int,
        help="Force audio sample rate in Hz (default: preserve source)",
    )
    parser.add_argument(
        "-vq",
        "--video-quality",
        type=int,
        choices=range(0, 11),
        default=DEFAULT_VIDEO_QUALITY,
        help=f"Theora quality 0-10 with --fast (default: {DEFAULT_VIDEO_QUALITY})",
    )
    parser.add_argument(
        "-aq",
        "--audio-quality",
        type=int,
        choices=range(0, 11),
        default=DEFAULT_AUDIO_QUALITY,
        help=f"Vorbis quality 0-10 with --fast (default: {DEFAULT_AUDIO_QUALITY})",
    )
    parser.add_argument(
        "--standardize",
        action="store_true",
        help="Resample audio to 48 kHz Vorbis (project batch preset)",
    )
    parser.add_argument(
        "--fast",
        action="store_true",
        help=(
            "Skip lossless intermediate; fixed Theora/Vorbis quality (-vq/-aq); "
            "smaller files, faster encode"
        ),
    )
    parser.add_argument(
        "--no-lossless",
        action="store_true",
        help=(
            "Skip FFV1+FLAC intermediate; 2-pass Theora directly from lossy source "
            "(faster, lower quality than default)"
        ),
    )
    parser.add_argument(
        "--lossless-dir",
        default="",
        help="Lossless intermediate directory (default: <input>/lossless)",
    )
    parser.add_argument(
        "--clean-lossless",
        action="store_true",
        help="Delete lossless intermediate MKV after successful OGV export",
    )
    channel_group = parser.add_mutually_exclusive_group()
    channel_group.add_argument(
        "--mono", action="store_true", help="Force mono audio output"
    )
    channel_group.add_argument(
        "--stereo", action="store_true", help="Force stereo audio output"
    )
    parser.add_argument(
        "--overwrite", action="store_true", help="Replace existing output files"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Preview without writing files"
    )
    return parser.parse_args()


def resolve_channels(args: argparse.Namespace) -> int | None:
    if args.mono:
        return 1
    if args.stereo:
        return 2
    return None


def resolve_forced_sample_rate(args: argparse.Namespace) -> int | None:
    if args.standardize:
        return GAME_STANDARD_SAMPLE_RATE
    return args.sample_rate


def resolve_match_source(args: argparse.Namespace) -> bool:
    return not args.fast


def resolve_lossless_intermediate(args: argparse.Namespace) -> bool:
    return not args.fast and not args.no_lossless


def describe_file_plan(
    probe: dict,
    forced_rate: int | None,
    video_quality: int,
    audio_quality: int,
    forced_channels: int | None,
    stream_copy: bool,
    match_source: bool,
    use_lossless_intermediate: bool,
    video_target_bps: int | None,
    audio_target_bps: int | None,
    intermediate_note: str,
) -> str:
    video = probe.get("video") or {}
    audio = probe.get("audio") or {}

    if stream_copy:
        w, h = video.get("width"), video.get("height")
        size = f"{w}x{h}" if w and h else "source"
        if audio:
            rate = audio.get("sample_rate")
            ch = audio.get("channels") or "?"
            return f"stream copy ({size}, {rate} Hz, {ch} ch)"
        return f"stream copy ({size}, no audio)"

    w, h = video.get("width"), video.get("height")
    size = f"{w}x{h}" if w and h else "source"
    via = f", {intermediate_note}" if intermediate_note else ""

    if match_source and use_lossless_intermediate:
        if not audio:
            if is_lossless_source(probe):
                return f"{size}, Theora q={MAX_QUALITY}, Vorbis q={MAX_QUALITY}, no audio"
            return f"{size}, FFV1+FLAC → Theora q={MAX_QUALITY}{via}, no audio"
        rate = f"{forced_rate} Hz" if forced_rate else "source rate"
        ch = {1: "mono", 2: "stereo"}.get(forced_channels, "preserve")
        if is_lossless_source(probe):
            return (
                f"{size}, Theora q={MAX_QUALITY}, Vorbis q={MAX_QUALITY}, "
                f"{rate}, {ch}"
            )
        return (
            f"{size}, FFV1+FLAC → Theora q={MAX_QUALITY}, "
            f"Vorbis q={MAX_QUALITY}, {rate}, {ch}{via}"
        )

    if match_source:
        if video_target_bps:
            video_part = f"Theora 2-pass ~{round(video_target_bps / 1000)}k"
        else:
            video_part = f"Theora q={MAX_QUALITY} (bitrate unknown)"
        if not audio:
            return f"{size}, {video_part}, no audio"
        rate = f"{forced_rate} Hz" if forced_rate else "source rate"
        ch = {1: "mono", 2: "stereo"}.get(forced_channels, "preserve")
        if audio_target_bps:
            audio_part = f"Vorbis ~{round(audio_target_bps / 1000)}k"
        else:
            audio_part = f"Vorbis q={MAX_QUALITY}"
        return f"{size}, {video_part}, {audio_part}, {rate}, {ch}"

    if not audio:
        return f"{size}, Theora q={video_quality}, no audio"

    rate = f"{forced_rate} Hz" if forced_rate else "source rate"
    ch = {1: "mono", 2: "stereo"}.get(forced_channels, "preserve")
    return f"{size}, Theora q={video_quality}, Vorbis q={audio_quality}, {rate}, {ch}"


def main() -> int:
    args = parse_args()
    ffmpeg = resolve_ffmpeg()
    ffprobe = resolve_ffprobe(ffmpeg)

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Input path not found: {args.input}", file=sys.stderr)
        return 1

    input_path = input_path.resolve()
    files = get_video_files(input_path, args.recurse)
    if not files:
        print(f"No supported video files found under: {args.input}")
        return 0

    if input_path.is_file():
        input_root = input_path.parent
    else:
        input_root = input_path

    output_dir = (
        Path(args.output_dir).resolve()
        if args.output_dir
        else input_root / "ogv"
    )
    lossless_dir = (
        Path(args.lossless_dir).resolve()
        if args.lossless_dir
        else input_root / "lossless"
    )

    forced_rate = resolve_forced_sample_rate(args)
    forced_channels = resolve_channels(args)
    match_source = resolve_match_source(args)
    use_lossless_intermediate = resolve_lossless_intermediate(args)

    initial_count = len(files)
    files = filter_output_files(files, output_dir)
    files = filter_output_files(files, lossless_dir)
    if not files:
        if initial_count:
            print(
                "No source files to process: all inputs lie under the output directory. "
                "Choose a separate output directory (default: ogv/).",
                file=sys.stderr,
            )
            return 1
        print(f"No supported video files found under: {args.input}")
        return 0

    collisions = find_source_collisions(files, input_root, output_dir)
    if collisions:
        print(
            "Refusing to overwrite source files. Use a separate output directory "
            "(default: ogv/).",
            file=sys.stderr,
        )
        for source, dest in collisions:
            print(f"  {source} -> {dest}", file=sys.stderr)
        return 1

    if use_lossless_intermediate:
        mode = (
            "lossless intermediate (FFV1+FLAC MKV in lossless/) → "
            f"Theora q={MAX_QUALITY}, Vorbis q={MAX_QUALITY} OGV"
        )
    elif match_source:
        mode = "match-source (2-pass Theora at 1.5x source video bitrate, matched audio)"
    elif args.standardize:
        mode = (
            f"standardize (48 kHz audio, vq={args.video_quality}, aq={args.audio_quality})"
        )
    else:
        mode = (
            f"Theora q={args.video_quality}, Vorbis q={args.audio_quality}, "
            "preserve resolution and frame rate"
        )
    print(f"Input:  {args.input}")
    print(f"Files:  {len(files)}")
    print(f"Mode:   {mode}")
    print(f"Output: {output_dir}")
    if use_lossless_intermediate:
        print(f"Lossless: {lossless_dir}")
    if args.dry_run:
        print("Run:    DRY RUN")
    print()

    ok = 0
    skip = 0
    fail = 0

    for file_path in files:
        rel = output_rel_path(file_path, input_root)
        out_path = output_dir / rel
        src_rel = relative_path(file_path, input_root)

        if out_path.exists() and not args.overwrite and not args.dry_run:
            print(f"[skip] {rel}")
            skip += 1
            continue

        probe = probe_streams(ffprobe, file_path)
        if not probe.get("video"):
            print(f"[fail] {src_rel} (no video stream)")
            fail += 1
            continue

        video_target_bps, audio_target_bps = match_source_targets(probe)
        stream_copy = can_stream_copy(
            file_path, probe, forced_rate, forced_channels, match_source
        )

        intermediate_note = ""
        encode_path = file_path
        encode_probe = probe
        intermediate_path: Path | None = None

        if match_source and use_lossless_intermediate and not stream_copy:
            encode_path, encode_probe, intermediate_note = resolve_encode_source(
                ffmpeg,
                ffprobe,
                file_path,
                input_root,
                lossless_dir,
                probe,
                forced_rate,
                forced_channels,
                use_lossless_intermediate,
                args.overwrite,
                args.dry_run,
            )
            intermediate_path = lossless_dir / lossless_rel_path(file_path, input_root)
            if not is_lossless_source(probe):
                video_target_bps, audio_target_bps = None, None

        plan = describe_file_plan(
            probe,
            forced_rate,
            args.video_quality,
            args.audio_quality,
            forced_channels,
            stream_copy,
            match_source,
            use_lossless_intermediate,
            video_target_bps,
            audio_target_bps,
            intermediate_note,
        )

        if args.dry_run:
            print(f"[plan] {src_rel} -> {rel} ({plan})")
            ok += 1
            continue

        try:
            print(f"[run]  {src_rel} -> {rel} ({plan})")
            if stream_copy:
                convert_file(
                    ffmpeg,
                    file_path,
                    out_path,
                    probe,
                    forced_rate,
                    args.video_quality,
                    args.audio_quality,
                    forced_channels,
                    True,
                )
            elif match_source and use_lossless_intermediate:
                convert_file(
                    ffmpeg,
                    encode_path,
                    out_path,
                    encode_probe,
                    forced_rate,
                    MAX_QUALITY,
                    MAX_QUALITY,
                    forced_channels,
                    False,
                )
            elif match_source:
                convert_file_match_source(
                    ffmpeg,
                    encode_path,
                    out_path,
                    encode_probe,
                    forced_rate,
                    forced_channels,
                    video_target_bps,
                    audio_target_bps,
                )
            else:
                convert_file(
                    ffmpeg,
                    encode_path,
                    out_path,
                    encode_probe,
                    forced_rate,
                    args.video_quality,
                    args.audio_quality,
                    forced_channels,
                    False,
                )
            if (
                args.clean_lossless
                and intermediate_path is not None
                and intermediate_path.is_file()
            ):
                intermediate_path.unlink()
                print(f"[clean] removed {lossless_rel_path(file_path, input_root)}")
            ok += 1
        except RuntimeError as exc:
            print(f"[fail] {rel}")
            print(exc)
            fail += 1

    print()
    print(f"Done. processed={ok} skipped={skip} failed={fail}")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
