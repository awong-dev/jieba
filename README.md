# Jieba

![Build](https://github.com/awong-dev/jieba/actions/workflows/elixir.yml/badge.svg)


A Ruslter bridge to [jieba-rs](https://github.com/messense/jieba-rs), the Rust
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
    {:jieba, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/jieba>.

