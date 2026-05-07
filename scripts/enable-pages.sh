#!/usr/bin/env bash
set -euo pipefail

repo="${1:-}"
if [[ -z "${repo}" ]]; then
  repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if [[ ! "${repo}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "usage: $0 [OWNER/REPO]" >&2
  exit 2
fi

if gh api "repos/${repo}/pages" >/dev/null 2>&1; then
  echo "GitHub Pages is already enabled for ${repo}."
  exit 0
fi

gh api --method POST "repos/${repo}/pages" -f build_type=workflow >/dev/null
echo "Enabled GitHub Pages for ${repo} using GitHub Actions."
