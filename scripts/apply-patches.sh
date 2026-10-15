#!/usr/bin/env bash
# Apply the independent patchset to a CLEAN checkout of fork beta.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash scripts/apply-patches.sh PATCHSET_DIR SOURCE_DIR" >&2
  exit 2
fi

patchset="$(cd "$1" && pwd)"
source_dir="$(cd "$2" && pwd)"
series="$patchset/patches/series"

if [[ ! -f "$series" || ! -d "$source_dir/.git" && ! -f "$source_dir/.git" ]]; then
  echo "Missing patches/series or target git checkout." >&2
  exit 2
fi
if ! git -C "$source_dir" diff --quiet || ! git -C "$source_dir" diff --cached --quiet; then
  echo "Refusing to patch a dirty checkout." >&2
  exit 1
fi

echo "Base commit: $(git -C "$source_dir" rev-parse HEAD)"
echo "Patchset commit: $(git -C "$patchset" rev-parse HEAD)"
applied=0
skipped=0
while IFS= read -r entry || [[ -n "$entry" ]]; do
  [[ -z "$entry" || "$entry" == \#* ]] && continue
  if [[ ! "$entry" =~ ^patches/[[:alnum:]_.-]+\.patch$ ]]; then
    echo "Invalid patch entry: $entry" >&2
    exit 1
  fi
  file="$patchset/$entry"
  if [[ ! -f "$file" ]]; then
    echo "Missing patch: $entry" >&2
    exit 1
  fi
  echo "Checking $entry"
  if git -C "$source_dir" apply --reverse --check "$file" 2>/dev/null; then
    echo "SKIP (already in source): $entry"
    skipped=$((skipped + 1))
  elif git -C "$source_dir" apply --check "$file"; then
    git -C "$source_dir" apply "$file"
    echo "APPLIED: $entry"
    applied=$((applied + 1))
  else
    echo "PATCH CONFLICT: $entry. Review upstream; never auto-merge." >&2
    exit 1
  fi
done < "$series"

git -C "$source_dir" diff --check
echo "Summary: $applied applied, $skipped already included upstream"
git -C "$source_dir" diff --stat
