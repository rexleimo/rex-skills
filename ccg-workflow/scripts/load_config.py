#!/usr/bin/env python3
"""
CCG Workflow Configuration Loader

Loads and validates ccg-workflow configuration with three-level resolution:
  1. CLI flags / environment variables (highest priority)
  2. Project config file (ccg-workflow.yaml)
  3. Built-in defaults (lowest priority)

Usage:
  python load_config.py                          # Load from default locations
  python load_config.py --config path/to/config  # Load from specific file
  python load_config.py --get backends.backend    # Get specific value
  python load_config.py --schema                  # Show active schema
  python load_config.py --validate                # Validate config
  python load_config.py --init                    # Generate default config
"""

import argparse
import json
import os
import sys
from pathlib import Path

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

# ─── Built-in Defaults ───────────────────────────────────────────────────────

DEFAULTS = {
    "schema": "default",
    "backends": {
        "backend": {"provider": "codex", "model": None},
        "frontend": {"provider": "gemini", "model": "gemini-2.5-pro"},
        "fallback": {"provider": "claude", "model": None},
    },
    "context": "",
    "trust": {
        "backend_domain": "codex",
        "frontend_domain": "gemini",
        "cross_cutting": "coordinator",
        "conflict_strategy": "domain_expert",
    },
    "workflow": {
        "enhance": {
            "enabled": True,
            "min_completeness": 7,
            "auto_enhance": False,
        },
        "research": {
            "scan_depth": "medium",
            "include_git_history": True,
        },
        "ideation": {
            "parallel": True,
            "min_options": 2,
            "auto_select": False,
        },
        "plan": {
            "require_approval": True,
            "detail_level": "detailed",
        },
        "execute": {
            "dry_run": False,
            "auto_commit": False,
            "commit_style": "conventional",
        },
        "review": {
            "parallel": True,
            "min_score": 80,
            "severity_filter": "major",
            "auto_fix": False,
        },
    },
    "rules": {
        "dev": [],
        "debug": [],
        "review": [],
        "analyze": [],
        "init": [],
        "team": [],
    },
    "safety": {
        "max_files_per_execute": 20,
        "require_user_confirm_before_write": True,
        "context_token_warning": 80000,
        "never_kill_background": True,
        "timeout_seconds": 600,
    },
    "output": {
        "language": "zh-CN",
        "verbosity": "normal",
        "show_model_source": True,
        "report_format": "markdown",
    },
}

# ─── Config Resolution ────────────────────────────────────────────────────────

def find_config_file():
    """Find config file in resolution order."""
    # 1. Environment variable
    env_path = os.environ.get("CCG_CONFIG")
    if env_path and os.path.exists(env_path):
        return env_path

    # 2. Current directory
    for name in ["ccg-workflow.yaml", "ccg-workflow.yml", ".ccg-workflow.yaml"]:
        if os.path.exists(name):
            return name

    # 3. Project root (walk up to find .git)
    current = Path.cwd()
    for parent in [current] + list(current.parents):
        for name in ["ccg-workflow.yaml", "ccg-workflow.yml"]:
            candidate = parent / name
            if candidate.exists():
                return str(candidate)
        if (parent / ".git").exists():
            break

    return None


def deep_merge(base, override):
    """Deep merge override into base dict."""
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def load_yaml_or_json(path):
    """Load YAML or JSON file."""
    with open(path, "r") as f:
        content = f.read()

    if HAS_YAML:
        return yaml.safe_load(content)

    # Fallback: try JSON
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        # Simple YAML-like parser for basic key-value configs
        print(f"Warning: PyYAML not installed. Install with: pip install pyyaml", file=sys.stderr)
        print(f"Falling back to JSON parser.", file=sys.stderr)
        return {}


def load_config(config_path=None):
    """Load configuration with three-level resolution."""
    config = DEFAULTS.copy()

    # Level 1: Project config file
    path = config_path or find_config_file()
    if path and os.path.exists(path):
        file_config = load_yaml_or_json(path)
        if file_config:
            config = deep_merge(config, file_config)

    # Level 2: Environment variable overrides
    env_overrides = {
        "CCG_SCHEMA": ("schema",),
        "CCG_BACKEND_PROVIDER": ("backends", "backend", "provider"),
        "CCG_BACKEND_MODEL": ("backends", "backend", "model"),
        "CCG_FRONTEND_PROVIDER": ("backends", "frontend", "provider"),
        "CCG_FRONTEND_MODEL": ("backends", "frontend", "model"),
        "CCG_LANGUAGE": ("output", "language"),
        "CCG_VERBOSITY": ("output", "verbosity"),
        "CCG_PARALLEL": ("workflow", "ideation", "parallel"),
        "CCG_MIN_SCORE": ("workflow", "review", "min_score"),
        "CCG_TIMEOUT": ("safety", "timeout_seconds"),
    }

    for env_var, key_path in env_overrides.items():
        value = os.environ.get(env_var)
        if value is not None:
            # Navigate to the right nested dict
            target = config
            for key in key_path[:-1]:
                target = target.setdefault(key, {})
            # Type conversion
            final_key = key_path[-1]
            if isinstance(DEFAULTS.get(key_path[0], {}).get(key_path[-1]) if len(key_path) == 2 else None, bool):
                value = value.lower() in ("true", "1", "yes")
            elif isinstance(target.get(final_key), int):
                try:
                    value = int(value)
                except ValueError:
                    pass
            target[final_key] = value

    return config


