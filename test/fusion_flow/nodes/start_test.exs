defmodule FusionFlow.Nodes.StartTest do
  use ExUnit.Case, async: true
  alias FusionFlow.Nodes.Start

  describe "definition/0" do
    test "returns the correct node definition" do
      definition = Start.definition()
      assert definition.name == "Start"
      assert definition.category == :flow_control
      assert definition.inputs == []
      assert definition.outputs == ["exec"]
    end
  end

  describe "handler/2" do
    test "returns :ok and the original context" do
      context = %{"foo" => "bar"}
      assert Start.handler(context, nil) == {:ok, context}
    end
  end
end
