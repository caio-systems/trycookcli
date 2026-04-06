# Releasing

This document is the **only** supported pipeline for publishing TryCook CLI binaries to `caio-systems/trycookcli`.

> **Hard rule:** never push the private monorepo `trycookcli/` subtree to this repo. Releases ship binaries via GitHub Releases. The repo itself stays thin.

## Where the source lives

- **Source of truth:** private monorepo, subdirectory `trycookcli/`
- **Public repo:** `caio-systems/trycookcli` — install scripts, README, license, releases only
- **Distribution:** GitHub Releases on the public repo

## Release pipeline

### 1. Build binaries from the private monorepo

From the monorepo root:

```bash
cd trycookcli
bun install
bun run build           # produces dist/ binaries
```

Build the four supported targets:

- `trycook-darwin-arm64`
- `trycook-darwin-x64`
- `trycook-linux-arm64`
- `trycook-linux-x64`

### 2. Generate `checksums.txt`

```bash
cd dist
shasum -a 256 trycook-darwin-arm64 trycook-darwin-x64 trycook-linux-arm64 trycook-linux-x64 > checksums.txt
```

### 3. Tag and publish a release on the public repo

Use the canonical tag format `trycookcli-vX.Y.Z` going forward (older releases used both `vX.Y.Z` and `trycookcli-vX.Y.Z` — both work, but new releases should standardize on the prefixed form).

```bash
gh release create trycookcli-vX.Y.Z \
  --repo caio-systems/trycookcli \
  --title "trycookcli vX.Y.Z" \
  --notes "Release notes here." \
  ./dist/trycook-darwin-arm64 \
  ./dist/trycook-darwin-x64 \
  ./dist/trycook-linux-arm64 \
  ./dist/trycook-linux-x64 \
  ./dist/checksums.txt
```

Each release ships exactly **5 assets** to keep `install.sh` deterministic.

### 4. Verify the release

```bash
gh release view trycookcli-vX.Y.Z --repo caio-systems/trycookcli
curl -fsSL https://trycook.ai/install.sh | bash
```

The install script reads from the latest release of this repo, so a fresh install on a clean machine is the canonical smoke test.

## What you must NOT do

- ❌ `git subtree push` from the monorepo to this repo
- ❌ `git push` source files, build outputs, lockfiles, or tests
- ❌ Add a GitHub Action that mirrors monorepo commits
- ❌ Bypass the `main` ruleset with a force-push
- ❌ Create releases without `checksums.txt`

## What you can do without a release

Direct edits via PR are allowed for the public files only:

- `README.md`
- `install.sh`
- `LICENSE`
- `CONTRIBUTING.md`
- `RELEASING.md`

Anything else: route the change through the private monorepo and ship it as a release.
