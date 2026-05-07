#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

script="scripts/enable-pages.sh"

if [[ ! -x "${script}" ]]; then
  echo "expected ${script} to be executable" >&2
  exit 1
fi

if grep -F '${{ inputs.' "${script}" >/dev/null; then
  echo "enable-pages script must not interpolate workflow inputs" >&2
  exit 1
fi

if ! grep -F 'gh repo view --json nameWithOwner' "${script}" >/dev/null; then
  echo "enable-pages script must infer the current repository" >&2
  exit 1
fi

if ! grep -F 'build_type=workflow' "${script}" >/dev/null; then
  echo "enable-pages script must enable the GitHub Actions Pages source" >&2
  exit 1
fi

if ! grep -F 'repos/${repo}/pages' "${script}" >/dev/null; then
  echo "enable-pages script must call the Pages REST API" >&2
  exit 1
fi

echo "ok - enable pages script"
