# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### Unreleased
  1. Clean-up CI, Readme, and Docs.

## [0.3.0] 2024-03-30

   1. This release comes from an entirely new codebase: [awong-dev/jieba](https://github.com/awong-dev/jieba).
   2. Ownership of `hex.pm` package changed from [lmi](https://hex.pm/users/lmj) to [awong.dev](https://hex.pm/users/awong.dev)

Implementation of `awong-dev/jieba` was spurred by the
[Visual Fonts](https://visual-fonts.com/) project and was code-complete with
`jieba_rs` API exposed in a thread-safe manner (complete with documentation
and tests) before noticing that there was an exisitng `hex.pm` jieba pakcage.

After the name collision was discovered, `ljm` and `awong-dev` decided to
transfer package ownership and release a new version of `jieba` using the
new codebase.

The previous 0.2.0 API was added into the `awong-dev/jieba` implementation
as a deprecated API for the 0.3.0 release and will be removed later.

### Added
  1. Ability to create multiple `Jieba` instances instead of depending on one global one.
  2. APIs exposing all functionality in [messense/jieba_rs](https://github.com/messense/jieba-rs) including
      1. Ability to load custom dictionaries to extend the segmentation
      2. Simple exposure of the [TFIDF](https://docs.rs/jieba-rs/0.6.8/jieba_rs/struct.TFIDF.html) and [TextRank](https://docs.rs/jieba-rs/0.6.8/jieba_rs/struct.TextRank.html) APIs
  3. Doctests for all exposed APIs

### Deprecated
  1. `Jieba.cut/1` is being removed because other APIs are more flexible and provide full thread-safety guarantees.

### Changed
  1. hex.pm jieba packaged ownership transfered from `ljm` to `awong-dev`
  2. Source tree is now at [awong-dev/jieba](https://github.com/awong-dev/jieba)
  3. Documentation written primarily in English


## [0.2.0] and prior - 2021-07-13
Versions 0.2.0 and prior are released from the
[mjason/jieba_ex](https://github.com/mjason/jieba_ex) project and feature a
single, lazily initialized, Rust Jieba instance that can be accessed in
elixir via the `Jieba.cut/1` function. This would return the result of cut in
`Jieba_rs` with the default dictionary and `hmm` turned off.


All concurrent calls from Elixir would have unsynchronized access to the
underlying Rust Jieba instance.

Versions before 0.2.0 contain various build tweaks.
