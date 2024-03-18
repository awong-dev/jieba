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
  def cut(_jieba, _text), do: :erlang.nif_error(:nif_not_loaded)
  def load_dict(_jieba, _dict_path), do: :erlang.nif_error(:nif_not_loaded)
end

