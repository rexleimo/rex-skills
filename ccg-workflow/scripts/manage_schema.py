#!/usr/bin/env python3
"""
CCG Workflow Schema Manager

Manage workflow schemas: list, show, fork, validate.
Inspired by OpenSpec's `openspec schema` commands.

Usage:
  python manage_schema.py list                          # List available schemas
  python manage_schema.py show <name>                   # Show schema details
  python manage_schema.py fork <source> <target>        # Fork a schema
  python manage_schema.py validate <name>               # Validate a schema
  python manage_schema.py which                         # Show active schema resolution
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

SKILL_DIR = Path(__file__).parent.parent
BUILTIN_SCHEMAS_DIR = SKILL_DIR / "schemas"


def load_schema(schema_dir):
    """Load schema.yaml from a directory."""
    schema_file = schema_dir / "schema.yaml"
    if not schema_file.exists():
        schema_file = schema_dir / "schema.yml"
    if not schema_file.exists():
        return None

    with open(schema_file) as f:
        if HAS_YAML:
            return yaml.safe_load(f.read())
        else:
            # Minimal fallback
            return {"name": schema_dir.name, "description": "(install pyyaml for full parsing)"}


def find_schemas():
    """Find all available schemas from all sources."""
    schemas = {}

    # 1. Built-in schemas (from skill package)
    if BUILTIN_SCHEMAS_DIR.exists():
        for d in sorted(BUILTIN_SCHEMAS_DIR.iterdir()):
            if d.is_dir() and (d / "schema.yaml").exists():
                schema = load_schema(d)
                if schema:
                    schemas[schema.get("name", d.name)] = {
                        "source": "builtin",
                        "path": str(d),
                        "schema": schema,
                    }

    # 2. Project-level schemas (openspec/schemas/ or ccg-schemas/)
    for search_dir in ["openspec/schemas", "ccg-schemas", ".ccg/schemas"]:
        project_dir = Path.cwd() / search_dir
        if project_dir.exists():
            for d in sorted(project_dir.iterdir()):
                if d.is_dir() and (d / "schema.yaml").exists():
                    schema = load_schema(d)
                    if schema:
                        name = schema.get("name", d.name)
                        schemas[name] = {
                            "source": "project",
                            "path": str(d),
                            "schema": schema,
                        }

    # 3. User-level schemas (~/.ccg/schemas/)
    user_dir = Path.home() / ".ccg" / "schemas"
    if user_dir.exists():
        for d in sorted(user_dir.iterdir()):
            if d.is_dir() and (d / "schema.yaml").exists():
                schema = load_schema(d)
                if schema:
                    name = schema.get("name", d.name)
                    if name not in schemas:  # Project-level takes precedence
                        schemas[name] = {
                            "source": "user",
                            "path": str(d),
                            "schema": schema,
                        }

    return schemas


def cmd_list(args):
    """List all available schemas."""
    schemas = find_schemas()
    if not schemas:
        print("No schemas found.")
        return

    if args.json:
        print(json.dumps({k: {"source": v["source"], "path": v["path"],
                               "description": v["schema"].get("description", "")}
                          for k, v in schemas.items()}, indent=2))
        return

    print(f"{'Name':<20} {'Source':<10} {'Description'}")
    print("-" * 70)
    for name, info in schemas.items():
        desc = info["schema"].get("description", "")
        print(f"{name:<20} {info['source']:<10} {desc}")


def cmd_show(args):
    """Show schema details."""
    schemas = find_schemas()
    if args.name not in schemas:
        print(f"Schema '{args.name}' not found. Available: {', '.join(schemas.keys())}")
        sys.exit(1)

    info = schemas[args.name]
    schema = info["schema"]

    if args.json:
        print(json.dumps(schema, indent=2, ensure_ascii=False))
        return

    print(f"Schema: {schema.get('name', args.name)}")
    print(f"Source: {info['source']}")
    print(f"Path:   {info['path']}")
    print(f"Description: {schema.get('description', 'N/A')}")
    print()

    phases = schema.get("phases", [])
    if phases:
        print(f"Phases ({len(phases)}):")
        print(f"  {'#':<4} {'ID':<15} {'Title':<25} {'Backends':<20} {'Parallel'}")
        print(f"  {'-'*4} {'-'*15} {'-'*25} {'-'*20} {'-'*8}")
        for i, phase in enumerate(phases, 1):
            pid = phase.get("id", "?")
            title = phase.get("title", "?")
            backends = ", ".join(phase.get("backends", ["coordinator"]))
            parallel = "✓" if phase.get("parallel") else ""
            approval = " 🔒" if phase.get("approval_required") else ""
            print(f"  {i:<4} {pid:<15} {title:<25} {backends:<20} {parallel}{approval}")

    print()
    # Show dependency chain
    if phases:
        chain = " → ".join(p.get("id", "?") for p in phases)
        print(f"Flow: {chain}")

    finalize = schema.get("finalize", {})
    if finalize:
        actions = finalize.get("actions", [])
        if actions:
            print(f"Finalize: {', '.join(actions)}")


def cmd_fork(args):
    """Fork a schema to create a custom version."""
    schemas = find_schemas()
    if args.source not in schemas:
        print(f"Source schema '{args.source}' not found. Available: {', '.join(schemas.keys())}")
        sys.exit(1)

    # Determine target directory
    target_dir = Path.cwd() / "ccg-schemas" / args.target
    if target_dir.exists():
        print(f"Target '{target_dir}' already exists. Choose a different name.")
        sys.exit(1)

    # Copy schema
    import shutil
    source_path = Path(schemas[args.source]["path"])
    shutil.copytree(source_path, target_dir)

    # Update schema name
    schema_file = target_dir / "schema.yaml"
    if schema_file.exists():
        content = schema_file.read_text()
        content = content.replace(f"name: {args.source}", f"name: {args.target}", 1)
        schema_file.write_text(content)

    print(f"✅ Forked '{args.source}' → '{args.target}'")
    print(f"   Path: {target_dir}")
    print(f"   Edit {target_dir}/schema.yaml to customize your workflow.")


def cmd_validate(args):
    """Validate a schema definition."""
    schemas = find_schemas()
    if args.name not in schemas:
        print(f"Schema '{args.name}' not found.")
        sys.exit(1)

    schema = schemas[args.name]["schema"]
    issues = []

    # Check required fields
    if not schema.get("name"):
        issues.append("Missing 'name' field")
    if not schema.get("phases"):
        issues.append("Missing 'phases' field")

    # Check phases
    phase_ids = set()
    for phase in schema.get("phases", []):
        pid = phase.get("id")
        if not pid:
            issues.append("Phase missing 'id' field")
        elif pid in phase_ids:
            issues.append(f"Duplicate phase id: {pid}")
        phase_ids.add(pid)

        # Check dependencies exist
        for req in phase.get("requires", []):
            if req not in phase_ids:
                issues.append(f"Phase '{pid}' requires '{req}' which hasn't been defined yet")

        # Check role references
        for role_name, role_file in phase.get("roles", {}).items():
            role_path = SKILL_DIR / "references" / role_file
            if not role_path.exists():
                issues.append(f"Phase '{pid}' references role '{role_file}' which doesn't exist")

    # Check circular dependencies
    # (Simple check: since we validate requires only reference earlier phases, no cycles possible)

    if issues:
        print(f"❌ Schema '{args.name}' has {len(issues)} issue(s):")
        for issue in issues:
            print(f"   - {issue}")
        sys.exit(1)
    else:
        print(f"✅ Schema '{args.name}' is valid ({len(phase_ids)} phases)")


def cmd_which(args):
    """Show which schema is active and its resolution path."""
    schemas = find_schemas()

    # Try to load config
    sys.path.insert(0, str(Path(__file__).parent))
    try:
        from load_config import load_config, find_config_file
        config = load_config()
        active_schema = config.get("schema", "default")
        config_source = find_config_file() or "(built-in defaults)"
    except ImportError:
        active_schema = "default"
        config_source = "(unable to load config)"

    print(f"Active schema: {active_schema}")
    print(f"Config source: {config_source}")
    print()

    if active_schema in schemas:
        info = schemas[active_schema]
        print(f"Resolved from: {info['source']}")
        print(f"Schema path:   {info['path']}")
    else:
        print(f"⚠ Schema '{active_schema}' not found in any location")

    if args.all:
        print()
        print("All available schemas:")
        for name, info in schemas.items():
            marker = " ← active" if name == active_schema else ""
            print(f"  {name:<20} ({info['source']}){marker}")


def main():
    parser = argparse.ArgumentParser(description="CCG Workflow Schema Manager")
    sub = parser.add_subparsers(dest="command")

    # list
    p_list = sub.add_parser("list", help="List available schemas")
    p_list.add_argument("--json", action="store_true")

    # show
    p_show = sub.add_parser("show", help="Show schema details")
    p_show.add_argument("name", help="Schema name")
    p_show.add_argument("--json", action="store_true")

    # fork
    p_fork = sub.add_parser("fork", help="Fork a schema")
    p_fork.add_argument("source", help="Source schema name")
    p_fork.add_argument("target", help="Target schema name")

    # validate
    p_val = sub.add_parser("validate", help="Validate a schema")
    p_val.add_argument("name", help="Schema name")

    # which
    p_which = sub.add_parser("which", help="Show active schema")
    p_which.add_argument("--all", action="store_true", help="Show all schemas")

    args = parser.parse_args()

    if args.command == "list":
        cmd_list(args)
    elif args.command == "show":
        cmd_show(args)
    elif args.command == "fork":
        cmd_fork(args)
    elif args.command == "validate":
        cmd_validate(args)
    elif args.command == "which":
        cmd_which(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
