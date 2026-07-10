#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)"
cd "${repo_root}"

if [[ -L dist || ( -e dist && ! -d dist ) ]]; then
  echo "YAP Pages output parent must be a regular directory: dist" >&2
  exit 1
fi
mkdir -p dist
if [[ -L dist/pages || ( -e dist/pages && ! -d dist/pages ) ]]; then
  echo "YAP Pages output must not be a symlink or non-directory: dist/pages" >&2
  exit 1
fi

output_dir="${repo_root}/dist/pages"
rm -rf "${output_dir}"
mkdir -p "${output_dir}"

while IFS= read -r -d '' file; do
  if [[ ( "${file}" == ".press-pages-no-editor" || "${file}" == "site.yaml" ) && ( -L "${file}" || ! -f "${file}" ) ]]; then
    echo "YAP Pages policy file must be a regular file: ${file}" >&2
    exit 1
  fi
  mkdir -p "${output_dir}/$(dirname "${file}")"
  cp "${file}" "${output_dir}/${file}"
done < <(git ls-files -z -- .nojekyll .press-pages-no-editor index.html index_editor.html index_editor_preview.html site.yaml assets wwwroot)

node scripts/pages-editor-exclusion.mjs --source-root "${repo_root}" --pages-root "${output_dir}"
