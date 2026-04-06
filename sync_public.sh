#!/usr/bin/env bash
# =============================================================================
# sync_public.sh — Sync main branch to GitHub, stripping CDW-specific files
# =============================================================================
# This script maintains a 'public' branch that mirrors 'main' but excludes
# files containing institutional CDW schema, data profiles, and results.
#
# Usage:
#   ./sync_public.sh              # Sync and push to GitHub
#   ./sync_public.sh --dry-run    # Show what would happen without pushing
#
# Setup (one-time):
#   git remote add gitlab https://gitlab.com/YOUR_USERNAME/AutoTTE.git
#   git remote rename origin github   # if origin was GitHub
#   # Then: do all work on main, push to both remotes
# =============================================================================

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[DRY RUN] No changes will be pushed."
  echo ""
fi

# Files to strip from the public branch (glob patterns)
# These contain institutional CDW schema, data profiles, or real results
STRIP_FILES=(
  "CDW_DBO_database_schema.txt"
  "CDW_data_profile.md"
  "MasterPatientIndex_DBO_database_schema.txt"
  "CDW_DB_Profiler.qmd"
  "results/"
)

# Ensure we're in the repo root
cd "$(git rev-parse --show-toplevel)"

# Save current branch to return to it later
ORIGINAL_BRANCH=$(git branch --show-current)

echo "=== Syncing public branch with main ==="
echo ""

# Make sure main is clean
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: Working tree is dirty. Commit or stash your changes first."
  exit 1
fi

# Create public branch if it doesn't exist
if ! git show-ref --verify --quiet refs/heads/public; then
  echo "Creating 'public' branch from main..."
  git checkout -b public main
else
  echo "Switching to 'public' branch..."
  git checkout public
  echo "Merging main into public..."
  git merge main --no-edit
fi

# Remove CDW-specific files (--cached = remove from git, keep on disk)
echo ""
echo "Stripping CDW-specific files..."
for pattern in "${STRIP_FILES[@]}"; do
  if git ls-files --error-unmatch "$pattern" &>/dev/null 2>&1; then
    echo "  Removing: $pattern"
    if [[ "$pattern" == */ ]]; then
      git rm -r --cached --quiet "$pattern" 2>/dev/null || true
    else
      git rm --cached --quiet "$pattern" 2>/dev/null || true
    fi
  fi
done

# Only commit if there are staged changes
if [[ -n "$(git diff --cached --name-only)" ]]; then
  git commit -m "Sync from main — strip CDW-specific files for public repo"
  echo ""
  echo "Committed stripped changes."
else
  echo ""
  echo "No files to strip (already clean)."
fi

# Push to GitHub
if $DRY_RUN; then
  echo ""
  echo "[DRY RUN] Would push public branch to github remote as main."
  echo "  Command: git push github public:main"
else
  echo ""
  echo "Pushing to GitHub..."
  git push github public:main
  echo "Done."
fi

# Return to original branch
echo ""
echo "Returning to '$ORIGINAL_BRANCH' branch..."
git checkout "$ORIGINAL_BRANCH"

echo ""
echo "=== Sync complete ==="
echo "  GitLab (private):  push main directly with 'git push gitlab main'"
echo "  GitHub (public):   run this script to sync"
