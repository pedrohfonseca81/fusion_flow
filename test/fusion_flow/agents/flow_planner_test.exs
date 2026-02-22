defmodule FusionFlow.Agents.FlowPlannerTest do
  use ExUnit.Case, async: true

  describe "chat/3" do
    test "returns ok tuple with stream" do
      messages = [%{role: "user", content: "hello"}]
      result = FusionFlow.Agents.FlowPlanner.chat(messages)

      assert {:ok, %{stream: _stream}} = result
    end

    test "accepts current_flow parameter" do
      messages = [%{role: "user", content: "create a flow"}]
      current_flow = %{nodes: [], connections: []}

      result = FusionFlow.Agents.FlowPlanner.chat(messages, current_flow)
      assert {:ok, %{stream: _stream}} = result
    end

    test "accepts locale parameter" do
      messages = [%{role: "user", content: "hola"}]

      result = FusionFlow.Agents.FlowPlanner.chat(messages, nil, "es")
      assert {:ok, %{stream: _stream}} = result
    end

    test "works with all nil parameters" do
      messages = [%{role: "user", content: "help"}]

      result = FusionFlow.Agents.FlowPlanner.chat(messages, nil, "en")
      assert {:ok, %{stream: _stream}} = result
    end
  end
end
