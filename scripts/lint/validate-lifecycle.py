#!/usr/bin/env python3
"""Validate lifecycle authority and the complete migration graph."""

from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys


def frontmatter(path: pathlib.Path) -> dict[str, str]:
    """Parse the deliberately flat capability frontmatter."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        raise ValueError("capability frontmatter is missing")
    values: dict[str, str] = {}
    for line in lines[1:]:
        if line == "---":
            return values
        key, separator, value = line.partition(":")
        if not separator or key in values:
            raise ValueError(f"malformed or duplicate capability field: {line}")
        values[key] = value.strip()
    raise ValueError("capability frontmatter is unterminated")


def version_claims(root: pathlib.Path) -> list[tuple[str, str]]:
    """Return every derived JSON version claim that must match authority."""
    paths = [
        root / ".claude-plugin/plugin.json",
        root / ".claude-plugin/marketplace.json",
        root / ".codex-plugin/plugin.json",
        root / "plugins/spade-framework/.codex-plugin/plugin.json",
    ]
    claims: list[tuple[str, str]] = []
    for path in paths:
        data = json.loads(path.read_text(encoding="utf-8"))
        if path.name == "marketplace.json":
            claims.append((str(path.relative_to(root)) + " metadata", data["metadata"]["version"]))
            claims.append((str(path.relative_to(root)) + " plugin", data["plugins"][0]["version"]))
        else:
            claims.append((str(path.relative_to(root)), data["version"]))
    return claims


def git_show(root: pathlib.Path, commit: str, path: str) -> bytes | None:
    """Read one immutable release path, returning None when it did not exist."""
    result = subprocess.run(
        ["git", "-C", str(root), "show", f"{commit}:{path}"],
        check=False,
        capture_output=True,
    )
    return result.stdout if result.returncode == 0 else None


def scrub_tracker_identity(content: bytes) -> bytes:
    """Replace the maintainer's tracker identity in a release config with placeholders."""

    content = re.sub(rb"^(  team: ).*$", rb"\1Example Team", content, flags=re.MULTILINE)
    content = re.sub(rb"https://linear\.app/[^/]+/", rb"https://linear.app/example/", content)
    return re.sub(rb"https://horizon\.[^/]+/", rb"https://horizon.example.com/", content)


def normalize_fixture(version: str, path: str, content: bytes) -> bytes:
    """Apply the tracker-identity scrub and the two approved PS-2420 wording corrections."""

    if path == ".spade/config":
        content = scrub_tracker_identity(content)
    if version not in {"3.1.0", "3.2.0"}:
        return content
    if path == ".spade/config":
        return content.replace(
            b"# - Plans are persisted locally under .spade/plans/ in addition to Linear comments.",
            b"# - In linear mode, Linear is canonical; .spade/plans/ is fallback-only when the tracker cannot accept a Plan.",
        )
    if path == "AGENTS.md":
        return content.replace(b"Revertable as one commit", b"Reversible as one commit")
    return content


