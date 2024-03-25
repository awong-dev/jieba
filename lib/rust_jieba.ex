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

  This module directly mostly projects the Rust API into Elixir with an
  object-oriented imperative API.
  """

  use Rustler,
    otp_app: :jieba, # must match the name of the project in `mix.exs`
    crate: :rustler_jieba # must match the name of the crate in `native/jieba/Cargo.toml`

  @enforce_keys [:use_default, :dict_paths, :native]
  defstruct [:use_default, :dict_paths, :native]

  @type t :: %__MODULE__{
        use_default: boolean(),
        dict_paths: list(String.t()),
        native: reference(),
      }

  @doc """
  Creates an initializes new RustJieba instance with default dictionary.

  Returns RustJieba instance.

  ## Examples

      iex> _jieba = RustJieba.new()
  """
  def new(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Creates an initializes new RustJieba instance with an empty dictionary.

  Returns RustJieba instance.

  ## Examples

      iex> _jieba = RustJieba.empty()
  """
  def empty(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Creates an initializes new RustJieba instance with the dictionary given in `_dict_path`.

  Returns RustJieba instance.

  ## Examples

      iex> _jieba = RustJieba.with_dict("example_userdict.txt")
  """
  def with_dict(_dict_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Makes another RustJieba with the same dictionary state.

  Returns RustJieba instance.

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.clone(jieba)
  """
  def clone(_rust_jieba), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Merges the keywords in `_dict_path` to the current RustJieba instance.

  Returns `(:ok, rust_jieba)`

  ## Examples

      iex> jieba = RustJieba.new()
      iex> x = RustJieba.load_dict(jieba, "example_userdict.txt")
      iex> x != jieba
  """
  def load_dict(_rust_jieba, _dict_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Given a new segment, this attempts to guess the frequency of the segment.
  It is used by `add_word()` if no `freq` is given.

  Returns 483 (number with word frequency)

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.suggest_freq(jieba, "也")
      307852
      iex> RustJieba.suggest_freq(jieba, "是")
      796991
      iex> RustJieba.suggest_freq(jieba, "也是")
      4083
      iex> RustJieba.suggest_freq(jieba, "佢哋")
      1
  """
  def suggest_freq(_rust_jieba, _segment), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Adds a segment to the dictionary with an optional frequency or tag.

  If no frequency is given, `suggest_freq()` is used to guess the frequency.
  This can be used to prevent oversegmentation.

  Returns 2434 (frequency of the added segment)

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.cut(jieba, "「台中」正确应该不会被切开", true)
      ["「", "台", "中", "」", "正确", "应该", "不会", "被", "切开"]
      iex> RustJieba.add_word(jieba, "台中", nil, nil)
      69
      iex> RustJieba.cut(jieba, "「台中」正确应该不会被切开", true)
      ["「", "台中", "」", "正确", "应该", "不会", "被", "切开"]
  """
  def add_word(_rust_jieba, _word, _freq, _tag), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence and breaks it into a vector of segments.

  Returns `["李小福", "是"]`

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.cut(jieba, "李小福是创新办任也是云计算方面的家", true)
      ["李小福", "是", "创新", "办任", "也", "是", "云", "计算",
       "方面", "的", "家"]
  """
  def cut(_rust_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence and breaks it into a vector containing segemnts using
  the most aggressive segmentation possible given the input dictionary.
  It is likely that it will produce an oversegmented results. There may
  also be multiple tokens returned any sequence of characters. For example,
  `"创新"` will return `["创", "创新", "新"]`.

  This means that joining all elements of the result vector will not
  necessarily result in a string with the same meaning as the input.

  Returns `["李", "小", "福", "是", "创", "创新", ...]`

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.cut_all(jieba, "李小福是创新办任也是云计算方面的家")
      ["李", "小", "福", "是", "创", "创新", "新", "办", "任", "也", "是", "云", "计", "计算", "算", "方", "方面", "面", "的", "家"]
  """
  def cut_all(_rust_jieba, _sentence), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence and breaks it into a vector containing segments tuned for
  search engine keyword matching.  This tends to produce shorted segments
  that are more likely to produce a keyword match. For example,
  `"中国科学院"` will produce `["中国", "科学", "学院", "科学院", "中国科学院"]`
  whereas with `cut()`, it will just produce `["中国科学院"]`
  It is possible (and likely) that phrases will be repeated.

  Returns `["中国", "科学", "学院", "科学院", "中国科学院"]`

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.cut(jieba, "小明硕士毕业于中国科学院计算所，后在日本京都大学深造", true)
      ["小明", "硕士", "毕业", "于", "中国科学院", "计算所", "，", "后", "在", "日本京都大学", "深造"]
      iex> RustJieba.cut_for_search(jieba, "小明硕士毕业于中国科学院计算所，后在日本京都大学深造", true)
      ["小明", "硕士", "毕业", "于", "中国", "科学", "学院", "科学院", "中国科学院", "计算",
       "计算所", "，", "后", "在", "日本", "京都", "大学", "日本京都大学", "深造"]
  """
  def cut_for_search(_rust_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence, performs `cut()`, and then produces a vector of `Token` structs that
  indicate where in the sentence the segment comes from.

  The tokenization mode can be one of :default or :search.

  Returns `[
              %{start: 0, __struct__: RustJieba.Token, word: "李小福"},
              %{start: 3, __struct__: RustJieba.Token, word: "是"},["是"]`
           ]`

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.tokenize(jieba, "李小福是创新办任也是云计算方面的家", :default, true)
      [
          %{start: 0, __struct__: RustJieba.Token, word: "李小福"},
          %{start: 3, __struct__: RustJieba.Token, word: "是"},
          %{start: 4, __struct__: RustJieba.Token, word: "创新"},
          %{start: 6, __struct__: RustJieba.Token, word: "办任"},
          %{start: 8, __struct__: RustJieba.Token, word: "也"},
          %{start: 9, __struct__: RustJieba.Token, word: "是"},
          %{start: 10, __struct__: RustJieba.Token, word: "云"},
          %{start: 11, __struct__: RustJieba.Token, word: "计算"},
          %{start: 13, __struct__: RustJieba.Token, word: "方面"},
          %{start: 15, __struct__: RustJieba.Token, word: "的"},
          %{start: 16, __struct__: RustJieba.Token, word: "家"}
      ]
  """
  def tokenize(_rust_jieba, _sentence, _mode, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence, performs `cut()`, and then produces a vector of `Tag` structs that
  label each segment with a tag -- usually the part of speech.

  Returns `[
              %RustJieba.Tag{word: "李小福", tag: "x"},
              %RustJieba.Tag{word: "是", tag: "v"},
              ...
           ]`

  ## Examples

      iex> jieba = RustJieba.new()
      iex> RustJieba.tag(jieba, "李小福是创新办任也是云计算方面的家", true)
      [
              %RustJieba.Tag{word: "李小福", tag: "x"},
              %RustJieba.Tag{word: "是", tag: "v"},
              %RustJieba.Tag{word: "创新", tag: "v"},
              %RustJieba.Tag{word: "办任", tag: "x"},
              %RustJieba.Tag{word: "也", tag: "d"},
              %RustJieba.Tag{word: "是", tag: "v"},
              %RustJieba.Tag{word: "云", tag: "ns"},
              %RustJieba.Tag{word: "计算", tag: "v"},
              %RustJieba.Tag{word: "方面", tag: "n"},
              %RustJieba.Tag{word: "的", tag: "uj"},
              %RustJieba.Tag{word: "家", tag: "q"}
            ]
  """
  def tag(_rust_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)
end
