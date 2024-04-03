defmodule JiebaTest do
  use ExUnit.Case
  doctest Jieba
  test "empty" do
    empty_jieba = Jieba.new!(use_default: :false, hmm: false)
    assert Jieba.cut(empty_jieba, "鄧小平學生好可憐") == ["鄧","小","平","學","生","好","可","憐"]

  end
end