def get_nested(config, dotpath):
    """Get a nested config value by dot-separated path."""
    keys = dotpath.split(".")
    current = config
    for key in keys:
        if isinstance(current, dict) and key in current:
            current = current[key]
        else:
            return None
    return current


# ─── Validation ───────────────────────────────────────────────────────────────

def validate_config(config):
    """Validate configuration and return list of issues."""
    issues = []

    # Validate schema
    valid_schemas = ["default", "fast", "review-only", "custom"]
    if config.get("schema") not in valid_schemas:
        issues.append(f"Invalid schema '{config.get('schema')}'. Valid: {valid_schemas}")

    # Validate backend providers
    valid_providers = ["codex", "gemini", "claude", "openai-compatible"]
    for role in ["backend", "frontend", "fallback"]:
        provider = config.get("backends", {}).get(role, {}).get("provider")
        if provider and provider not in valid_providers:
            issues.append(f"Invalid provider '{provider}' for {role}. Valid: {valid_providers}")

    # Validate trust settings
    trust = config.get("trust", {})
    valid_strategies = ["domain_expert", "always_ask", "majority_vote"]
    if trust.get("conflict_strategy") not in valid_strategies:
        issues.append(f"Invalid conflict_strategy. Valid: {valid_strategies}")

    # Validate workflow settings
    wf = config.get("workflow", {})
    mc = wf.get("enhance", {}).get("min_completeness", 7)
    if not (0 <= mc <= 10):
        issues.append(f"min_completeness must be 0-10, got {mc}")

    ms = wf.get("review", {}).get("min_score", 80)
    if not (0 <= ms <= 100):
        issues.append(f"min_score must be 0-100, got {ms}")

    valid_depths = ["light", "medium", "deep"]
    depth = wf.get("research", {}).get("scan_depth")
    if depth and depth not in valid_depths:
        issues.append(f"Invalid scan_depth '{depth}'. Valid: {valid_depths}")

    # Validate safety settings
    safety = config.get("safety", {})
    timeout = safety.get("timeout_seconds", 600)
    if timeout < 30:
        issues.append(f"timeout_seconds too low ({timeout}s). Minimum: 30")

    return issues


# ─── Init ─────────────────────────────────────────────────────────────────────

def generate_default_config():
    """Generate a default config file."""
    skill_dir = Path(__file__).parent.parent
    config_template = skill_dir / "config.yaml"
    if config_template.exists():
        return config_template.read_text()
    # Fallback: generate from DEFAULTS
    if HAS_YAML:
        return yaml.dump(DEFAULTS, default_flow_style=False, allow_unicode=True)
    return json.dumps(DEFAULTS, indent=2, ensure_ascii=False)


# ─── CLI ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="CCG Workflow Configuration Loader")
    parser.add_argument("--config", help="Path to config file")
    parser.add_argument("--get", help="Get specific config value (dot-separated path)")
    parser.add_argument("--schema", action="store_true", help="Show active schema")
    parser.add_argument("--validate", action="store_true", help="Validate configuration")
    parser.add_argument("--init", action="store_true", help="Generate default config file")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--summary", action="store_true", help="Show config summary")
    args = parser.parse_args()

    if args.init:
        print(generate_default_config())
        return

    config = load_config(args.config)

    if args.validate:
        issues = validate_config(config)
        if issues:
            print("❌ Configuration issues found:")
            for issue in issues:
                print(f"  - {issue}")
            sys.exit(1)
        else:
            config_path = args.config or find_config_file() or "(defaults)"
            print(f"✅ Configuration valid (source: {config_path})")
        return

    if args.schema:
        print(config.get("schema", "default"))
        return

    if args.get:
        value = get_nested(config, args.get)
        if value is None:
            print(f"Key not found: {args.get}", file=sys.stderr)
            sys.exit(1)
        if args.json or isinstance(value, (dict, list)):
            print(json.dumps(value, indent=2, ensure_ascii=False))
        else:
            print(value)
        return

    if args.summary:
        print("CCG Workflow Configuration Summary")
        print("=" * 50)
        source = args.config or find_config_file() or "(built-in defaults)"
        print(f"Source:           {source}")
        print(f"Schema:           {config['schema']}")
        print(f"Backend model:    {config['backends']['backend']['provider']}"
              f" ({config['backends']['backend'].get('model') or 'default'})")
        print(f"Frontend model:   {config['backends']['frontend']['provider']}"
              f" ({config['backends']['frontend'].get('model') or 'default'})")
        print(f"Trust strategy:   {config['trust']['conflict_strategy']}")
        print(f"Parallel ideation:{config['workflow']['ideation']['parallel']}")
        print(f"Parallel review:  {config['workflow']['review']['parallel']}")
        print(f"Min review score: {config['workflow']['review']['min_score']}")
        print(f"Output language:  {config['output']['language']}")
        return

    # Default: print full config
    if args.json:
        print(json.dumps(config, indent=2, ensure_ascii=False))
    else:
        if HAS_YAML:
            print(yaml.dump(config, default_flow_style=False, allow_unicode=True))
        else:
            print(json.dumps(config, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
