# Jieba

![Build](https://github.com/awong-dev/jieba-rs/actions/workflows/elixir.yml/badge.svg)
![semver](https://img.shields.io/badge/semver-0.3.0-blue)

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
    {:jieba, "~> 0.3.0"}
  ]
end
```

<a name="0.2.0-and-earlier">
## Versions prior to 0.2.0
</a>
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
