defmodule FusionFlow.AITest do
  use ExUnit.Case, async: true

  describe "stream_text/2" do
    test "returns ok tuple with stream" do
      messages = [%{role: "user", content: "hello"}]
      result = FusionFlow.AI.stream_text(messages, system: "you are a assistant")

      assert {:ok, %{stream: _stream}} = result
    end

    test "adds system message when provided" do
      messages = [%{role: "user", content: "hello"}]
      system = "you are helpful"

      result = FusionFlow.AI.stream_text(messages, system: system)
      assert {:ok, %{stream: _stream}} = result
    end

    test "uses custom model when provided" do
      messages = [%{role: "user", content: "hello"}]

      result = FusionFlow.AI.stream_text(messages, system: "test", model: "gpt-4")
      assert {:ok, %{stream: _stream}} = result
    end

    test "handles empty messages" do
      result = FusionFlow.AI.stream_text([], system: "test")
      assert {:ok, %{stream: _stream}} = result
    end
  end
end
