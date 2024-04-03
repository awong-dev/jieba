defmodule F1Score do
  @doc """
  Produce a list of (index, segment) to show which segment each position of the
  string got assigned to.

  ## Examples
  Hypothesis: 共同 创造 美 好 的 新 世纪 —— 二○○一年 新年 贺词
      iex> F1Score.expand(["喂", "遲", "啲", "去", "唔", "去", "旅行", "啊", "?"])
      [{0, 0}, {1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 6}, {8, 7}, {9, 8}]
  """
  def expand(segments) do
    [result, _] = segments
        |> Enum.reduce([[], 0], fn (segment, [output, char_count]) ->
            [output ++ [{char_count, segment}], char_count + String.length(segment)]
            end)
    result
  end

  @doc """
  Given 2 lists of segments, gets the precision + recall number as 2 tuples.

  Precision is defined as number of segments in the hypothesis that match
  exactly with what's in the golden.

  Recall is defined as number of segments in the golden that match
  exactly with what's in the segment.

  A segment match is defined as the same character span with the same number.

  Returns: {{num_hyp_matched, total_hyp_segments}, {num_gold_matched, num_gold_segments}}

  ## Examples

      iex> hypothesis = ["共同","创造","美", "好","的","新","世纪","——","二○○一年","新年","贺词"]
      iex> golden = ["共同","创造","美好","的","新","世纪","——","二○○一年","新年","贺词"]
      iex> precision_recall(hypothesis, golden)
      {{2, 11}, {1, 10}}
  """
  def precision_recall(hypothesis, golden) do
    h = MapSet.new(expand(hypothesis))
    g = MapSet.new(expand(golden))
    h_size = MapSet.size(h) 
    g_size = MapSet.size(g)
    { {h_size - MapSet.size(MapSet.difference(h,g)), h_size},
      {g_size - MapSet.size(MapSet.difference(g,h)), g_size} }
  end

  def calcluate_score({{num_hyp_matched, total_hyp_segments}, {num_gold_matched, num_gold_segments}}) do
    precision = num_hyp_matched / total_hyp_segments
    recall = num_gold_matched / num_gold_segments
    f1 = (2 * precision * recall) / (precision + recall)
    IO.puts("Precision: #{precision}, Recall: #{recall}, F1: #{f1}")
  end

  def score_corpus(segmenter, corpus) do
    corpus
      |> Enum.map(fn [utt, golden] -> {segmenter.(utt), golden} end)
      |> Enum.reduce({{0,0}, {0,0}},
           fn ({hypothesis, golden}, 
               {{num_hyp_matched, total_hyp_segments}, {num_gold_matched, num_gold_segments}}) ->
           {{h_m, h_s}, {g_m, g_s}} = F1Score.precision_recall(hypothesis, golden);
           {{num_hyp_matched + h_m, total_hyp_segments + h_s}, {num_gold_matched + g_m, num_gold_segments + g_s}} end)
      |> F1Score.calcluate_score()
  end
end

hkcancor_segmentation = Jason.decode!(File.read!('corpus/data/hkcancor_segmentation.json'))
jieba_default = Jieba.new!()
jieba_yue = Jieba.new!(dict_paths: ["merged_dict.txt"])

IO.puts("\nDefault no hmm:")
IO.inspect(F1Score.score_corpus(&(Jieba.cut(jieba_default, &1, false)), hkcancor_segmentation))

IO.puts("\nDefault with hmm:")
IO.inspect(F1Score.score_corpus(&(Jieba.cut(jieba_default, &1, true)), hkcancor_segmentation))

IO.puts("\nyue no hmm:")
IO.inspect(F1Score.score_corpus(&(Jieba.cut(jieba_yue, &1, false)), hkcancor_segmentation))

IO.puts("\nyuet with hmm:")
IO.inspect(F1Score.score_corpus(&(Jieba.cut(jieba_yue, &1, true)), hkcancor_segmentation))
