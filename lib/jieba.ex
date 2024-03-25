defmodule Jieba.JiebaError do
  defexception [:message]
end

defmodule Jieba.Keyword do
  @moduledoc """
  Corresponds to a Keyword in the jieba-rs API.

  `keyword` is the keyword produced by the jieba-rs TextRank extractor.
  `weight` is the score assigned by the TextRank extractor for the keyword.
  """
  defstruct keyword: "",
            weight: 0.0
end

defmodule Jieba.Tag do
  @moduledoc """
  Corresponds to a Tag in the jieba-rs API.

  `word` is the string for the token
  `tag` is a string with the tag for the token. These are often parts of speech tags.
  """
  defstruct word: "",
            tag: ""
end

defmodule Jieba.Token do
  @moduledoc """
  Corresponds to a Token in the jieba-rs API.

  `word` is the string for the token
  `start` and `end` are the locations in the input sentence of `word`.
  """
  defstruct word: "",
            start: 0,
            end: 0
end

defmodule Jieba do
  @moduledoc """
  Wrapper for the [jieba-rs](https://github.com/messense/jieba-rs) project,
  a Rust implementation of the Python [Jieba](https://github.com/fxsjy/jieba)
  Chinese Word Segmentation library.

  This module directly mostly projects the Rust API into Elixir with an
  object-oriented imperative API with very thin syntactic sugar. Where possible,
  it attempts to preserve functional behavior but this is not possible always,
  especially with the `load_dict/2` inteface.
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
  Creates an initializes new Jieba instance.

  This is a conveniece wrapper that avoids the need to touch the imperative load_dict/2
  API allowing for a more functional calling style.

  Returns {:ok, jieba} or {:error, reason}

  ## Examples

      iex> {:ok, jieba} = Jieba.new(use_default: false)
      iex> Jieba.cut(jieba, "呢個係乜嘢呀")
      ["呢", "個", "係", "乜", "嘢", "呀"]

      iex> {:ok, jieba} = Jieba.new()
      iex> Jieba.cut(jieba, "呢個係乜嘢呀")
      ["呢", "個", "係", "乜嘢", "呀"]
      iex> Jieba.cut(jieba, "李小福是创新办任也是云计算方面的家")
      ["李小福", "是", "创新", "办任", "也", "是", "云", "计算",
       "方面", "的", "家"]

      iex> {:ok, jieba} = Jieba.new(dict_paths: ["test/example_userdict.txt"])
      iex> Jieba.cut(jieba, "李小福是创新办任也是云计算方面的家")
      ["李小福", "是", "创新办", "任", "也", "是", "云", "计算",
       "方面", "的", "家"]

      iex> {:error, :enoent} = Jieba.new(dict_paths: ["NotAFile.nope.nope"])
  """
  def new(options \\ [{:dict_paths, []}, {:use_default, true}]) do
    use_default = options[:use_default] != false

    Enum.reduce(
      options[:dict_paths] || [],
      {:ok, (if use_default, do: native_new(), else: native_empty())},
      fn (path, result) ->
        case result do
          {:ok, jieba} -> load_dict(jieba, path)
          _ -> result
        end
      end)
  end

  @doc """
  Creates an initializes new Jieba instance using new/2.

  Returns Jieba instance.

  Raises Jieba.JiebaError on error.

  ## Examples
      iex> jieba = Jieba.new!(use_default: false)
      iex> Jieba.cut(jieba, "呢個係乜嘢呀")
      ["呢", "個", "係", "乜", "嘢", "呀"]
  """
  def new!(options \\ [{:dict_paths, []}, {:use_default, true}]) do
    case new(options) do
      {:ok, jieba} -> jieba
      {:error, reason} -> raise Jieba.JiebaError, message: to_string(reason)
    end
  end

  # Since the new/3 conveniece wrapper plus default options captures all
  # the functionality this is private. However this is still needed to
  # implement new/3.
  defp native_new(), do: :erlang.nif_error(:nif_not_loaded)

  # Creates an initializes new Jieba instance with an empty dictionary.
  #
  # Returns Jieba instance.
  defp native_empty(), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Makes another Jieba with the same dictionary state.

  Returns Jieba instance.

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.clone(jieba)
  """
  def clone(_jieba), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Merges the entries in `_dict_path` to the current native Jieba instance

  This is an imperative function and will modify the underlying state of the
  Jieba instance.  The function will return a new Jieba that has the
  `Jieba.dict_paths` field updated. However, since both the original
  input object and the returned object will share a native jieba instance,
  they will both be altered even if the `dict_paths` field of the original
  object is left untouched.  The original object should be discarded after
  use.

  If you wish to keep the original Jieba instance, use `clone/1` to make
  a copy that can be preserved.

  Returns `(:ok, rust_jieba)`

  ## Examples

      # Show that the original jieba instance and the returned ones are entangled even
      # if the dict_paths are different.
      iex> jieba = Jieba.new!()
      iex> {:ok, new_jieba} = Jieba.load_dict(jieba, "test/example_userdict.txt")
      iex> jieba.dict_paths
      []
      iex> new_jieba.dict_paths
      ["test/example_userdict.txt"]
      iex> new_jieba.native == jieba.native
      true

      # Show the effect of the entanglement on the cut/3 function.
      iex> jieba = Jieba.new!()
      iex> old_cut = Jieba.cut(jieba, "李小福是创新办任也是云计算方面的家", true)
      ["李小福", "是", "创新", "办任", "也", "是", "云", "计算",
       "方面", "的", "家"]
      iex> {:ok, new_jieba} = Jieba.load_dict(jieba, "test/example_userdict.txt")
      iex> new_cut = Jieba.cut(new_jieba, "李小福是创新办任也是云计算方面的家", true)
      ["李小福", "是", "创新办", "任", "也", "是", "云", "计算",
       "方面", "的", "家"]
      iex> new_cut == old_cut
      false
      iex> old_cut == Jieba.cut(jieba, "李小福是创新办任也是云计算方面的家", true)
      false

      # Show error handling
      iex> jieba = Jieba.new!()
      iex> {:error, :enoent} = Jieba.load_dict(jieba, "NotAFile.nope.nope")
      iex> {:error, invalid_entry} = Jieba.load_dict(jieba, "test/malformed_userdict.txt")
      iex> invalid_entry
      "line 5 `This is an invalid entry.\\n` frequency is is not a valid integer: invalid digit found in string"
  """
  def load_dict(_jieba, _dict_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Merges the entries in `dict_path` to the current native Jieba instance using load_dict/2.

  Please see load_dict/2 for caveats about imperative behvior.

  Returns Jieba instance with merged dictionary.

  Raises Jieba.JiebaError on error.

  ## Examples
      iex> jieba = Jieba.new!()
      iex> new_jieba = Jieba.load_dict!(jieba, "test/example_userdict.txt")
      iex> Jieba.cut(new_jieba, "李小福是创新办任也是云计算方面的家", true)
      ["李小福", "是", "创新办", "任", "也", "是", "云", "计算",
       "方面", "的", "家"]
  """
  def load_dict!(rust_jieba, dict_path) do
    case load_dict(rust_jieba, dict_path) do
      {:ok, jieba} -> jieba
      {:error, reason} -> raise Jieba.JiebaError, message: to_string(reason)
    end
  end

  @doc """
  Given a new segment, this attempts to guess the frequency of the segment.
  It is used by `add_word()` if no `freq` is given.

  This can be used to examine the frequencies of the existing table which
  can be helpful for tuning or even scaling datasets for dialects of chinese
  without as much corpus data.  For example, if you had a small 粵語 dataset,
  you could look up common characters like 雨，車，窗 that are not likely to
  have a huge frequency diverenge (as opposed to things like 他 or 地 which
  while frequent are far more used in some dialects), find the average delta
  and then scale up the frequencies to match the dictionary you are merging
  in to.

  Returns 483 (frequency of the word)

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.suggest_freq(jieba, "也")
      307852
      iex> Jieba.suggest_freq(jieba, "是")
      796991
      iex> Jieba.suggest_freq(jieba, "也是")
      4083
      iex> Jieba.suggest_freq(jieba, "佢哋")
      1
  """
  def suggest_freq(_jieba, _segment), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Adds a segment to the dictionary with an optional frequency or tag.

  If no frequency is given, `suggest_freq()` is used to guess the frequency.
  This can be used to prevent oversegmentation.

  Returns 2434 (frequency of the added segment)

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.cut(jieba, "「台中」正确应该不会被切开", true)
      ["「", "台", "中", "」", "正确", "应该", "不会", "被", "切开"]
      iex> Jieba.add_word(jieba, "台中", nil, nil)
      69
      iex> Jieba.cut(jieba, "「台中」正确应该不会被切开", true)
      ["「", "台中", "」", "正确", "应该", "不会", "被", "切开"]
  """
  def add_word(_jieba, _word, _freq, _tag), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence and breaks it into a vector of segments.

  Returns `["李小福", "是"]`

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.cut(jieba, "李小福是创新办任也是云计算方面的家", true)
      ["李小福", "是", "创新", "办任", "也", "是", "云", "计算",
       "方面", "的", "家"]
  """
  def cut(_jieba, _sentence, _hmm \\ true), do: :erlang.nif_error(:nif_not_loaded)

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

      iex> jieba = Jieba.new!()
      iex> Jieba.cut_all(jieba, "李小福是创新办任也是云计算方面的家")
      ["李", "小", "福", "是", "创", "创新", "新", "办", "任", "也", "是", "云", "计", "计算", "算", "方", "方面", "面", "的", "家"]
  """
  def cut_all(_jieba, _sentence), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence and breaks it into a vector containing segments tuned for
  search engine keyword matching.  This tends to produce shorted segments
  that are more likely to produce a keyword match. For example,
  `"中国科学院"` will produce `["中国", "科学", "学院", "科学院", "中国科学院"]`
  whereas with `cut()`, it will just produce `["中国科学院"]`
  It is possible (and likely) that phrases will be repeated.

  Returns `["中国", "科学", "学院", "科学院", "中国科学院"]`

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.cut(jieba, "小明硕士毕业于中国科学院计算所，后在日本京都大学深造", true)
      ["小明", "硕士", "毕业", "于", "中国科学院", "计算所", "，", "后", "在", "日本京都大学", "深造"]
      iex> Jieba.cut_for_search(jieba, "小明硕士毕业于中国科学院计算所，后在日本京都大学深造", true)
      ["小明", "硕士", "毕业", "于", "中国", "科学", "学院", "科学院", "中国科学院", "计算",
       "计算所", "，", "后", "在", "日本", "京都", "大学", "日本京都大学", "深造"]
  """
  def cut_for_search(_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence, performs `cut()`, and then produces a vector of `Token` structs that
  indicate where in the sentence the segment comes from.

  The tokenization mode can be one of :default or :search.

  Returns `[
              %{start: 0, __struct__: Jieba.Token, word: "李小福"},
              %{start: 3, __struct__: Jieba.Token, word: "是"},["是"]`
           ]`

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.tokenize(jieba, "李小福是创新办任也是云计算方面的家", :default, true)
      [
          %{start: 0, __struct__: Jieba.Token, word: "李小福"},
          %{start: 3, __struct__: Jieba.Token, word: "是"},
          %{start: 4, __struct__: Jieba.Token, word: "创新"},
          %{start: 6, __struct__: Jieba.Token, word: "办任"},
          %{start: 8, __struct__: Jieba.Token, word: "也"},
          %{start: 9, __struct__: Jieba.Token, word: "是"},
          %{start: 10, __struct__: Jieba.Token, word: "云"},
          %{start: 11, __struct__: Jieba.Token, word: "计算"},
          %{start: 13, __struct__: Jieba.Token, word: "方面"},
          %{start: 15, __struct__: Jieba.Token, word: "的"},
          %{start: 16, __struct__: Jieba.Token, word: "家"}
      ]
  """
  def tokenize(_jieba, _sentence, _mode, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence, performs `cut()`, and then produces a vector of `Tag` structs that
  label each segment with a tag -- usually the part of speech.

  Returns `[
              %Jieba.Tag{word: "李小福", tag: "x"},
              %Jieba.Tag{word: "是", tag: "v"},
              ...
           ]`

  ## Examples

      iex> jieba = Jieba.new!()
      iex> Jieba.tag(jieba, "李小福是创新办任也是云计算方面的家", true)
      [
              %Jieba.Tag{word: "李小福", tag: "x"},
              %Jieba.Tag{word: "是", tag: "v"},
              %Jieba.Tag{word: "创新", tag: "v"},
              %Jieba.Tag{word: "办任", tag: "x"},
              %Jieba.Tag{word: "也", tag: "d"},
              %Jieba.Tag{word: "是", tag: "v"},
              %Jieba.Tag{word: "云", tag: "ns"},
              %Jieba.Tag{word: "计算", tag: "v"},
              %Jieba.Tag{word: "方面", tag: "n"},
              %Jieba.Tag{word: "的", tag: "uj"},
              %Jieba.Tag{word: "家", tag: "q"}
            ]
  """
  def tag(_jieba, _sentence, _hmm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Takes a sentence, and attempts to extract the top_k keywords based on TFIDF
  ranking.

  This constructs a new TFIDF struct each call. If there is no `tfidf_dict_path`
  or `_stop_words`, this is lightweight. However, if there is, it will
  reconstruct the internal data structure per call.

  We cannot do better yet because the Jieba-RS interface confusingly requires
  that the TFIDF struct must be bound to a stack-scoped Jieba object. With
  thi Elixir bridge. the Jieba object is actually dynamically allocated and
  shared with a ResourceARC and a Mutex. To do this more properly would
  require the Jieba-RS project redesign the TFIDF interface so it takes
  `jieba` on the `extract_keyword()` method and not as in the `new() method.

  Returns { :ok,
            [ %Jieba.Keyword{keyword: "北京烤鸭", weight: 1.3904870323222223},
              %Jieba.Keyword{keyword: "纽约", weight: 1.121759684755},
              %Jieba.Keyword{keyword: "天气", weight: 1.0766573240983333}
            ]
          }

  ## Examples
      iex> jieba = Jieba.new!()
      iex> {:ok, top_k_tags} = Jieba.tfidf_extract_tags(jieba, "今天纽约的天气真好啊，京华大酒店的张尧经理吃了一只北京烤鸭。后天纽约的天气不好，昨天纽约的天气也不好，北京烤鸭真好吃", 3)
      iex> top_k_tags
      [%Jieba.Keyword{keyword: "北京烤鸭", weight: 1.3904870323222223}, %Jieba.Keyword{keyword: "纽约", weight: 1.121759684755}, %Jieba.Keyword{keyword: "天气", weight: 1.0766573240983333}]

      iex> jieba = Jieba.new!()
      iex> {:error, :enoent} = Jieba.tfidf_extract_tags(jieba, "", 3, [], "NotAFile.nope.nope")
  """
  def tfidf_extract_tags(_jieba, _sentence, _top_k, _allowed_pos \\ [], _tfidf_dict_path \\ "", _stop_words \\ []), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Uses TFIDF algorithm to extract tags.

  Returns list of Jieba.Keyword

  Raises Jieba.JiebaError on error.

  ## Examples
      iex> jieba = Jieba.new!()
      iex> Jieba.tfidf_extract_tags!(jieba, "今天纽约的天气真好啊，京华大酒店的张尧经理吃了一只北京烤鸭。后天纽约的天气不好，昨天纽约的天气也不好，北京烤鸭真好吃", 3)
      [%Jieba.Keyword{keyword: "北京烤鸭", weight: 1.3904870323222223}, %Jieba.Keyword{keyword: "纽约", weight: 1.121759684755}, %Jieba.Keyword{keyword: "天气", weight: 1.0766573240983333}]
  """
  def tfidf_extract_tags!(jieba, sentence, top_k, allowed_pos \\ [], tfidf_dict_path \\ "", stop_words \\ []) do
    case tfidf_extract_tags(jieba, sentence, top_k, allowed_pos, tfidf_dict_path, stop_words) do
      {:ok, tags} -> tags
      {:error, reason} -> raise Jieba.JiebaError, message: to_string(reason)
    end
  end

  @doc """
  Takes a sentence, and attempts to extract the top_k keywords based on TextRank
  ranking.

  This constructs a new TextRank struct each call. If there is no `_stop_words`,
  this is lightweight. However, if there is, it will reconstruct the internal
  data structure per call.

  We cannot do better yet because the Jieba-RS interface confusingly requires
  that the TextRank struct must be bound to a stack-scoped Jieba object. With
  thi Elixir bridge. the Jieba object is actually dynamically allocated and
  shared with a ResourceARC and a Mutex. To do this more properly would
  require the Jieba-RS project redesign the TextRank interface so it takes
  `jieba` on the `extract_keyword()` method and not as in the `new() method.

  Returns { :ok,
            [
              %Jieba.Keyword{keyword: "天气", weight: 19307118367.17687},
              %Jieba.Keyword{keyword: "纽约", weight: 19179632457.07701},
              %Jieba.Keyword{keyword: "不好", weight: 13769629783.10484}
            ]
          }

  ## Examples
      iex> jieba = Jieba.new!()
      iex> {:ok, top_k_tags } = Jieba.textrank_extract_tags(jieba, "今天纽约的天气真好啊，京华大酒店的张尧经理吃了一只北京烤鸭。后天纽约的天气不好，昨天纽约的天气也不好，北京烤鸭真好吃", 3)
      iex> top_k_tags
      [ %Jieba.Keyword{keyword: "天气", weight: 19307118367.17687}, %Jieba.Keyword{keyword: "纽约", weight: 19179632457.07701}, %Jieba.Keyword{keyword: "不好", weight: 13769629783.10484} ]
  """
  def textrank_extract_tags(_jieba, _sentence, _top_k, _allowed_pos \\ [], _stop_words \\ []), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Uses TextRank algorithm to extract tags.

  Returns list of Jieba.Keyword

  Raises Jieba.JiebaError on error.

  ## Examples
      iex> jieba = Jieba.new!()
      iex> Jieba.textrank_extract_tags!(jieba, "今天纽约的天气真好啊，京华大酒店的张尧经理吃了一只北京烤鸭。后天纽约的天气不好，昨天纽约的天气也不好，北京烤鸭真好吃", 3)
      [ %Jieba.Keyword{keyword: "天气", weight: 19307118367.17687}, %Jieba.Keyword{keyword: "纽约", weight: 19179632457.07701}, %Jieba.Keyword{keyword: "不好", weight: 13769629783.10484} ]
  """
  def textrank_extract_tags!(jieba, sentence, top_k, allowed_pos \\ [], stop_words \\ []) do
    case textrank_extract_tags(jieba, sentence, top_k, allowed_pos, stop_words) do
      {:ok, tags} -> tags
      {:error, reason} -> raise Jieba.JiebaError, message: to_string(reason)
    end
  end
end
