defmodule JiebaTest do
  use ExUnit.Case
  doctest Jieba

  test "cut with default dict" do
    j = Jieba.new()
    assert ["呢", "個", "係", "乜嘢", "呀"] == Jieba.cut(j, "呢個係乜嘢呀")
  end
end
