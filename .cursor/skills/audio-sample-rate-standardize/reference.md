# Sample Rate Standardize — Reference

## Output Format

All files are written as **16-bit PCM WAV** (`pcm_s16le`). Output sample rate is **44100 or 48000 Hz only**.

| Setting | Default output |
|---------|----------------|
| Sample rate | 44100 Hz if source ≤ 44100 Hz; 48000 Hz if source > 44100 Hz |
| Bit depth | 16-bit PCM |
| Format | WAV |
| Channels | Preserved from source |

## FFmpeg Command Shape

```bash
# Source ≤ 44100 Hz
ffmpeg -i input.mp3 -ar 44100 -c:a pcm_s16le output.wav

# Source > 44100 Hz
ffmpeg -i input.flac -ar 48000 -c:a pcm_s16le output.wav
```
