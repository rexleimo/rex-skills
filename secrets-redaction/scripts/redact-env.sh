#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  redact-env.sh [path]

Print a redacted view of a .env-style file (KEY=VALUE lines), masking secrets.

Examples:
  bash redact-env.sh .env
  bash redact-env.sh config/.env.local
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

file="${1:-.env}"
if [[ ! -f "$file" ]]; then
  echo "File not found: $file" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  python3 - "$file" <<'PY'
import re
import sys
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

SECRET_KEY_RE = re.compile(
    r"(?:"
    r"api[_-]?key|access[_-]?key|secret|token|password|passwd|pwd|private|"
    r"cookie|auth|session|webhook|signature|database|db|dsn|connection"
    r")",
    re.IGNORECASE,
)

JWT_RE = re.compile(r"^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$")
HEX_RE = re.compile(r"^[A-Fa-f0-9]{32,}$")
BASE64ISH_RE = re.compile(r"^[A-Za-z0-9+/_=-]{24,}$")

PREFIX_HINTS = (
    "sk-",
    "rk-",
    "pk_",
    "ghp_",
    "xoxb-",
    "xoxa-",
    "xoxp-",
    "ya29.",
    "AIza",
)


def redact_token(value: str) -> str:
    n = len(value)
    if n == 0:
        return value
    if n <= 4:
        return "*" * n
    if n <= 8:
        return f"{value[:1]}…{value[-1:]}"
    return f"{value[:4]}…{value[-4:]}"


def looks_like_secret(value: str) -> bool:
    v = value.strip()
    if not v:
        return False
    if v.startswith("$"):
        return False
    if "-----BEGIN" in v or v.startswith("ssh-"):
        return True
    if any(v.startswith(p) for p in PREFIX_HINTS):
        return True
    if JWT_RE.match(v) and len(v) >= 20:
        return True
    if HEX_RE.match(v):
        return True
    if BASE64ISH_RE.match(v):
        return True
    if "://" in v and "@" in v:
        return True
    return False


def redact_url(value: str) -> str:
    try:
        parts = urlsplit(value)
    except Exception:
        return value

    if not parts.scheme or not parts.netloc:
        return value

    netloc = parts.netloc
    if "@" in netloc:
        userinfo, host = netloc.rsplit("@", 1)
        if ":" in userinfo:
            user, _pw = userinfo.split(":", 1)
            userinfo = f"{user}:***"
        else:
            userinfo = f"{userinfo}:***"
        netloc = f"{userinfo}@{host}"

    query_pairs = parse_qsl(parts.query, keep_blank_values=True)
    if query_pairs:
        redacted_pairs = []
        for k, v in query_pairs:
            if SECRET_KEY_RE.search(k) or looks_like_secret(v):
                redacted_pairs.append((k, redact_token(v)))
            else:
                redacted_pairs.append((k, v))
        query = urlencode(redacted_pairs, doseq=True)
    else:
        query = parts.query

    return urlunsplit((parts.scheme, netloc, parts.path, query, parts.fragment))


def split_unquoted_value_and_comment(raw: str) -> tuple[str, str]:
    for i, ch in enumerate(raw):
        if ch == "#":
            if i == 0 or raw[i - 1].isspace():
                return raw[:i].rstrip(), raw[i:].rstrip()
    return raw.rstrip(), ""


def split_quoted_value_and_tail(raw: str, quote: str) -> tuple[str, str]:
    if quote == "'":
        end = raw.find("'", 1)
        if end == -1:
            return raw[1:], ""
        return raw[1:end], raw[end + 1 :].rstrip()

    # double quotes: allow backslash escaping
    i = 1
    escaped = False
    while i < len(raw):
        c = raw[i]
        if escaped:
            escaped = False
        elif c == "\\":
            escaped = True
        elif c == '"':
            return raw[1:i], raw[i + 1 :].rstrip()
        i += 1
    return raw[1:], ""


def main() -> int:
    path = sys.argv[1]
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for original_line in f:
            line = original_line.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                print(line)
                continue

            m = re.match(r"^(?P<prefix>\s*)(?P<export>export\s+)?(?P<key>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?P<rest>.*)$", line)
            if not m:
                print(line)
                continue

            prefix = m.group("prefix") or ""
            export = m.group("export") or ""
            key = m.group("key")
            rest = m.group("rest")

            quote = ""
            value = rest
            comment = ""
            if rest.startswith(("'", '"')):
                quote = rest[0]
                value, tail = split_quoted_value_and_tail(rest, quote)
                if tail.strip().startswith("#"):
                    comment = tail.strip()
                else:
                    # keep any non-comment tail (rare) as part of comment for safety
                    comment = tail.strip()
            else:
                value, comment = split_unquoted_value_and_comment(rest)

            redacted = False
            out_value = value

            if "://" in value:
                url_redacted = redact_url(value)
                if url_redacted != value:
                    out_value = url_redacted
                    redacted = True

            if SECRET_KEY_RE.search(key) or looks_like_secret(value):
                out_value = redact_token(out_value)
                redacted = True

            if redacted:
                note = f"redacted len={len(value)}"
                if comment.startswith("#"):
                    comment = f"{comment} | {note}"
                elif comment:
                    comment = f"# {comment} | {note}"
                else:
                    comment = f"# {note}"

            quoted_out = f"{quote}{out_value}{quote}" if quote else out_value
            if comment:
                print(f"{prefix}{export}{key}={quoted_out} {comment}".rstrip())
            else:
                print(f"{prefix}{export}{key}={quoted_out}".rstrip())
    return 0


raise SystemExit(main())
PY
  exit 0
fi

# Fallback: basic awk redaction (less accurate with quotes/comments)
awk '
function tolower_str(s,   i,c,out) { out=""; for (i=1;i<=length(s);i++){c=substr(s,i,1); out=out tolower(c)} return out }
function is_secret_key(k, kl) {
  kl=tolower_str(k)
  return (kl ~ /(api[_-]?key|access[_-]?key|secret|token|password|passwd|pwd|private|cookie|auth|session|webhook|signature|database|db|dsn|connection)/)
}
function looks_like_secret(v) {
  if (v ~ /^\$/) return 0
  if (v ~ /-----BEGIN/ || v ~ /^ssh-/) return 1
  if (v ~ /^(sk-|rk-|pk_|ghp_|xox[bap]-|ya29\.|AIza)/) return 1
  if (v ~ /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/ && length(v) >= 20) return 1
  if (v ~ /^[A-Fa-f0-9]{32,}$/) return 1
  if (v ~ /^[A-Za-z0-9+/_=-]{24,}$/) return 1
  if (v ~ /:\/\// && v ~ /@/) return 1
  return 0
}
function redact_token(v, n) {
  n=length(v)
  if (n==0) return v
  if (n<=4) return "****"
  if (n<=8) return substr(v,1,1) "…" substr(v,n,1)
  return substr(v,1,4) "…" substr(v,n-3,4)
}
{
  line=$0
  if (line ~ /^[[:space:]]*$/ || line ~ /^[[:space:]]*#/) { print line; next }
  sub(/^[[:space:]]*export[[:space:]]+/, "export ", line)
  eq=index(line, "=")
  if (eq==0) { print $0; next }
  key=substr(line,1,eq-1)
  val=substr(line,eq+1)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
  if (is_secret_key(key) || looks_like_secret(val)) {
    print key "=" redact_token(val) " # redacted len=" length(val)
  } else {
    print key "=" val
  }
}
' "$file"

