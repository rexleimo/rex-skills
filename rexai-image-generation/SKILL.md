---
name: rexai-image-generation
description: Use when the user wants to generate images with RexAI, create AI artwork, run text-to-image or image-to-image jobs, edit an image from a reference, download generated image files locally, or asks for 生图, 生成图片, 文生图, 图生图, AI image generation, image edit, or RexAI image API usage.
---

# RexAI Image Generation

Generate images through RexAI's async image API and save the finished files locally with the bundled uv/Python runner.

## Required Workflow

1. Inspect the environment before calling the API:
   ```bash
   bash <skill-dir>/scripts/rexai-image --check-env
   ```
2. If `uv` is missing, install it on the user's computer before execution:
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```
   Then reopen the shell or add the printed uv bin directory to `PATH`.
3. Resolve authentication without printing secrets. Prefer `REXAI_API_KEY`, then `OPENAI_API_KEY`, then `~/.codex/auth.json` field `OPENAI_API_KEY`.
4. Refresh current products when model choice is uncertain:
   ```bash
   bash <skill-dir>/scripts/rexai-image --list-products
   ```
5. Run generation with the wrapper, which executes `uv run --script scripts/rexai_image.py`:
   ```bash
   bash <skill-dir>/scripts/rexai-image \
     --prompt "A cinematic red panda pilot in a bamboo airship" \
     --model gpt-image-1.5 \
     --size 1024x1024 \
     --output-dir generated/rexai
   ```
6. Report the local file path(s), job id, product id, source URL if present, and expiry time if present.

Read `references/api.md` when endpoint details, supported parameters, products, sizes, or error codes are needed.

## Text-To-Image

Use active text-to-image product IDs from `--list-products`. Current common choices include `gpt-image-1.5`, `nano2-4k`, `nano2-2k`, `nano2-1k`, `nano-4k`, `nano-2k`, `nano-1k`, and `img-image-minimax-image-01-t2i`.

```bash
bash <skill-dir>/scripts/rexai-image \
  --prompt "一只橘猫在午后阳光里睡觉，柔和胶片质感" \
  --model gpt-image-1.5 \
  --n 1 \
  --size 1024x1024 \
  --output-dir generated/rexai
```

## Image-To-Image

Pass at least one reference image with `--image`. A value may be a local file path, `https://` URL, or `data:image/...` URL. Local files are converted to data URLs by the Python runner.

```bash
bash <skill-dir>/scripts/rexai-image \
  --model nano2-2k-i2i \
  --prompt "将这张图片转换为水彩插画风格" \
  --image path/to/source.png \
  --output-dir generated/rexai
```

## Operational Rules

- Never print or paste the raw API key. The checker reports only whether each source exists.
- Use an output directory inside the current workspace unless the user requests another path.
- Do not invent a reference image for image-to-image; ask for a local path or URL when none is provided.
- Do not pass unsupported aliases such as `imageSize` or `image_size`; use `size`.
- Poll the returned job until `succeeded` or `failed`; if polling times out, report the job id and last status.
- If RexAI returns `invalid_model`, `model_not_found`, or `invalid_parameter`, run `--list-products` and retry with an active product ID.
- Avoid spending user quota just to test the skill. Use `--check-env`, `--list-products`, and `--dry-run` for validation.

## Script Output

The runner prints JSON on success:

```json
{
  "id": "job-id",
  "status": "succeeded",
  "product_id": "gpt-image-1.5",
  "output_dir": "generated/rexai",
  "results": [
    {
      "file": "generated/rexai/rexai-job-id-1.png",
      "url": "https://cdn.example.com/image.png",
      "expires_at": "2026-06-29T01:00:00.000Z"
    }
  ]
}
```
