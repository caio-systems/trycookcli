# Contributing

Thanks for the interest — please read this first.

## This is not the source repository

`caio-systems/trycookcli` is a **release/install repo only**. The TryCook CLI source code lives in a private monorepo. This repository exists so users can:

- Install the CLI (`curl -fsSL https://trycook.ai/install.sh | sh`, `npm install -g trycookcli`)
- Read public documentation
- Download official binaries from [GitHub Releases](https://github.com/caio-systems/trycookcli/releases)

It does **not** track CLI source, build outputs, tests, or internal tooling.

## What we accept here

PRs and issues are welcome for the small set of intentionally public files:

- `README.md`
- `LICENSE`
- `CONTRIBUTING.md` / `RELEASING.md`
- Documentation about installation and usage

## What we do not accept here

- CLI source code, build artifacts, lockfiles, or tests
- Anything that resembles a sync or mirror of the private monorepo `trycookcli/` subtree
- PRs that add new top-level directories without prior discussion
- Force-pushes, history rewrites, or merges that bypass review

If your change involves CLI behavior, open an issue describing the use case. The fix lands upstream in the private repo and ships through a GitHub Release here.

## How changes land

`main` is protected. Every change must go through a pull request:

1. Branch from `main`
2. Make a focused change to one of the public files listed above
3. Open a PR — keep it small and reviewable
4. Merge requires **1 approving review**, **linear history**, and **no force-pushes**
5. Stale approvals are dismissed when new commits are pushed

## Reporting bugs

Open an issue with reproduction steps and the CLI version (`trycook --version`). For security issues, please email instead of filing a public issue.

## Releases

See [`RELEASING.md`](./RELEASING.md) for how official binaries are produced and published.
