# RexAI Image API Reference

Source: `https://tool.rexai.top/docs/api` and its JSON data endpoint `https://tool.rexai.top/api/api-docs` checked on 2026-06-30.

## Authentication

Send one of these headers:

- `Authorization: Bearer cr_xxxxxxxx`
- `x-api-key: cr_xxxxxxxx`

The bundled runner uses `Authorization: Bearer ...` and resolves the key from `REXAI_API_KEY`, `OPENAI_API_KEY`, or `~/.codex/auth.json` key `OPENAI_API_KEY`.

## Base URL

The docs front-end falls back to `https://coding.rexai.top` when the docs JSON reports `/` as `baseUrl`. Override with `--base-url` or `REXAI_BASE_URL` only when the docs or administrator says to.

## Create Image Job

`POST /v1/images/generations`

Text-to-image parameters:

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `model` | string | yes | RexAI image product ID, not upstream model name. |
| `prompt` | string | yes | Image description. |
| `n` | integer | no | Image count; default `1`. |
| `size` | string | no | Example `1024x1024`. |

Image-to-image uses the same endpoint and adds:

| Name | Type | Required | Notes |
| --- | --- | --- | --- |
| `images` | string[] | yes | At least one data URL or image URL. Local files must be converted to data URLs first. |
| `prompt` | string | conditionally | Description or edit instruction. |

The API returns `202 Accepted` with a job object such as `id`, `object`, `status`, `productId`, and `providerTaskId`.

## Poll Job

`GET /v1/images/jobs/{id}`

Poll every 2-5 seconds until `status` is `succeeded` or `failed`. A successful result may contain:

```json
{
  "id": "job-id",
  "status": "succeeded",
  "product_id": "gpt-image-1.5",
  "result": {
    "url": "https://cdn.example.com/images/xxx.png",
    "b64_json": null,
    "expires_at": "2026-06-29T01:00:00.000Z"
  }
}
```

## Current Products

Refresh with:

```bash
bash <skill-dir>/scripts/rexai-image --list-products
```

Products observed on 2026-06-30:

| Product ID | Type | Name |
| --- | --- | --- |
| `gpt-image-1.5` | text-to-image | gpt-image-1.5 |
| `nano2-4k` | text-to-image | [banana] nano2-4k |
| `nano2-2k` | text-to-image | [banana] nano2-2k |
| `nano2-1k` | text-to-image | [banana] nano2-1k |
| `nano-4k` | text-to-image | [banana] nano-4k |
| `nano-2k` | text-to-image | [banana] nano-2k |
| `nano-1k` | text-to-image | [banana] nano-1k |
| `img-image-minimax-image-01-t2i` | text-to-image | minimax-image-01-t2i |
| `nano2-2k-i2i` | image-to-image | banana nano2-2k-i2i |
| `nano2-1k-i2i` | image-to-image | banana nano2-1k image-to-image |

## Current Sizes

- `256x256`
- `512x512`
- `1024x1024`
- `1792x1024`
- `1024x1792`

## Common Errors

| Code | Meaning |
| --- | --- |
| `permission_denied` | API key lacks permission. |
| `invalid_request_error` | Request body format is invalid. |
| `model_not_found` | Model/product is unavailable. |
| `rate_limit_error` | Rate limit exceeded. |
| `service_unavailable` | No upstream account is available. |
| `insufficient_package_quota` | Subscription quota is insufficient. |
| `insufficient_direct_balance` | Direct-pay balance is insufficient. |
| `invalid_parameter` | Image API rejects unsupported fields such as `imageSize` or `image_size`. |
| `invalid_model` | Image API `model` is missing or invalid. |
| `image_call_limit_exhausted` | Daily image call limit exceeded. |
| `image_upstream_failed` | Upstream image provider failed. |
