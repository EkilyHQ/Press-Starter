# Press Starter

This is the minimal GitHub template for a Press site.

Use this repository through GitHub's **Use this template** button to create a new site. It includes the Press runtime, editor, built-in `native` theme, Theme Manager, `assets/themes/packs.json`, `assets/themes/catalog.json`, and minimal empty content files. It does not include the Press official documentation corpus or regression posts.

## Start a Site

1. Use this repository as a template.
2. Edit `site.yaml` and set `siteTitle`, `siteDescription`, and `repo.owner` / `repo.name`.
3. Add posts and tabs through `index_editor.html`.
4. Keep GitHub Pages set to **Deploy from a branch**, with `main` and `/`.
5. Push changes to `main`; GitHub Pages publishes the site from the repository root.
6. Open the published site and editor from GitHub Pages.

## Included

- `site.yaml`
- `wwwroot/index.yaml`
- `wwwroot/tabs.yaml`
- Press runtime files from the system release package
- `.nojekyll` for GitHub Pages branch publishing

## GitHub Pages

Press Starter is a no-build static site, so GitHub Pages should use **Deploy from
a branch** with branch `main` and folder `/`. New repositories created from this
template may already have that source selected. If Pages is disabled or points
somewhere else, set it in **Settings -> Pages -> Build and deployment**.

Do not switch the starter site to **GitHub Actions** unless you add your own
Pages deployment workflow. The template intentionally publishes directly from
the repository root so the generated site works with GitHub's default branch
Pages mode.

## Theme Defaults

`themePack` starts as `native`. Install other official themes from Theme Manager after creating the site.

## Runtime Sync

This template is rebuilt from Press system release packages. The sync workflow can be triggered by:

- `repository_dispatch` from `EkilyHQ/Press` after a system release is published.
- Manual `workflow_dispatch`, optionally with a release tag.
- A scheduled catch-up run.

The workflow downloads the latest `press-system-vX.Y.Z.zip`, verifies its size and SHA-256 when available, overlays the system-owned runtime files, and regenerates a native-only `assets/themes/packs.json`. Starter-owned files such as `.nojekyll`, `site.yaml`, `wwwroot`, `README.md`, and repository metadata are preserved.

For private Press repositories, configure `PRESS_RELEASE_TOKEN` in this repository so the workflow can read Press releases. For event-driven sync from Press, configure `STARTER_SYNC_TOKEN` in the Press repository with permission to dispatch workflows in this repository.
