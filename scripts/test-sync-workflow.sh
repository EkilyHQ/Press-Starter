#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

workflow=".github/workflows/sync-from-press-release.yml"

if [[ ! -f "${workflow}" ]]; then
  echo "expected ${workflow} to exist" >&2
  exit 1
fi

if ! grep -F 'repository_dispatch:' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must accept repository_dispatch events" >&2
  exit 1
fi

if ! grep -F 'press-system-release' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must listen for the press-system-release event" >&2
  exit 1
fi

if ! grep -F 'workflow_dispatch:' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must support manual runs" >&2
  exit 1
fi

if ! grep -F 'schedule:' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must include a scheduled catch-up run" >&2
  exit 1
fi

if ! grep -F 'PRESS_REPOSITORY' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must allow the Press repository to be configured" >&2
  exit 1
fi

if ! grep -F 'scripts/sync-from-press-release.sh' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must run the local sync script" >&2
  exit 1
fi

if ! grep -F 'scripts/test-sync-from-press-release.sh' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must validate the sync script before publishing to main" >&2
  exit 1
fi

if ! grep -F 'scripts/test-pages-workflow.sh' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must validate the Pages workflow before publishing to main" >&2
  exit 1
fi

if ! grep -F 'actions/checkout@v6' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must use a Node 24-compatible checkout action" >&2
  exit 1
fi

if grep -E 'actions/(checkout@v4|upload-artifact@v4)' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must not pin known Node 20-backed GitHub actions" >&2
  exit 1
fi

if grep -F 'gh pr create' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must not open pull requests for runtime updates" >&2
  exit 1
fi

if grep -F 'gh pr edit' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must not edit pull requests for runtime updates" >&2
  exit 1
fi

if grep -F 'pull-requests: write' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must not request pull request write permissions" >&2
  exit 1
fi

if ! grep -F 'git pull --rebase origin main' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must rebase on origin/main before publishing" >&2
  exit 1
fi

if ! grep -F 'git push origin HEAD:main' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must publish runtime updates directly to main" >&2
  exit 1
fi

test_line="$(grep -nF 'scripts/test-sync-from-press-release.sh' "${workflow}" | head -n 1 | cut -d: -f1)"
pages_test_line="$(grep -nF 'scripts/test-pages-workflow.sh' "${workflow}" | head -n 1 | cut -d: -f1)"
push_line="$(grep -nF 'git push origin HEAD:main' "${workflow}" | head -n 1 | cut -d: -f1)"
if [[ -z "${test_line}" || -z "${pages_test_line}" || -z "${push_line}" || "${test_line}" -ge "${push_line}" || "${pages_test_line}" -ge "${push_line}" ]]; then
  echo "YAP sync workflow must validate sync and Pages scripts before pushing to main" >&2
  exit 1
fi

if ! grep -F 'PRESS_RELEASE_TOKEN' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must support a Press release read token" >&2
  exit 1
fi

if ! grep -F 'git status --porcelain' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must detect untracked files after syncing" >&2
  exit 1
fi

if ! grep -Fx 'dist/' .gitignore >/dev/null; then
  echo "YAP sync workflow scratch files must stay out of commits" >&2
  exit 1
fi

if grep -F 'assets/themes/packs.json' "${workflow}" >/dev/null; then
  echo "YAP sync workflow must not copy packs.json directly from Press releases" >&2
  exit 1
fi

echo "ok - YAP sync workflow"
