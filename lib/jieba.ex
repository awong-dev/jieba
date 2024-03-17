defmodule Jieba do
  @moduledoc """
  Wrapper for the [jieba-rs](https://github.com/messense/jieba-rs) project,
  a Rust implementation of the Python [Jieba](https://github.com/fxsjy/jieba)
  Chinese Word Segmentation library.

  ## Examples

      # An empty dictionary segments at every character.
      iex> j = Jieba.new(use_default: false)
      iex> Jieba.cut(j, "呢個係乜嘢呀")
      ["呢", "個", "係", "乜", "嘢", "呀"]

      iex> j = Jieba.new()
      iex> Jieba.cut(j, "呢個係乜嘢呀")
      ["呢", "個", "係", "乜嘢", "呀"]
      iex> Jieba.cut(j, "李小福是创新办任也是云计算方面的家")
      ["李小福", "是", "创新", "办任", "也", "是", "云", "计算",
       "方面", "的", "家"]

      iex> j = Jieba.new(dict_paths: ["example_userdict.txt"])
      iex> Jieba.cut(j, "李小福是创新办任也是云计算方面的家")
      ["李小福", "是", "创新办", "任", "也", "是", "云", "计算",
       "方面", "的", "家"]
  """

  use Rustler,
    otp_app: :jieba, # must match the name of the project in `mix.exs`
    crate: :rustler_jieba # must match the name of the crate in `native/jieba/Cargo.toml`

  @doc """
  Creates an initializes new Jieba instance.
  """
  def new(options \\ [{:dict_paths, []}, {:use_default, true}]) do
    jieba = make(options[:use_default] != false)

    for path <- (options[:dict_paths] || []) do
      load_dict(jieba, path)
    end
    jieba
  end

  def cut(_jieba, _text), do: :erlang.nif_error(:nif_not_loaded)

  defp make(_use_default), do: :erlang.nif_error(:nif_not_loaded)
  def load_dict(_jieba, _dict_path), do: :erlang.nif_error(:nif_not_loaded)

end
