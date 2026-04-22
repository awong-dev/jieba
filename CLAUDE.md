# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An Elixir wrapper around [jieba-rs](https://github.com/messense/jieba-rs) (Rust implementation of the Jieba Chinese segmenter), exposed via a Rustler NIF and shipped to users as precompiled binaries through `RustlerPrecompiled`.

## Common commands

```bash
mix deps.get                               # fetch deps
mix compile --warnings-as-errors           # build (CI uses this exact flag)
mix test                                   # run all tests
mix test test/jieba_test.exs:LINE          # run a single test (or doctest) by line
mix format --check-formatted               # CI gate
mix deps.unlock --check-unused             # CI gate
mix rust_lint                              # rustfmt + clippy in check mode
mix rust_lint --fix                        # rustfmt + clippy with fixes
```

By default the NIF is loaded from a precompiled artifact downloaded from a GitHub release matching `mix.exs`'s `@version`. To force a local Rust build instead, set `JIEBA_FORCE_RUSTLER_BUILD=1` (CI sets this so it actually compiles `native/`).

The Elixir test file (`test/jieba_test.exs`) is a one-liner — `doctest Jieba` — so the real test suite lives in the `## Examples` blocks of every public function in `lib/jieba.ex`. Adding/changing a public function means adding/changing its doctest.

## Architecture

Two layers, one process:

- **Elixir** (`lib/jieba.ex`): defines `%Jieba{}` plus the `Jieba.Token`, `Jieba.Tag`, `Jieba.Keyword` structs, and the public API. Most functions are `:erlang.nif_error(:nif_not_loaded)` stubs replaced by the NIF on load. Convenience wrappers (`new/1`, `new!/1`, `load_dict!/2`, `*_extract_tags!/_`) live here.
- **Rust NIF** (`native/rustler_jieba/src/lib.rs`): registered as `Elixir.Jieba` via `rustler::init!`. Each `#[rustler::nif]` corresponds to a stub in `lib/jieba.ex` of the same name. The NIF crate name `rustler_jieba` is referenced from `lib/jieba.ex` (`crate: :rustler_jieba`) and from `mix rust_lint` — keep them in sync if renaming.

The Rust side wraps the underlying `jieba_rs::Jieba` in a `Mutex<Jieba>` inside a `JiebaResource`, handed back to Elixir as a `ResourceArc`. This is what the `native:` field on `%Jieba{}` holds. Two important consequences flow from this design and are intentional:

1. **`load_dict/2` and `add_word/4` mutate native state in place.** They return a new `%Jieba{}` with updated metadata (`dict_paths`), but both the original and returned struct share the same `ResourceArc`, so a `cut` on the "old" struct will see the new dictionary. Use `clone/1` if you need an independent copy. The doctests in `lib/jieba.ex` deliberately demonstrate this entanglement — don't "fix" them.
2. **`tfidf_extract_tags` and `textrank_extract_tags` rebuild the extractor on every call.** This is slow when a custom dict or stop-word list is supplied. The cause is upstream: `jieba-rs`'s `TFIDF`/`TextRank` borrow the `Jieba` instance at construction time, which is incompatible with our `Mutex`-guarded `ResourceArc`. See https://github.com/messense/jieba-rs/issues/99. Don't try to cache them in the resource without solving that lifetime issue first.

There is also a deprecated single-arity `Jieba.cut/1` that uses a `lazy_static` global `Jieba` on the Rust side (see `STATIC_JIEBA` and `native_static_cut`). It's not thread-safe per `jieba_rs`'s contract and exists only for backward compatibility with the pre-0.3 `mjason/jieba_ex` API; it will be removed in 1.0.

## CI workflows

Three separate workflows in `.github/workflows/` with different trigger scopes — important when editing them:

- **`ci.yml`** — runs `mix format --check-formatted`, `mix deps.unlock --check-unused`, `mix compile --warnings-as-errors`, and `mix test` on every PR and on push to `main`. Pinned to a single matrix entry (OTP 26.2.3 / Elixir 1.16.2); the matrix structure is there to make widening compat easy, but doing so is a deliberate decision.
- **`rust-ci.yml`** — runs `cargo fmt --check` and `cargo clippy -- -Dwarnings` only when files under `native/**` change. Two consequences: (1) Rust-only changes that don't touch `native/` (e.g. editing this workflow itself) won't get linted; (2) CI's clippy is stricter than `mix rust_lint`, which doesn't pass `-Dwarnings` — local lint passing isn't sufficient. Its cache `path:` block still references `native/ex_tokenizers/target/` (leftover from the `elixir-nx/tokenizers` template it was forked from); the cache key won't hit anything useful for this repo, so don't rely on Rust build caching in CI.
- **`release.yml`** — see release flow below.

## Versioning and release flow

- `@version` in `mix.exs` is the source of truth. `.github/workflows/release.yml` parses it with `sed -n 's/^  @version "\(.*\)"/\1/p'` — preserve the two-space indent and double-quoted form.
- Pushing a tag triggers `release.yml`, which builds the NIF for ~10 targets via `philss/rustler-precompiled-action` and attaches the artifacts to the GitHub Release. `RustlerPrecompiled` in `lib/jieba.ex` then downloads them from `…/releases/download/v<version>/`. A version bump without a tagged release will leave end users unable to fetch the NIF.
- `aarch64-unknown-linux-musl` is added to the precompile target list explicitly in `lib/jieba.ex` (it isn't in `RustlerPrecompiled`'s defaults). New targets need to be added in *both* `release.yml`'s matrix and the `targets:` list in `lib/jieba.ex`.
