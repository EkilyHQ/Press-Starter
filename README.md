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

Do not switch the YAP site to **GitHub Actions** unless you add your own Pages
deployment workflow. The template intentionally publishes directly from the
repository root so the generated site works with GitHub's default branch Pages
mode.

## Publishing

YAP includes `connect.baseUrl` in `site.yaml`, so the Press editor uses Ekily
Connect for GitHub App-backed publishing by default. Authors sign in with
GitHub from the editor and do not need to create a fine-grained Personal Access
Token. If the GitHub App is not installed on the repository, install it first or
remove `connect.baseUrl` to use the editor's advanced PAT fallback.

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
