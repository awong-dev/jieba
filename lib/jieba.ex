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

  @enforce_keys [:use_default, :dict_paths, :rust_jieba]
  defstruct [:use_default, :dict_paths, :rust_jieba]

  @doc """
  Creates an initializes new Jieba instance.
  """
  def new(options \\ [{:dict_paths, []}, {:use_default, true}]) do
    use_default = options[:use_default] != false
    rust_jieba = if use_default, do: RustJieba.new(), else: RustJieba.empty()

    for path <- (options[:dict_paths] || []) do
      RustJieba.load_dict(rust_jieba, path)
    end

    %Jieba{use_default: use_default, dict_paths: options[:dict_paths], rust_jieba: rust_jieba}
  end

  @doc """
  Takes `text` and returns an array of the segments.
  """
  def cut(jieba, text) do
    RustJieba.cut(jieba.rust_jieba, text, :true)
  end
end
