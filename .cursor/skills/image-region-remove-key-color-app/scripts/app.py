"""
Gradio UI: paint a region, then remove key-color pixels only inside that region.

Run via manifest image-region-remove-key-color-app.bin — see SKILL.md.
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
import time
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

PRESETS = {
    "white": (255, 255, 255),
    "green": (0, 255, 0),
    "magenta": (255, 0, 255),
}
PRESET_TOLERANCE = {"white": 25, "green": 40, "magenta": 40}
DEFAULT_FEATHER = 2
DEFAULT_PORT = 7860
GRAY = (0x9E, 0x9E, 0x9E, 255)
MAX_DISPLAY_SIDE = 520
EDITOR_CHROME_PX = 56

_TEMP_DIR = Path(tempfile.mkdtemp(prefix="region_key_"))


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02x}{:02x}{:02x}".format(*rgb)


def parse_hex(color: str | None) -> tuple[int, int, int]:
    if not color:
        return PRESETS["white"]
    s = color.strip().lstrip("#")
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    if len(s) != 6:
        return PRESETS["white"]
    return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)


def load_rgba(path: str | Path) -> Image.Image:
    with Image.open(path) as img:
        return img.convert("RGBA")


def as_pil(image) -> Image.Image | None:
    """Normalize ImageEditor layer payloads (path / PIL / array) to RGBA."""
    if image is None:
        return None
    if isinstance(image, (str, Path)):
        return load_rgba(image)
    if isinstance(image, Image.Image):
        return image.convert("RGBA")
    return Image.fromarray(image).convert("RGBA")


def on_gray(image: Image.Image) -> Image.Image:
    """Bake transparency to opaque gray for Pixi / preview display."""
    rgba = image.convert("RGBA")
    return Image.alpha_composite(Image.new("RGBA", rgba.size, GRAY), rgba).convert("RGB")


def save_temp_png(image: Image.Image, name: str = "display.png") -> str:
    path = _TEMP_DIR / Path(name).name
    image.save(path, format="PNG")
    return str(path)


def download_name(name: str | None) -> str:
    if not name:
        return "result.png"
    return str(Path(name).with_suffix(".png").name)


def display_height(size: tuple[int, int], *, chrome: int = 0) -> int:
    w, h = size
    scale = min(MAX_DISPLAY_SIDE / max(w, h, 1), 1.0)
    return max(1, int(round(h * scale))) + chrome


def editor_update(source: Image.Image, name: str):
    """Build ImageEditor value + canvas sized to the image (no letterbox padding)."""
    import gradio as gr

    display = save_temp_png(on_gray(source), download_name(name))
    return gr.update(
        value={"background": display, "layers": [], "composite": display},
        canvas_size=source.size,
        height=display_height(source.size, chrome=EDITOR_CHROME_PX),
    )


def is_key_pixel(r, g, b, key, tolerance, *, white_mode: bool) -> bool:
    if white_mode:
        floor = 255 - tolerance
        return r >= floor and g >= floor and b >= floor
    kr, kg, kb = key
    return max(abs(r - kr), abs(g - kg), abs(b - kb)) <= tolerance


def editor_region_mask(editor_value: dict | None, size: tuple[int, int]) -> Image.Image:
    mask = Image.new("L", size, 0)
    if not editor_value:
        return mask
    for layer in editor_value.get("layers") or []:
        pil = as_pil(layer)
        if pil is None:
            continue
        if pil.size != size:
            pil = pil.resize(size, Image.Resampling.NEAREST)
        mask = ImageChops.lighter(mask, pil.split()[3])
    return mask


def remove_key_in_region(
    image: Image.Image,
    region_mask: Image.Image,
    *,
    key: tuple[int, int, int],
    tolerance: int,
    feather: int,
) -> Image.Image:
    rgba = image.convert("RGBA")
    width, height = rgba.size
    mask = region_mask.convert("L")
    if mask.size != (width, height):
        mask = mask.resize((width, height), Image.Resampling.NEAREST)

    pixels = list(rgba.getdata())
    mask_px = list(mask.getdata())
    white_mode = key == (255, 255, 255)
    keep = [255] * len(pixels)
    for i, (pixel, m) in enumerate(zip(pixels, mask_px)):
        if m and is_key_pixel(pixel[0], pixel[1], pixel[2], key, tolerance, white_mode=white_mode):
            keep[i] = 0

    if feather > 0:
        keep_img = Image.new("L", (width, height))
        keep_img.putdata(keep)
        keep = list(keep_img.filter(ImageFilter.GaussianBlur(radius=feather)).getdata())

    out = [
        (r, g, b, int(round(a * (k / 255.0))))
        for (r, g, b, a), k in zip(pixels, keep)
    ]
    result = Image.new("RGBA", (width, height))
    result.putdata(out)
    return result


def build_ui(
    *,
    preload_path: Path | None,
    default_preset: str,
    default_tolerance: int,
    default_feather: int,
):
    import gradio as gr

    path0 = str(preload_path) if preload_path else None
    name0 = preload_path.name if preload_path else ""
    initial = None
    initial_canvas = (800, 800)
    initial_height = MAX_DISPLAY_SIDE + EDITOR_CHROME_PX
    if preload_path is not None:
        source0 = load_rgba(preload_path)
        display = save_temp_png(on_gray(source0), download_name(name0))
        initial = {"background": display, "layers": [], "composite": display}
        initial_canvas = source0.size
        initial_height = display_height(source0.size, chrome=EDITOR_CHROME_PX)

    with gr.Blocks(title="image-region-remove-key-color-app") as demo:
        with gr.Row(elem_classes=["title-row"]):
            gr.Markdown("## image-region-remove-key-color-app", scale=1)
            stop_btn = gr.Button(
                "Stop server",
                variant="stop",
                scale=0,
                min_width=140,
                elem_id="stop-server-btn",
            )

        source_path = gr.State(path0)

        file_in = gr.File(
            label="Upload image (PNG with transparency OK)",
            file_types=["image"],
            type="filepath",
            value=path0,
        )

        with gr.Row(equal_height=False):
            editor = gr.ImageEditor(
                value=initial,
                show_label=False,
                type="filepath",
                image_mode="RGBA",
                format="png",
                brush=gr.Brush(default_size=8, colors=["#ff00ff"], color_mode="fixed"),
                layers=False,
                transforms=(),
                canvas_size=initial_canvas,
                fixed_canvas=False,
                height=initial_height,
                # Never load source PNGs here — Pixi canvas is white under alpha.
                sources=(),
                buttons=[],
            )
            preview = gr.Image(
                show_label=False,
                type="pil",
                format="png",
                image_mode="RGB",
                height=display_height(initial_canvas) if initial else MAX_DISPLAY_SIDE,
                buttons=[],
            )

        with gr.Row():
            key_color = gr.ColorPicker(
                value=rgb_to_hex(PRESETS[default_preset]),
                label="Key color",
            )
            tolerance = gr.Slider(
                0,
                80,
                value=default_tolerance,
                step=1,
                label="Tolerance",
                info="How close a pixel must be to Key color to be removed (higher = more aggressive)",
            )
            feather = gr.Slider(
                0,
                8,
                value=default_feather,
                step=1,
                label="Feather",
                info="Softens edges of removed regions inside the paint mask (0 = hard cut)",
            )

        status = gr.Markdown(
            f"Loaded `{download_name(name0)}` — paint, Apply, then Download."
            if path0
            else "Upload an image to begin."
        )
        with gr.Row():
            apply_btn = gr.Button("Apply", variant="primary")
            download_btn = gr.DownloadButton(label="Download", value=None, interactive=False)

        def on_file(path):
            if not path:
                return (
                    None,
                    gr.update(
                        value=None,
                        canvas_size=(800, 800),
                        height=MAX_DISPLAY_SIDE + EDITOR_CHROME_PX,
                    ),
                    "Upload an image to begin.",
                )
            path = Path(path)
            if not path.is_file():
                return None, gr.update(value=None), f"File not found: `{path}`"
            source = load_rgba(path)
            return (
                str(path),
                editor_update(source, path.name),
                f"Loaded `{download_name(path.name)}` — paint, Apply, then Download.",
            )

        def on_apply(editor_value, path, color, tol, feather_radius):
            if not path:
                return None, gr.update(value=None, interactive=False), "Upload an image first."
            source = load_rgba(path)
            mask = editor_region_mask(editor_value, source.size)
            if mask.getbbox() is None:
                return None, gr.update(value=None, interactive=False), "Paint the region to remove first."
            result = remove_key_in_region(
                source,
                mask,
                key=parse_hex(color),
                tolerance=int(tol),
                feather=int(feather_radius),
            )
            name = download_name(Path(path).name)
            out = save_temp_png(result, name)
            return (
                gr.update(value=on_gray(result), height=display_height(result.size)),
                gr.update(value=out, interactive=True, label=f"Download ({name})"),
                f"Ready — download as `{name}`.",
            )

        def on_stop():
            # Yield UI feedback first so the browser grays the button before exit.
            yield (
                gr.update(value="Stopping…", interactive=False, variant="secondary"),
                "Stopping server…",
            )
            time.sleep(0.5)
            yield (
                gr.update(value="Stopped", interactive=False, variant="secondary"),
                "Server stopped.",
            )
            time.sleep(0.4)
            try:
                demo.close()
            except Exception:
                pass
            os._exit(0)

        file_in.change(on_file, inputs=[file_in], outputs=[source_path, editor, status])
        apply_btn.click(
            on_apply,
            inputs=[editor, source_path, key_color, tolerance, feather],
            outputs=[preview, download_btn, status],
        )
        stop_btn.click(on_stop, outputs=[stop_btn, status])

    return demo


def main() -> int:
    parser = argparse.ArgumentParser(description="Paint a region and remove key-color background.")
    parser.add_argument("image", nargs="?", help="Optional image to preload")
    parser.add_argument("--preset", choices=list(PRESETS), default="white")
    parser.add_argument("--tolerance", type=int)
    parser.add_argument("--feather", type=int, default=DEFAULT_FEATHER)
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()

    preload_path = None
    if args.image:
        preload_path = Path(args.image).expanduser().resolve()
        if not preload_path.is_file():
            print(f"Image not found: {preload_path}", file=sys.stderr)
            return 1

    tol = args.tolerance if args.tolerance is not None else PRESET_TOLERANCE[args.preset]
    demo = build_ui(
        preload_path=preload_path,
        default_preset=args.preset,
        default_tolerance=tol,
        default_feather=args.feather,
    )

    print(f"Starting Gradio on http://127.0.0.1:{args.port}", flush=True)
    demo.launch(
        server_name="127.0.0.1",
        server_port=args.port,
        inbrowser=not args.no_browser,
        share=False,
        css="""
.title-row { align-items: center; }
#stop-server-btn button:disabled,
#stop-server-btn.disabled,
#stop-server-btn button[disabled] {
  opacity: 0.45 !important;
  filter: grayscale(1);
  cursor: not-allowed !important;
}
""",
        footer_links=["gradio", "settings"],
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
