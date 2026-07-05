#!/usr/bin/env bash
# bump-version.sh x.y.z — set the plugin version in BOTH manifests atomically.
#
# The version lives in two files (.claude-plugin/plugin.json and
# .claude-plugin/marketplace.json .plugins[0].version); editing them by hand
# is how they drift apart. This is the only supported way to change it.
# (Simplified from superpowers' .version-bump.json multi-file mechanism.)
set -euo pipefail

VERSION="${1:-}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || { echo "usage: bump-version.sh x.y.z (got: '${VERSION}')" >&2; exit 2; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

python3 - "$ROOT" "$VERSION" <<'EOF'
import json, sys
root, version = sys.argv[1], sys.argv[2]

paths = {
    f"{root}/plugin/.claude-plugin/plugin.json": lambda d: d.__setitem__("version", version),
    f"{root}/.claude-plugin/marketplace.json":   lambda d: d["plugins"][0].__setitem__("version", version),
}
for path, setter in paths.items():
    with open(path) as f:
        data = json.load(f)
    setter(data)
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

# Verify both agree after the write
v1 = json.load(open(f"{root}/plugin/.claude-plugin/plugin.json"))["version"]
v2 = json.load(open(f"{root}/.claude-plugin/marketplace.json"))["plugins"][0]["version"]
assert v1 == v2 == version, f"post-write mismatch: {v1} vs {v2}"
print(f"version -> {version} (both manifests)")
EOF

echo "Now add a CHANGELOG.md entry for ${VERSION} in the same commit."
