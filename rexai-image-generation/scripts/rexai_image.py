#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""RexAI async image generation runner."""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import pathlib
import re
import shutil
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

DOCS_ENDPOINT = "https://tool.rexai.top/api/api-docs"
DEFAULT_API_BASE = "https://coding.rexai.top"
TERMINAL_SUCCESS = {"succeeded", "completed", "success"}
TERMINAL_FAILURE = {"failed", "error", "cancelled", "canceled"}


def eprint(*values: object) -> None:
    print(*values, file=sys.stderr)


def load_json_url(url: str, headers: dict[str, str] | None = None, timeout: int = 30) -> Any:
    req = urllib.request.Request(url, headers=headers or {"User-Agent": "rexai-image-skill/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode("utf-8")
    return json.loads(raw)


def request_json(url: str, *, method: str = "GET", api_key: str | None = None, body: dict[str, Any] | None = None, timeout: int = 60) -> tuple[int, Any]:
    data = None
    headers = {"Accept": "application/json", "User-Agent": "rexai-image-skill/1.0"}
    if body is not None:
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            payload = resp.read().decode("utf-8", "replace")
            return resp.status, json.loads(payload) if payload else {}
    except urllib.error.HTTPError as exc:
        payload = exc.read().decode("utf-8", "replace")
        try:
            parsed = json.loads(payload) if payload else {}
        except json.JSONDecodeError:
            parsed = {"error": payload}
        raise RuntimeError(f"HTTP {exc.code} from RexAI: {json.dumps(parsed, ensure_ascii=False)}") from exc


def resolve_api_base(args: argparse.Namespace) -> str:
    raw = args.base_url or os.environ.get("REXAI_BASE_URL")
    if not raw and not args.no_docs_base:
        try:
            docs = load_json_url(args.docs_endpoint)
            raw = docs.get("baseUrl")
        except Exception as exc:  # noqa: BLE001 - diagnostics only
            eprint(f"Warning: failed to fetch docs base URL: {exc}")
    if not raw or raw == "/":
        raw = DEFAULT_API_BASE
    raw = raw.rstrip("/")
    if not re.match(r"^https?://", raw):
        raw = DEFAULT_API_BASE
    return raw


def auth_json_path(args: argparse.Namespace) -> pathlib.Path:
    if args.auth_json:
        return pathlib.Path(args.auth_json).expanduser()
    return pathlib.Path.home() / ".codex" / "auth.json"


def load_key_from_auth_json(path: pathlib.Path) -> str | None:
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    value = data.get("OPENAI_API_KEY")
    return value if isinstance(value, str) and value.strip() else None


def resolve_api_key(args: argparse.Namespace) -> tuple[str | None, str]:
    if args.api_key:
        return args.api_key, "--api-key"
    for name in ("REXAI_API_KEY", "OPENAI_API_KEY"):
        value = os.environ.get(name)
        if value:
            return value, name
    path = auth_json_path(args)
    value = load_key_from_auth_json(path)
    if value:
        return value, str(path)
    return None, "missing"


def check_env(args: argparse.Namespace) -> int:
    path = auth_json_path(args)
    auth_has_key = bool(load_key_from_auth_json(path))
    report: dict[str, Any] = {
        "uv": shutil.which("uv") or "missing",
        "python": sys.version.split()[0],
        "REXAI_API_KEY": bool(os.environ.get("REXAI_API_KEY")),
        "OPENAI_API_KEY": bool(os.environ.get("OPENAI_API_KEY")),
        "codex_auth_json": str(path),
        "codex_auth_json_exists": path.exists(),
        "codex_auth_json_has_OPENAI_API_KEY": auth_has_key,
        "docs_endpoint": args.docs_endpoint,
    }
    if not args.skip_network:
        try:
            docs = load_json_url(args.docs_endpoint)
            report["docs_reachable"] = True
            report["active_image_products"] = len([p for p in docs.get("imageProducts", []) if p.get("isActive")])
            report["image_sizes"] = [s.get("id") for s in docs.get("imageSizes", [])]
        except Exception as exc:  # noqa: BLE001 - command output should explain failure
            report["docs_reachable"] = False
            report["docs_error"] = str(exc)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if (report["REXAI_API_KEY"] or report["OPENAI_API_KEY"] or auth_has_key) else 2


def list_products(args: argparse.Namespace) -> int:
    docs = load_json_url(args.docs_endpoint)
    products = [p for p in docs.get("imageProducts", []) if p.get("isActive")]
    output = {
        "base_url": docs.get("baseUrl") or DEFAULT_API_BASE,
        "image_sizes": docs.get("imageSizes", []),
        "text_to_image": [p for p in products if p.get("type") == "text-to-image"],
        "image_to_image": [p for p in products if p.get("type") == "image-to-image"],
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


def image_to_data_url(value: str) -> str:
    if value.startswith(("http://", "https://", "data:image/")):
        return value
    path = pathlib.Path(value).expanduser()
    if not path.exists():
        raise FileNotFoundError(f"Reference image not found: {value}")
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def build_payload(args: argparse.Namespace) -> dict[str, Any]:
    payload: dict[str, Any] = {"model": args.model, "n": args.n}
    if args.prompt:
        payload["prompt"] = args.prompt
    if args.size:
        payload["size"] = args.size
    if args.image:
        payload["images"] = [image_to_data_url(item) for item in args.image]
    if not payload.get("prompt") and not payload.get("images"):
        raise ValueError("Provide --prompt and/or --image.")
    return payload


def normalize_job_id(payload: dict[str, Any]) -> str:
    for key in ("id", "job_id", "jobId"):
        value = payload.get(key)
        if isinstance(value, str) and value:
            return value
    raise RuntimeError(f"RexAI response did not include a job id: {json.dumps(payload, ensure_ascii=False)}")


def poll_job(base_url: str, job_id: str, api_key: str, timeout_s: int, interval_s: float) -> dict[str, Any]:
    deadline = time.time() + timeout_s
    last: dict[str, Any] = {}
    while time.time() < deadline:
        _, payload = request_json(f"{base_url}/v1/images/jobs/{urllib.parse.quote(job_id)}", api_key=api_key)
        if not isinstance(payload, dict):
            raise RuntimeError(f"Unexpected poll response: {payload!r}")
        last = payload
        status = str(payload.get("status", "")).lower()
        if status in TERMINAL_SUCCESS:
            return payload
        if status in TERMINAL_FAILURE:
            raise RuntimeError(f"RexAI image job failed: {json.dumps(payload, ensure_ascii=False)}")
        eprint(f"job {job_id}: status={status or 'unknown'}; polling again in {interval_s:g}s")
        time.sleep(interval_s)
    raise TimeoutError(f"Timed out waiting for job {job_id}; last response: {json.dumps(last, ensure_ascii=False)}")


def iter_result_items(job: dict[str, Any]) -> list[dict[str, Any]]:
    result = job.get("result") or job.get("data") or job.get("output")
    if isinstance(result, list):
        return [item if isinstance(item, dict) else {"url": item} for item in result]
    if isinstance(result, dict):
        if isinstance(result.get("images"), list):
            return [item if isinstance(item, dict) else {"url": item} for item in result["images"]]
        return [result]
    if isinstance(result, str):
        return [{"url": result}]
    return []


def extension_from_url(url: str, content_type: str | None) -> str:
    if content_type:
        ext = mimetypes.guess_extension(content_type.split(";", 1)[0].strip())
        if ext:
            return ".jpg" if ext == ".jpe" else ext
    path = urllib.parse.urlparse(url).path
    suffix = pathlib.Path(path).suffix.lower()
    return suffix if suffix in {".png", ".jpg", ".jpeg", ".webp", ".gif"} else ".png"


def download_url(url: str, target_prefix: pathlib.Path) -> pathlib.Path:
    req = urllib.request.Request(url, headers={"User-Agent": "rexai-image-skill/1.0"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = resp.read()
        ext = extension_from_url(url, resp.headers.get("Content-Type"))
    target = target_prefix.with_suffix(ext)
    target.write_bytes(data)
    return target


def save_results(job: dict[str, Any], output_dir: pathlib.Path) -> list[dict[str, Any]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    job_id = str(job.get("id") or job.get("job_id") or "rexai")
    saved: list[dict[str, Any]] = []
    for index, item in enumerate(iter_result_items(job), start=1):
        prefix = output_dir / f"rexai-{job_id}-{index}"
        record: dict[str, Any] = {"url": item.get("url"), "expires_at": item.get("expires_at")}
        b64_json = item.get("b64_json") or item.get("b64")
        if b64_json:
            target = prefix.with_suffix(".png")
            target.write_bytes(base64.b64decode(b64_json))
            record["file"] = str(target)
        elif item.get("url"):
            target = download_url(str(item["url"]), prefix)
            record["file"] = str(target)
        else:
            record["raw"] = item
        saved.append(record)
    return saved


def generate(args: argparse.Namespace) -> int:
    api_key, key_source = resolve_api_key(args)
    if not api_key:
        raise RuntimeError("Missing API key. Set REXAI_API_KEY, OPENAI_API_KEY, or ~/.codex/auth.json OPENAI_API_KEY.")
    base_url = resolve_api_base(args)
    payload = build_payload(args)
    if args.dry_run:
        print(json.dumps({"base_url": base_url, "auth_source": key_source, "payload": payload}, ensure_ascii=False, indent=2))
        return 0
    status, created = request_json(f"{base_url}/v1/images/generations", method="POST", api_key=api_key, body=payload)
    job_id = normalize_job_id(created if isinstance(created, dict) else {})
    eprint(f"created RexAI image job {job_id} (HTTP {status}, auth={key_source})")
    final = poll_job(base_url, job_id, api_key, args.timeout, args.poll_interval)
    results = save_results(final, pathlib.Path(args.output_dir))
    output = {
        "id": job_id,
        "status": final.get("status"),
        "product_id": final.get("product_id") or final.get("productId") or payload.get("model"),
        "output_dir": args.output_dir,
        "results": results,
        "raw_job": final if args.include_raw else None,
    }
    if output["raw_job"] is None:
        output.pop("raw_job")
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate images with RexAI and save local files.")
    parser.add_argument("--prompt", help="Text prompt or edit instruction.")
    parser.add_argument("--model", default="gpt-image-1.5", help="RexAI image product ID.")
    parser.add_argument("--image", action="append", help="Reference image path, URL, or data URL. Repeat for multiple images.")
    parser.add_argument("--n", type=int, default=1, help="Number of images to generate.")
    parser.add_argument("--size", default="1024x1024", help="Output size, for example 1024x1024.")
    parser.add_argument("--output-dir", default="generated/rexai", help="Directory for downloaded files.")
    parser.add_argument("--poll-interval", type=float, default=3.0, help="Polling interval in seconds.")
    parser.add_argument("--timeout", type=int, default=600, help="Polling timeout in seconds.")
    parser.add_argument("--base-url", help="Override RexAI API base URL.")
    parser.add_argument("--docs-endpoint", default=DOCS_ENDPOINT, help="RexAI docs JSON endpoint.")
    parser.add_argument("--no-docs-base", action="store_true", help="Do not fetch docs endpoint to resolve base URL.")
    parser.add_argument("--auth-json", help="Path to Codex auth.json; default ~/.codex/auth.json.")
    parser.add_argument("--api-key", help="API key override. Prefer env/auth.json to avoid shell history.")
    parser.add_argument("--check-env", action="store_true", help="Print environment diagnostics without revealing secrets.")
    parser.add_argument("--skip-network", action="store_true", help="With --check-env, skip docs reachability check.")
    parser.add_argument("--list-products", action="store_true", help="Fetch and print active image products and sizes.")
    parser.add_argument("--dry-run", action="store_true", help="Print request payload and auth source without calling generation API.")
    parser.add_argument("--include-raw", action="store_true", help="Include raw final job JSON in success output.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    try:
        if args.check_env:
            return check_env(args)
        if args.list_products:
            return list_products(args)
        return generate(args)
    except Exception as exc:  # noqa: BLE001 - CLI should print a concise failure
        print(json.dumps({"error": str(exc)}, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
