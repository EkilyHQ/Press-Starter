#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

cd "${repo_root}"
scenario_repo="${tmp_dir}/yap"
mkdir -p "${scenario_repo}"
tracked_list="${tmp_dir}/tracked-files.txt"
git ls-files -z > "${tracked_list}"
for candidate in scripts/build-pages-artifact.sh scripts/pages-editor-exclusion.mjs scripts/test-pages-artifact.sh; do
  if ! git ls-files --error-unmatch "${candidate}" >/dev/null 2>&1; then
    printf '%s\0' "${candidate}" >> "${tracked_list}"
  fi
done
(
  tar --null -T "${tracked_list}" -cf -
) | (
  cd "${scenario_repo}"
  tar -xf -
)
(
  cd "${scenario_repo}"
  git init -q
  git add -A
  bash scripts/build-pages-artifact.sh >/dev/null
)

pages_dir="${scenario_repo}/dist/pages"
if [[ ! -f "${pages_dir}/index_editor.html" || ! -f "${pages_dir}/index_editor_preview.html" ]]; then
  echo "YAP Pages must retain both editor entries when the marker is absent" >&2
  exit 1
fi
if [[ -e "${pages_dir}/.press-pages-no-editor" || -L "${pages_dir}/.press-pages-no-editor" ]]; then
  echo "YAP Pages must not synthesize the editor exclusion marker" >&2
  exit 1
fi

printf '\nfeatures:\n  editorEntry:\n    enabled: false\n' >> "${scenario_repo}/site.yaml"
(
  cd "${scenario_repo}"
  git add site.yaml
  bash scripts/build-pages-artifact.sh >/dev/null
)
if [[ ! -f "${pages_dir}/index_editor.html" || ! -f "${pages_dir}/index_editor_preview.html" ]]; then
  echo "editorEntry=false without the tracked marker must remain presentation-only in YAP Pages" >&2
  exit 1
fi
if ! cmp -s "${scenario_repo}/assets/press-runtime-manifest.json" "${pages_dir}/assets/press-runtime-manifest.json"; then
  echo "editorEntry=false without the tracked marker must not project the YAP runtime manifest" >&2
  exit 1
fi
presentation_pages="${tmp_dir}/presentation-only-pages"
cp -R "${pages_dir}" "${presentation_pages}"

printf '' > "${scenario_repo}/.press-pages-no-editor"
(
  cd "${scenario_repo}"
  git add .press-pages-no-editor
  bash scripts/build-pages-artifact.sh >/dev/null
)
if [[ -e "${pages_dir}/index_editor.html" || -e "${pages_dir}/index_editor_preview.html" ]]; then
  echo "tracked marker plus explicit editorEntry=false must exclude both YAP Pages editor entries" >&2
  exit 1
fi
if [[ ! -f "${pages_dir}/.press-pages-no-editor" ]]; then
  echo "YAP Pages must retain the tracked editor exclusion marker" >&2
  exit 1
fi
if [[ ! -f "${scenario_repo}/index_editor.html" || ! -f "${scenario_repo}/index_editor_preview.html" ]]; then
  echo "YAP Pages editor exclusion must not delete source editor entries" >&2
  exit 1
fi

node - "${presentation_pages}" "${pages_dir}" <<'NODE'
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const assert = require('assert/strict');

