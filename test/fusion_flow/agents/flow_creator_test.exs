defmodule FusionFlow.Agents.FlowCreatorTest do
  use ExUnit.Case, async: true

  describe "chat/2" do
    test "returns ok tuple with stream" do
      messages = [%{role: "user", content: "hello"}]
      result = FusionFlow.Agents.FlowCreator.chat(messages)

      assert {:ok, %{stream: _stream}} = result
    end

    test "accepts current_flow parameter" do
      messages = [%{role: "user", content: "create a flow"}]
      current_flow = %{nodes: [], connections: []}

      result = FusionFlow.Agents.FlowCreator.chat(messages, current_flow)
      assert {:ok, %{stream: _stream}} = result
    end

    test "works with nil current_flow" do
      messages = [%{role: "user", content: "what can you do?"}]

      result = FusionFlow.Agents.FlowCreator.chat(messages, nil)
      assert {:ok, %{stream: _stream}} = result
    end
  end
end
