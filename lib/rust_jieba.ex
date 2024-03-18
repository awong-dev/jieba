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
  Creates an initializes new Jieba instance.
  """
  def new(), do: :erlang.nif_error(:nif_not_loaded)
  def empty(), do: :erlang.nif_error(:nif_not_loaded)
  def with_dict(_dict_path), do: :erlang.nif_error(:nif_not_loaded)

  #TODO: add clone()

  def load_dict(_jieba, _dict_path), do: :erlang.nif_error(:nif_not_loaded)
  def suggest_freq(_jieba, _segment), do: :erlang.nif_error(:nif_not_loaded)
  def add_word(_jieba, _word, _freq, _tag), do: :erlang.nif_error(:nif_not_loaded)

  def cut(_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)
  def cut_all(_jieba, _sentence), do: :erlang.nif_error(:nif_not_loaded)
  def cut_for_search(_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  def tokenize(_jieba, _sentence, _mode, _hmm), do: :erlang.nif_error(:nif_not_loaded)
  def tag(_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)
end