def main() -> int:
    """Check authority fields, migration reachability, and derived claims."""
    root = pathlib.Path(__file__).resolve().parents[2]
    capability = frontmatter(root / "src/CAPABILITIES.md")
    required = {
        "version",
        "canonical_remote",
        "release_ref_policy",
        "minimum_supported_version",
        "published_versions",
        "skills",
        "review_personas",
        "researcher",
        "helpers",
    }
    missing = sorted(required - capability.keys())
    if missing:
        raise ValueError(f"missing capability fields: {', '.join(missing)}")
    if capability["canonical_remote"] != "https://github.com/fuseboxhq/spade-framework.git":
        raise ValueError("canonical remote drifted")
    if capability["release_ref_policy"] != "commit":
        raise ValueError("release authority must be an exact commit")

    published = capability["published_versions"].split(",")
    if published[0] != capability["minimum_supported_version"] or published[-1] != capability["version"]:
        raise ValueError("published version endpoints do not match authority")
    if len(published) != len(set(published)):
        raise ValueError("published versions contain duplicates")

    rows: dict[str, tuple[str, str, tuple[str, ...]]] = {}
    for raw in (root / "migrations/manifest.tsv").read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        parts = raw.split("|")
        if len(parts) != 4:
            raise ValueError(f"malformed migration row: {raw}")
        source, target, action, paths = parts
        if source in rows:
            raise ValueError(f"duplicate migration start: {source}")
        if action not in {"pin", "refresh_fragments", "intent_mode_fragments"}:
            raise ValueError(f"unknown migration action: {action}")
        rows[source] = (target, action, tuple(paths.split(",")))

    expected_sources = published[:-1]
    if set(rows) != set(expected_sources):
        raise ValueError("migration starts do not equal published non-current versions")
    for source, target in zip(published, published[1:]):
        if rows[source][0] != target:
            raise ValueError(f"migration chain breaks at {source}")
        paths = rows[source][2]
        if paths[-1] != ".spade/version" or len(paths) != len(set(paths)):
            raise ValueError(f"migration paths are not unique with version last: {source}")

    fixture_rows = [
        line.split("|")
        for line in (root / "tests/fixtures/lifecycle/historical.tsv").read_text(encoding="utf-8").splitlines()
        if line and not line.startswith("#")
    ]
    if any(len(row) != 2 or len(row[1]) != 40 or any(character not in "0123456789abcdef" for character in row[1]) for row in fixture_rows):
        raise ValueError("historical fixture row or release commit is malformed")
    fixture_versions = [row[0] for row in fixture_rows]
    if fixture_versions != published:
        raise ValueError("historical fixture matrix does not equal published versions")
    release_root = root / "tests/fixtures/lifecycle/releases"
    if sorted(path.name for path in release_root.iterdir() if path.is_dir()) != sorted(published):
        raise ValueError("release-derived fixture directories do not equal published versions")
    for version, commit in fixture_rows:
        fixture = release_root / version
        if (fixture / ".release-commit").read_text(encoding="utf-8") != f"{commit}\n":
            raise ValueError(f"fixture commit receipt drifted: {version}")
        if (fixture / ".spade/version").read_text(encoding="utf-8") != f"spade_version={version}\n":
            raise ValueError(f"fixture version drifted: {version}")
        release_config = git_show(root, commit, ".spade/config")
        if release_config is None or (fixture / ".spade/config").read_bytes() != normalize_fixture(version, ".spade/config", release_config):
            raise ValueError(f"fixture config is not release-derived: {version}")
        release_intent = git_show(root, commit, "INTENT.md")
        fixture_intent = fixture / "INTENT.md"
        if release_intent is None and fixture_intent.exists():
            raise ValueError(f"fixture invents historical intent: {version}")
        if release_intent is not None and fixture_intent.read_bytes() != release_intent:
            raise ValueError(f"fixture intent is not release-derived: {version}")
        for name in ("AGENTS", "CLAUDE"):
            fragment = git_show(root, commit, f"fragments/{name}-section.md")
            if fragment is None:
                raise ValueError(f"release fragment is missing: {version} {name}")
            expected = (
                b"consumer-owned prefix\n\n"
                + f"<!-- SPADE-FRAMEWORK-START v{version} -->\n".encode()
                + fragment
                + b"<!-- SPADE-FRAMEWORK-END -->\n\nconsumer-owned suffix\n"
            )
            expected = normalize_fixture(version, f"{name}.md", expected)
            if (fixture / f"{name}.md").read_bytes() != expected:
                raise ValueError(f"fixture fragment is not release-derived: {version} {name}")

    authority = capability["version"]
    pin = (root / ".spade/version").read_text(encoding="utf-8").strip()
    if pin != f"spade_version={authority}":
        raise ValueError("repository pin differs from capability authority")
    for label, value in version_claims(root):
        if value != authority:
            raise ValueError(f"version claim drift: {label}={value}")

    helpers = capability["helpers"].split(",")
    for helper in helpers:
        if not (root / "bin" / helper).is_file():
            raise ValueError(f"declared helper is missing: {helper}")
    print(f"lifecycle-authority: {len(published)} versions, {len(rows)} migration units, {len(helpers)} helpers")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (KeyError, OSError, ValueError, json.JSONDecodeError) as error:
        print(f"lifecycle-authority: FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
