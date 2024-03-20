defmodule RustJieba.Keyword do
  defstruct keyword: "",
            weight: 0.0
end

defmodule RustJieba.Tag do
  defstruct word: "",
            tag: ""
end

defmodule RustJieba.Token do
  defstruct word: "",
            start: 0,
            end: 0
end

defmodule RustJieba do
  @moduledoc """
  Proxy for the [jieba-rs](https://github.com/messense/jieba-rs) project,
  a Rust implementation of the Python [Jieba](https://github.com/fxsjy/jieba)
  Chinese Word Segmentation library.

  This module attempts to directly project the Rust API into Elixir with an
  object-oriented imperative API. 

  Look at the the Jieba module for an API that is more Elixir idiomatic. 
  """

  use Rustler,
    otp_app: :jieba, # must match the name of the project in `mix.exs`
    crate: :rustler_jieba # must match the name of the crate in `native/jieba/Cargo.toml`

  @doc """
  Creates an initializes new RustJieba instance with default dictionary.

  Returns RustJieba instance.

  ## Examples

      iex> RustJieba.new()
  """
  def new(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Creates an initializes new RustJieba instance with an empty dictionary.

  Returns RustJieba instance.

  ## Examples

      iex> RustJieba.empty()
  """
  def empty(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Creates an initializes new RustJieba instance with the dictionary given in `_dict_path`.

  Returns RustJieba instance.

  ## Examples

      iex> RustJieba.with_dict("example_userdict.txt")
  """
  def with_dict(_dict_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Makes another RustJieba with the same dictionary state.

  Returns RustJieba instance.

  ## Examples

      iex> j = RustJieba.new()
      iex> RustJieba.clone(j)
  """
  def clone(_rust_jieba), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Merges the keywords in `_dict_path` to the current RustJieba instance.

  Returns `(:ok, rust_jieba)`

  ## Examples

      iex> j = RustJieba.new()
      iex> x = RustJieba.load_dict(j, "example_userdict.txt")
      iex> x == j
      true
  """
  def load_dict(_rust_jieba, _dict_path), do: :erlang.nif_error(:nif_not_loaded)
  def suggest_freq(_rust_jieba, _segment), do: :erlang.nif_error(:nif_not_loaded)
  def add_word(_rust_jieba, _word, _freq, _tag), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence and breaks it into a vector of segments.

  Returns ["李小福", "是"]

  ## Examples

      iex> j = RustJieba.new()
      iex> RustJieba.cut(j, "李小福是创新办任也是云计算方面的家", true)
      ["李小福", "是", "创新", "办任", "也", "是", "云", "计算",
       "方面", "的", "家"]
  """
  def cut(_rust_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)
  def cut_all(_rust_jieba, _sentence), do: :erlang.nif_error(:nif_not_loaded)
  def cut_for_search(_rust_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  def tokenize(_rust_jieba, _sentence, _mode, _hmm), do: :erlang.nif_error(:nif_not_loaded)
  def tag(_rust_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)
end
