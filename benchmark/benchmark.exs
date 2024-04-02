hkcancor_segmentation = Jason.decode!(File.read!('corpus/data/hkcancor_segmentation.json'))
utterances = Enum.map(hkcancor_segmentation, &Enum.at(&1,0))

jieba_default = Jieba.new!()

Benchee.run(%{
  "jieba_default"    => fn -> Enum.map(utterances, &Jieba.cut(jieba_default, &1, true)) end,
  "jieba_default_no_hmm"    => fn -> Enum.map(utterances, &Jieba.cut(jieba_default, &1, false)) end,
})
