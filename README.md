# ab-av1-batch

Dockerized batch video transcoder using [ab-av1](https://github.com/alexheretic/ab-av1) for quality-optimized encoding. Automatically finds the best CRF per file using VMAF scoring.

## Build

```bash
docker build -t ab-av1-batch .
```

## Usage

```bash
docker run --rm \
  -v /path/to/videos:/encode-targets:ro \
  -v /path/to/output:/output \
  -e TARGET_CODEC=AV1 \
  -e PRESET=8 \
  -e MIN_VMAF=95 \
  -e MAX_ENCODED_PERCENT=80 \
  ab-av1-batch
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `TARGET_CODEC` | `AV1` | Target codec: `AV1` or `HEVC` |
| `PRESET` | `8` | Preset (0-13) |
| `MIN_VMAF` | `95` | Minimum VMAF quality score (0-100). Higher = better quality, larger files |
| `MAX_ENCODED_PERCENT` | `80` | Maximum accepted size compared to source |

## Behavior

- Recursively scans `/encode-targets` for video files (`.mkv`, `.mp4`, `.avi`, `.ts`, `.wmv`)
- Preserves directory structure in `/output`
- **Skips** files already encoded in the target codec (copies them to output as-is)
- **Skips** files that already exist in `/output` (safe to re-run)
- Reports per-file size reduction and a summary at the end

## VMAF Guidelines

| VMAF Score | Quality |
|---|---|
| 95+ | Visually lossless for most content |
| 90-95 | Excellent, minor differences on close inspection |
| 85-90 | Good, noticeable on side-by-side comparison |

## Examples

Encode to HEVC with high quality:
```bash
docker run --rm \
  -v ~/media:/encode-targets:ro \
  -v ~/media-encoded:/output \
  -e TARGET_CODEC=HEVC \
  -e PRESET=8 \
  -e MIN_VMAF=93 \
  -e MAX_ENCODED_PERCENT=80 \
  ab-av1-batch
```

Encode to AV1 (maximum compression, visually lossless):
```bash
docker run --rm \
  -v ~/media:/encode-targets:ro \
  -v ~/media-encoded:/output \
  ab-av1-batch
```
