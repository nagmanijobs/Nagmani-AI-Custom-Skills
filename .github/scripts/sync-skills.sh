#!/usr/bin/env bash
set -euo pipefail

# Canonical local sync script.
# Syncs Copilot skills from this central repository into the current repository.
# Usage:
#   .github/scripts/sync-skills.sh [skill-name]

SOURCE_REPO="${SOURCE_REPO:-nagmanijobs/Nagmani-AI-Custom-Skills}"
SOURCE_BRANCH="${SOURCE_BRANCH:-main}"
TARGET_DIR=".github/skills"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required." >&2
  exit 1
fi

SKILL_NAME="${1:-}"

echo "Cloning $SOURCE_REPO ($SOURCE_BRANCH) to temporary directory..."
git clone --depth 1 --branch "$SOURCE_BRANCH" "https://github.com/$SOURCE_REPO.git" "$TMP_DIR/source" >/dev/null

mkdir -p "$TARGET_DIR"

if [[ -n "$SKILL_NAME" ]]; then
  SOURCE_PATH="$TMP_DIR/source/.github/skills/$SKILL_NAME"
  DEST_PATH="$TARGET_DIR/$SKILL_NAME"

  if [[ ! -d "$SOURCE_PATH" ]]; then
    echo "Error: Skill '$SKILL_NAME' not found in $SOURCE_REPO." >&2
    exit 1
  fi

  rm -rf "$DEST_PATH"
  cp -R "$SOURCE_PATH" "$DEST_PATH"
  echo "Synced skill: $SKILL_NAME"
else
  rm -rf "$TARGET_DIR"
  mkdir -p "$TARGET_DIR"
  cp -R "$TMP_DIR/source/.github/skills/." "$TARGET_DIR/"
  echo "Synced all skills from $SOURCE_REPO"
fi

echo "Done."