#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

workflow=".github/workflows/sync-from-press-release.yml"

if [[ ! -f "${workflow}" ]]; then
  echo "expected ${workflow} to exist" >&2
  exit 1
fi

if ! grep -F 'repository_dispatch:' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must accept repository_dispatch events" >&2
  exit 1
fi

if ! grep -F 'press-system-release' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must listen for the press-system-release event" >&2
  exit 1
fi

if ! grep -F 'workflow_dispatch:' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must support manual runs" >&2
  exit 1
fi

if ! grep -F 'schedule:' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must include a scheduled catch-up run" >&2
  exit 1
fi

if ! grep -F 'PRESS_REPOSITORY' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must allow the Press repository to be configured" >&2
  exit 1
fi

if ! grep -F 'scripts/sync-from-press-release.sh' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must run the local sync script" >&2
  exit 1
fi

if ! grep -F 'scripts/test-sync-from-press-release.sh' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must validate the sync script before opening a PR" >&2
  exit 1
fi

if ! grep -F 'gh pr create' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must open a pull request for runtime updates" >&2
  exit 1
fi

if ! grep -F 'gh pr edit "${pr_number}"' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must update an existing sync pull request" >&2
  exit 1
fi

if ! grep -F 'PRESS_RELEASE_TOKEN' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must support a Press release read token" >&2
  exit 1
fi

if ! grep -F 'GH_TOKEN: ${{ github.token }}' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must use the repository token for Starter pull requests" >&2
  exit 1
fi

if ! grep -F 'git status --porcelain' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must detect untracked files after syncing" >&2
  exit 1
fi

if ! grep -Fx 'dist/' .gitignore >/dev/null; then
  echo "Starter sync workflow scratch files must stay out of commits" >&2
  exit 1
fi

if grep -F 'assets/themes/packs.json' "${workflow}" >/dev/null; then
  echo "Starter sync workflow must not copy packs.json directly from Press releases" >&2
  exit 1
fi

echo "ok - starter sync workflow"
