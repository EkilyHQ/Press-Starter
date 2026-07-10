# YAP

YAP is the tiny GitHub template for a Press site. The name means
**yet-another press**, with a little yap yap yap energy baked in.

Use this repository through GitHub's **Use this template** button to create a
new site. It includes the Press runtime, editor, built-in `native` theme, Theme
Manager, `assets/themes/packs.json`, and a small starter article plus a small
starter page in every bundled Press language. It does not include the Press
official documentation corpus, regression posts, or a bundled official theme
catalog.

## Start a Site

1. Use this repository as a template.
2. Edit `site.yaml` and set `siteTitle`, `siteDescription`, and `repo.owner` / `repo.name`.
3. Add posts and tabs through `index_editor.html`.
4. Keep GitHub Pages set to **Deploy from a branch**, with `main` and `/`.
5. Install the Ekily Connect GitHub App on the new repository so the editor can publish through GitHub sign-in.
6. Push changes to `main`; GitHub Pages publishes the site from the repository root.
7. Open the published site and editor from GitHub Pages.

## Included

- `site.yaml`
- `wwwroot/index.yaml`
- `wwwroot/tabs.yaml`
- Sample article and About page Markdown files
- Press runtime files from the system release package
- `.nojekyll` for GitHub Pages branch publishing

## GitHub Pages

YAP is a no-build static site, so GitHub Pages should use **Deploy from a
branch** with branch `main` and folder `/`. New repositories created from this
template may already have that source selected. If Pages is disabled or points
somewhere else, set it in **Settings -> Pages -> Build and deployment**.

The template also carries a repository-owned GitHub Actions Pages workflow for
sites that need an artifact-only deployment policy. To keep the browser editor
out of that published artifact, switch Pages to **GitHub Actions**, commit a
regular `.press-pages-no-editor` file, and set
`features.editorEntry.enabled: false` as a block mapping in `site.yaml`. Both
signals are required, and malformed, inline, or ambiguous opt-in mappings fail
closed. The feature flag alone only hides public links. The artifact removes
only `index_editor.html` and `index_editor_preview.html`; source files and later
Press runtime syncs retain both files, so the choice is reversible. Sites made
from older YAP snapshots must adopt this builder, policy script, and workflow
manually because runtime sync preserves YAP-owned scripts and workflows.

## Publishing

The Press editor uses Ekily Connect for GitHub App-backed publishing by default.
Authors sign in with GitHub from the editor and do not need to create a
fine-grained Personal Access Token. The selected Connect URL is stored in the
browser's Repository settings, not in `site.yaml`. If the GitHub App is not
installed on the repository, install it first or switch the editor's Repository
publish method to the Personal token fallback.

## Theme Defaults

`themePack` starts as `native`. Install other official themes from Theme Manager after creating the site.

## Runtime Sync

This template is rebuilt from Press system release packages. The sync workflow
can be triggered by:

- `repository_dispatch` from `EkilyHQ/Press` after a system release is published.
- Manual `workflow_dispatch`, optionally with a release tag.
- A scheduled catch-up run.

The workflow downloads the latest `press-system-vX.Y.Z.zip`, verifies its size
and SHA-256 when available, overlays the system-owned runtime files,
regenerates a native-only `assets/themes/packs.json`, and commits the result
directly to `main`. YAP-owned files such as `.nojekyll`, `site.yaml`,
`wwwroot`, `README.md`, and repository metadata are preserved. Because this
repository publishes from `main` and `/`, each successful runtime sync also
starts a GitHub Pages publish from the updated template root.

For private Press repositories, configure `PRESS_RELEASE_TOKEN` in this
repository so the workflow can read Press releases. For event-driven sync from
Press, configure `STARTER_SYNC_TOKEN` in the Press repository with permission to
dispatch workflows in this repository; keep that secret name because it is part
of the Press release workflow contract.
