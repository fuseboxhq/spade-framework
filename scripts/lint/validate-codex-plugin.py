#!/usr/bin/env python3
"""Validate the generated Codex plugin using the bounded stdlib-only policy."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def declared_skill_count() -> int:
    """Count the skills declared in src/CAPABILITIES.md, the inventory authority."""
    manifest = (Path(__file__).resolve().parents[2] / "src" / "CAPABILITIES.md").read_text(encoding="utf-8")
    match = re.search(r"^skills: (.+)$", manifest, re.MULTILINE)
    if not match:
        fail("src/CAPABILITIES.md declares no skills")
    return len(match.group(1).split(","))


def fail(message: str) -> None:
    """Print one validator error and terminate with a failing status."""

    print(f"validate-codex-plugin: {message}", file=sys.stderr)
    raise SystemExit(1)


def validate(root: Path, *, require_folder_name: bool = True) -> None:
    """Validate manifest identity, required metadata, paths, and inventory."""
    manifest_path = root / ".codex-plugin" / "plugin.json"
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot parse {manifest_path}: {exc}")

    required = ("name", "version", "description", "author", "skills", "interface")
    missing = [field for field in required if not manifest.get(field)]
    if missing:
        fail(f"missing required fields: {', '.join(missing)}")
    if require_folder_name and manifest["name"] != root.name:
        fail(f"manifest name {manifest['name']!r} must match plugin folder {root.name!r}")
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", manifest["version"]):
        fail("version is not strict semver")
    if not isinstance(manifest["author"], dict) or not manifest["author"].get("name"):
        fail("author.name is required")

    interface_required = (
        "displayName",
        "shortDescription",
        "longDescription",
        "developerName",
        "category",
        "capabilities",
    )
    missing_interface = [field for field in interface_required if not manifest["interface"].get(field)]
    if missing_interface:
        fail(f"missing interface fields: {', '.join(missing_interface)}")

    skills_value = manifest["skills"]
    if not isinstance(skills_value, str) or not skills_value.startswith("./"):
        fail("skills must be a root-relative ./ path")
    skills_path = (root / skills_value[2:]).resolve()
    if root not in skills_path.parents or not skills_path.is_dir():
        fail("skills path escapes the plugin root or does not exist")
    skill_dirs = sorted(path.name for path in skills_path.iterdir() if path.is_dir())
    expected = declared_skill_count()
    if len(skill_dirs) != expected or any(not (skills_path / name / "SKILL.md").is_file() for name in skill_dirs):
        fail(f"Codex plugin must expose exactly {expected} skill directories with SKILL.md")

    unsupported = sorted(set(manifest).intersection({"hooks"}))
    if unsupported:
        fail(f"unsupported manifest fields: {', '.join(unsupported)}")
    print(f"validate-codex-plugin: {root} is valid")


def main() -> None:
    """Validate the requested plugin root or the repository root by default."""

    default_root = Path(__file__).resolve().parents[2]
    args = sys.argv[1:]
    option = "--allow-checkout-name"
    if args.count(option) > 1:
        fail("usage: validate-codex-plugin.py [root] [--allow-checkout-name]")
    allow_checkout_name = option in args
    roots = [arg for arg in args if arg != option]
    if len(roots) > 1 or any(root.startswith("--") for root in roots):
        fail("usage: validate-codex-plugin.py [root] [--allow-checkout-name]")
    root = Path(roots[0]).resolve() if roots else default_root
    validate(root, require_folder_name=not allow_checkout_name)


if __name__ == "__main__":
    main()
