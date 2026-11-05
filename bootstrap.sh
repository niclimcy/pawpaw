#!/bin/bash
#
# bootstrap.sh — sets up local development tooling for pawpaw.
# Installs a git pre-commit hook that lints staged Swift files with swift-format.
#
# Usage: ./bootstrap.sh

set -euo pipefail

# Run from the repository root regardless of where the script is invoked.
REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Resolve the hooks directory (respects worktrees and core.hooksPath).
HOOKS_DIR="$(git rev-parse --git-path hooks)"
HOOK_PATH="$HOOKS_DIR/pre-commit"
mkdir -p "$HOOKS_DIR"

# Verify swift-format is available.
if ! xcrun --find swift-format >/dev/null 2>&1; then
  echo "⚠️  swift-format not found via xcrun. Install Xcode 16+ (or swift-format) for the hook to work."
fi

# Write the hook to a temp file first so we can compare with any existing hook.
TMP_HOOK="$(mktemp)"
trap 'rm -f "$TMP_HOOK"' EXIT

cat > "$TMP_HOOK" <<'EOF'
#!/bin/bash

# Find staged .swift files (ignoring deleted files).
# Note: bash variables cannot hold NUL bytes, so we check for files first and
# stream the NUL-separated list directly into xargs instead of storing it.
if ! git diff --cached --name-only --diff-filter=d | grep -q '\.swift$'; then
  exit 0
fi

echo "Checking Swift code formatting..."

# Run swift-format lint mode. It will print warnings/errors and return a non-zero exit code if things are wrong.
if ! git diff --cached --name-only --diff-filter=d -z | grep -z '\.swift$' | xargs -0 xcrun swift-format lint --strict; then
  echo "❌ Code formatting issues found."
  exit 1
fi

echo "✅ Formatting check passed!"
exit 0
EOF

# Back up an existing, different hook before overwriting it.
if [ -f "$HOOK_PATH" ] && ! cmp -s "$TMP_HOOK" "$HOOK_PATH"; then
  BACKUP="$HOOK_PATH.backup.$(date +%Y%m%d%H%M%S)"
  cp "$HOOK_PATH" "$BACKUP"
  echo "ℹ️  Existing pre-commit hook backed up to $BACKUP"
fi

cp "$TMP_HOOK" "$HOOK_PATH"
chmod +x "$HOOK_PATH"

echo "✅ Installed pre-commit hook at $HOOK_PATH"
