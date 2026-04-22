# Jieba

![Build](https://github.com/awong-dev/jieba/actions/workflows/ci.yml/badge.svg)
![semver](https://img.shields.io/badge/semver-0.3.0-blue)
![Hex.pm](https://img.shields.io/hexpm/v/jieba)

([Note for versions 0.2.0 and earlier](#0.2.0-and-earlier))

A Rustler bridge to [jieba-rs](https://github.com/messense/jieba-rs), the Rust
Jieba implementation.

This provides the ability to use the Jieba-rs segmenter in Elixir for segmenting
Chinese text.

The API is mostly a direct mapping of the Rust API. The constructors have all
been combined under one `new/2` API that allows the code to feel less imperative.

The KeywordExtract functionality for both `TFIDF` and `TextRank` are also provided
but due to the design of `jieba-rs` that restricts to project those two Rust
structs into the Beam while respecting the Rust lifetime rules and ensuring mutual
exclusion across threads, they are exported as single use functions that
construct/tear-down the `TFIDF` and `TextRank` instances per call.  This is
possibly slow but fixing it to be fast would require modifying the `jieba-rs`
API so that neither `TFIDF` or `TextRank` held a reference to the underlying
`jieba` instance on construction and instead took the wanted instance on the
`extract_tags()` call.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jieba` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jieba, "~> 0.3.1"}
  ]
end
```

## Development

### CI workflows

Three GitHub Actions workflows live under `.github/workflows/`:

- **`ci.yml`** is the main Elixir gate. It runs on every pull request and on pushes to `main`. It installs Elixir/OTP, pulls deps, checks formatting (`mix format --check-formatted`), verifies there are no unused dependencies (`mix deps.unlock --check-unused`), compiles with `--warnings-as-errors`, and runs the test suite. It sets `JIEBA_FORCE_RUSTLER_BUILD=1` so the NIF is compiled from source rather than downloaded, which means a broken Rust change is caught here even though this job is primarily about Elixir.
- **`rust-ci.yml`** handles Rust linting — `cargo fmt --check` and `cargo clippy -- -Dwarnings`. It is deliberately scoped: it only runs when files under `native/**` change. A pure-Elixir PR won't trigger it, and edits to the workflow itself won't re-run its own checks.
- **`release.yml`** builds precompiled NIFs. See the Release process section below.

### Branching

The long-lived branch is `main`; feature and fix work merges there through pull requests.

Release preparation happens on dedicated, short-lived branches rather than directly on `main` — for example, `release_0_3_0` produced the `v0.3.0` tag and `rustler_precompiled` produced `v0.3.1`. This keeps experimental packaging churn (target matrices, precompile glue, CI shuffling) off `main` until it works end-to-end. Once a release is cut, the relevant commits are cherry-picked back onto `main` so the history carries forward. A practical consequence: release tags are *not* direct ancestors of `main`, so `git describe main` will not find them. Use `git log --all --decorate` or check tags explicitly when tracing release history.

### Release process

Releases are published through `release.yml`, which produces the precompiled NIFs that end users pick up via `rustler_precompiled`.

The source of truth for the release version is the `@version` attribute in `mix.exs`. The workflow extracts it with a regex over that exact line, so the two-space indent and double-quoted form must be preserved.

To cut a release:

1. On a release-prep branch, bump `@version` in `mix.exs`, update `CHANGELOG.md`, and update any hardcoded version references (e.g., the badge and `{:jieba, "~> X.Y.Z"}` snippet in this README).
2. Push a tag matching the version (e.g., `v0.3.2`). Tags trigger `release.yml` unconditionally; pushes to `main` only trigger it when something under `native/**` changes.
3. `release.yml` then fans out across a matrix of ~10 targets (macOS x86_64/arm64, Linux x86_64/aarch64/arm/riscv64 in gnu and musl variants, and Windows gnu/msvc), using `philss/rustler-precompiled-action` under the hood. Each job uploads its built artifact and — only when the run was triggered by a tag — attaches it to the GitHub Release via `softprops/action-gh-release`.
4. Once the release is populated with artifacts, publish the package to Hex (`mix hex.publish`). The `RustlerPrecompiled` setup in `lib/jieba.ex` points end users at `https://github.com/awong-dev/jieba/releases/download/v<version>/…`, so users installing from Hex will download the matching precompiled binary from the GitHub Release.
5. Cherry-pick the release commits back onto `main` and open a PR.

Adding a new precompile target requires edits in two places: the `matrix.job` list in `release.yml`, and the `targets:` list passed to `RustlerPrecompiled` in `lib/jieba.ex`. Miss one and users on that platform either won't get a binary or will fail checksum verification.

## <a name="0.2.0-and-earlier">Versions prior to 0.2.0</a>
Versions prior to 0.2.0 were written by [mjason](https://github.com/mjason)
([lmj](https://hex.pm/users/lmj) on hex and released from the
[mjason/jieba_ex](https://github.com/mjason/jieba_ex) source tree. It exposed
a single `Jieba.cut(sentence)` method will used a single, unsyncrhonized, static
instance of Jieba on the Rust side loaded with the default dictionary.
The `cut(sentence)` was hardcoded to have `hmm=false`.

In March 2024, this codebase was written to help with the
[Visual Fonts](https://visual-fonts.com/) project, not realizing an existing
codebase was available. This codebase had a more complete exposure of the Rust
API. After talking with `mjason`, it was decided to switch to this codebase and
to increment the version number to signify the API break.

The 0.3.z versions still include `Jieba.cut/1` interface, but have it marked
deprecated. In 1.0.0, this API will be removed in favor of non-global-object
based API.