function inventory(root, rel = '') {
  const result = new Map();
  for (const entry of fs.readdirSync(path.join(root, rel), { withFileTypes: true })) {
    const next = rel ? `${rel}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      for (const pair of inventory(root, next)) result.set(...pair);
    } else if (entry.isFile()) {
      result.set(next, crypto.createHash('sha256').update(fs.readFileSync(path.join(root, next))).digest('hex'));
    }
  }
  return result;
}

const included = inventory(process.argv[2]);
const excluded = inventory(process.argv[3]);
assert.deepEqual([...included.keys()].filter((file) => !excluded.has(file)).sort(), ['index_editor.html', 'index_editor_preview.html']);
assert.deepEqual([...excluded.keys()].filter((file) => !included.has(file)).sort(), ['.press-pages-no-editor']);
assert.deepEqual(
  [...included.keys()].filter((file) => excluded.has(file) && included.get(file) !== excluded.get(file)),
  ['assets/press-runtime-manifest.json']
);
NODE

first_excluded="${tmp_dir}/first-excluded"
cp -R "${pages_dir}" "${first_excluded}"
(
  cd "${scenario_repo}"
  bash scripts/build-pages-artifact.sh >/dev/null
)
if ! diff -qr "${first_excluded}" "${pages_dir}" >/dev/null; then
  echo "YAP Pages editor exclusion must be deterministic" >&2
  exit 1
fi

node - "${scenario_repo}/assets/press-runtime-manifest.json" "${pages_dir}/assets/press-runtime-manifest.json" "${pages_dir}" <<'NODE'
const fs = require('fs');
const path = require('path');
const assert = require('assert/strict');

const source = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const pages = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const pagesRoot = process.argv[4];
const omitted = new Set(['index_editor.html', 'index_editor_preview.html']);
const expectedEntries = source.entries.filter((entry) => !omitted.has(entry.path));
const expectedEdges = source.graph.edges.filter((edge) => !omitted.has(edge.from));
assert.deepEqual(
  source.entries.filter((entry) => !pages.entries.some((candidate) => candidate.path === entry.path)).map((entry) => entry.path).sort(),
  [...omitted].sort()
);
assert.equal(source.graph.edges.some((edge) => omitted.has(edge.to) && !omitted.has(edge.from)), false);
assert.deepEqual(pages.entries, expectedEntries);
assert.deepEqual(pages.graph.edges, expectedEdges);
assert.equal(pages.graph.edgeCount, expectedEdges.length);
for (const entry of pages.entries) {
  assert.equal(fs.statSync(path.join(pagesRoot, entry.path)).isFile(), true, entry.path);
}
NODE

node --input-type=module - "${repo_root}/scripts/pages-editor-exclusion.mjs" "${scenario_repo}/assets/press-runtime-manifest.json" <<'NODE'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

const { projectPagesRuntimeManifestWithoutEditor } = await import(pathToFileURL(process.argv[2]).href);
const manifest = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
const staleCount = structuredClone(manifest);
staleCount.graph.edgeCount += 1;
assert.throws(() => projectPagesRuntimeManifestWithoutEditor(staleCount), /edgeCount/);
const incoming = structuredClone(manifest);
incoming.graph.edges.push({ from: 'index.html', to: 'index_editor.html' });
incoming.graph.edgeCount += 1;
assert.throws(() => projectPagesRuntimeManifestWithoutEditor(incoming), /incoming editor edge/);
NODE

assert_policy_rejected() {
  local description="$1"
  if node "${repo_root}/scripts/pages-editor-exclusion.mjs" \
    --source-root "${scenario_repo}" \
    --pages-root "${first_excluded}" >/dev/null 2>&1; then
    echo "YAP Pages editor exclusion must reject ${description}" >&2
    exit 1
  fi
}

printf 'features:\n  editorEntry:\n    enabled: true\n' > "${scenario_repo}/site.yaml"
assert_policy_rejected "a truthy editorEntry flag"
printf 'features:\n  search:\n    enabled: false\n' > "${scenario_repo}/site.yaml"
assert_policy_rejected "a missing editorEntry flag"
printf 'features:\n  editorEntry\n    enabled: false\n' > "${scenario_repo}/site.yaml"
assert_policy_rejected "malformed site.yaml feature syntax"
printf 'features:\n  editorEntry:\n    enabled: false\n    enabled: true\n' > "${scenario_repo}/site.yaml"
assert_policy_rejected "ambiguous duplicate editorEntry flags"
printf 'features:\n  editorEntry:\n    enabled: false\n' > "${scenario_repo}/site.yaml"

(
  cd "${scenario_repo}"
  git rm -q --cached .press-pages-no-editor
  rm .press-pages-no-editor
  ln -s site.yaml .press-pages-no-editor
  git add .press-pages-no-editor
)
assert_policy_rejected "a symlink marker"
(
  cd "${scenario_repo}"
  git rm -q --cached .press-pages-no-editor
  rm .press-pages-no-editor
  mkdir .press-pages-no-editor
)
assert_policy_rejected "a nonregular marker"
rm -rf "${scenario_repo}/.press-pages-no-editor"
printf '' > "${scenario_repo}/.press-pages-no-editor"
assert_policy_rejected "an untracked marker"

rm -f "${scenario_repo}/.press-pages-no-editor"
rm -rf "${scenario_repo}/dist/pages"
redirect_target="${tmp_dir}/redirect-target"
mkdir -p "${redirect_target}"
printf 'keep\n' > "${redirect_target}/sentinel.txt"
ln -s "${redirect_target}" "${scenario_repo}/dist/pages"
if (
  cd "${scenario_repo}"
  bash scripts/build-pages-artifact.sh >/dev/null 2>&1
); then
  echo "YAP Pages builder must reject a symlinked output directory" >&2
  exit 1
fi
if [[ ! -f "${redirect_target}/sentinel.txt" ]]; then
  echo "YAP Pages builder must not delete files behind an output symlink" >&2
  exit 1
fi

echo "ok - YAP Pages artifact"
