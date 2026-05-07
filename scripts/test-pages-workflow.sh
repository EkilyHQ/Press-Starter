#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

workflow=".github/workflows/pages.yml"

if [[ ! -f "${workflow}" ]]; then
  echo "expected ${workflow} to exist" >&2
  exit 1
fi

if ! grep -F 'push:' "${workflow}" >/dev/null; then
  echo "Pages workflow must deploy on pushes" >&2
  exit 1
fi

if ! grep -F 'workflow_dispatch:' "${workflow}" >/dev/null; then
  echo "Pages workflow must support manual runs" >&2
  exit 1
fi

if ! grep -F 'pages: write' "${workflow}" >/dev/null; then
  echo "Pages workflow must grant pages write permission" >&2
  exit 1
fi

if ! grep -F 'id-token: write' "${workflow}" >/dev/null; then
  echo "Pages workflow must grant OIDC token permission" >&2
  exit 1
fi

if ! grep -F 'actions/configure-pages@v5' "${workflow}" >/dev/null; then
  echo "Pages workflow must configure GitHub Pages" >&2
  exit 1
fi

if ! grep -F 'enablement: true' "${workflow}" >/dev/null; then
  echo "Pages workflow must enable Pages for fresh template repositories" >&2
  exit 1
fi

if ! grep -F 'actions/upload-pages-artifact@v3' "${workflow}" >/dev/null; then
  echo "Pages workflow must upload a Pages artifact" >&2
  exit 1
fi

if ! grep -F 'actions/deploy-pages@v4' "${workflow}" >/dev/null; then
  echo "Pages workflow must deploy with deploy-pages" >&2
  exit 1
fi

if ! grep -F 'path: dist/pages' "${workflow}" >/dev/null; then
  echo "Pages workflow must publish the curated dist/pages artifact" >&2
  exit 1
fi

for path in index.html index_editor.html site.yaml .nojekyll assets wwwroot; do
  if ! grep -F "${path}" "${workflow}" >/dev/null; then
    echo "Pages workflow must include ${path} in the artifact" >&2
    exit 1
  fi
done

echo "ok - pages workflow"
