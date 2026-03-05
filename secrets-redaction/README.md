# Secrets Redaction

Safely display configuration files (especially `.env`) by masking secrets before sharing output.

## Usage

```bash
bash ./scripts/redact-env.sh .env
```

## What it does

- Keeps keys as-is
- Masks values that look like secrets (API keys, tokens, passwords, private keys, credentialed URLs)
- Annotates redacted values with `len=<N>` to help debugging without leaking

