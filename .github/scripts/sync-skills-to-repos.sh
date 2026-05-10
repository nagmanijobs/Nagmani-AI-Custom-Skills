#!/usr/bin/env bash
set -euo pipefail

# Sync skills from this central repository into all repositories in an owner account.
# Expected environment variables:
# - TARGET_OWNER (required)
# - TARGET_OWNER_TYPE (optional: user|org, default: user)
# - GH_TOKEN (required, PAT with repo scope)
# - TARGET_REPOS_CSV (optional: comma-separated full repo names; if set, only these repos are synced)
# - SKIP_REPOS_CSV (optional: comma-separated full repo names)

if [[ -z "${TARGET_OWNER:-}" ]]; then
  echo "TARGET_OWNER is required" >&2
  exit 1
fi

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "GH_TOKEN is required" >&2
  exit 1
fi

TARGET_OWNER_TYPE="${TARGET_OWNER_TYPE:-user}"
TARGET_REPOS_CSV="${TARGET_REPOS_CSV:-}"
SKIP_REPOS_CSV="${SKIP_REPOS_CSV:-}"
SYNC_BRANCH="chore/sync-copilot-skills"
SOURCE_ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
SOURCE_SKILLS_DIR="$SOURCE_ROOT/.github/skills"

if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
  echo "No skills directory found at $SOURCE_SKILLS_DIR" >&2
  exit 1
fi

IFS=',' read -r -a SKIP_REPOS <<< "$SKIP_REPOS_CSV"

if [[ -n "$TARGET_REPOS_CSV" ]]; then
  IFS=',' read -r -a repos <<< "$TARGET_REPOS_CSV"
  echo "Using explicit allowlist from TARGET_REPOS_CSV"
else
  echo "Discovering repositories for owner '$TARGET_OWNER' (type: $TARGET_OWNER_TYPE)..."
  if [[ "$TARGET_OWNER_TYPE" == "org" ]]; then
    mapfile -t repos < <(gh api --paginate "orgs/$TARGET_OWNER/repos?per_page=100&type=all" --jq '.[] | select(.archived == false) | .full_name')
  else
    mapfile -t repos < <(gh api --paginate "users/$TARGET_OWNER/repos?per_page=100&type=owner" --jq '.[] | select(.archived == false) | .full_name')
  fi
fi

should_skip_repo() {
  local repo="$1"
  for skipped in "${SKIP_REPOS[@]}"; do
    if [[ -n "$skipped" && "$repo" == "$skipped" ]]; then
      return 0
    fi
  done
  return 1
}

if [[ "${#repos[@]}" -eq 0 ]]; then
  echo "No repositories found for owner '$TARGET_OWNER'."
  exit 0
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

for repo in "${repos[@]}"; do
  # Skip this central source repository and any explicitly skipped repositories.
  if [[ "$repo" == "${GITHUB_REPOSITORY}" ]] || should_skip_repo "$repo"; then
    echo "Skipping $repo"
    continue
  fi

  repo_name="${repo##*/}"
  repo_dir="$tmp_dir/$repo_name"

  echo "\nSyncing $repo..."
  git clone --depth 1 "https://x-access-token:${GH_TOKEN}@github.com/${repo}.git" "$repo_dir" >/dev/null 2>&1 || {
    echo "Failed to clone $repo; skipping."
    continue
  }

  mkdir -p "$repo_dir/.github/skills"
  rsync -a --delete "$SOURCE_SKILLS_DIR/" "$repo_dir/.github/skills/"

  # Also sync prompt examples if they exist
  if [[ -f "$SOURCE_ROOT/.github/skills/PROMPT_EXAMPLES.md" ]]; then
    cp "$SOURCE_ROOT/.github/skills/PROMPT_EXAMPLES.md" "$repo_dir/.github/skills/PROMPT_EXAMPLES.md"
  fi

  if git -C "$repo_dir" diff --quiet; then
    echo "No changes needed for $repo"
    continue
  fi

  git -C "$repo_dir" config user.name "skills-sync-bot"
  git -C "$repo_dir" config user.email "skills-sync-bot@users.noreply.github.com"
  git -C "$repo_dir" checkout -B "$SYNC_BRANCH"
  git -C "$repo_dir" add .github/skills
  git -C "$repo_dir" commit -m "chore: sync Copilot skills from central repository"
  git -C "$repo_dir" push -u origin "$SYNC_BRANCH" --force

  existing_prs=$(gh pr list --repo "$repo" --head "$SYNC_BRANCH" --state open --json number --jq 'length')
  if [[ "$existing_prs" == "0" ]]; then
    gh pr create \
      --repo "$repo" \
      --base main \
      --head "$SYNC_BRANCH" \
      --title "chore: sync Copilot skills from central repository" \
      --body "Automated sync from $GITHUB_REPOSITORY.\n\nThis PR updates .github/skills to match the central skill source." >/dev/null
    echo "Created PR for $repo"
  else
    echo "Updated existing sync PR for $repo"
  fi
done

echo "\nSkill synchronization completed."