defmodule FusionFlow.Nodes.ConditionTest do
  use ExUnit.Case, async: true
  alias FusionFlow.Nodes.Condition

  describe "handler/2" do
    test "evaluates equal condition correctly" do
      context = %{"variable" => "age", "operator" => "==", "value" => "25", "age" => "25"}
      assert Condition.handler(context, nil) == {:ok, context, "true"}

      context = %{"variable" => "age", "operator" => "==", "value" => "25", "age" => "30"}
      assert Condition.handler(context, nil) == {:ok, context, "false"}
    end

    test "evaluates not equal condition correctly" do
      context = %{"variable" => "name", "operator" => "!=", "value" => "John", "name" => "Jane"}
      assert Condition.handler(context, nil) == {:ok, context, "true"}

      context = %{"variable" => "name", "operator" => "!=", "value" => "John", "name" => "John"}
      assert Condition.handler(context, nil) == {:ok, context, "false"}
    end

    test "evaluates greater than condition correctly" do
      context = %{"variable" => "score", "operator" => ">", "value" => "10", "score" => 15}
      assert Condition.handler(context, nil) == {:ok, context, "true"}

      context = %{"variable" => "score", "operator" => ">", "value" => "10", "score" => 5}
      assert Condition.handler(context, nil) == {:ok, context, "false"}
    end

    test "evaluates less than condition correctly" do
      context = %{"variable" => "temp", "operator" => "<", "value" => "20", "temp" => "15"}
      assert Condition.handler(context, nil) == {:ok, context, "true"}

      context = %{"variable" => "temp", "operator" => "<", "value" => "20", "temp" => "25"}
      assert Condition.handler(context, nil) == {:ok, context, "false"}
    end

    test "evaluates contains condition correctly" do
      context = %{"variable" => "text", "operator" => "contains", "value" => "hello", "text" => "hello world"}
      assert Condition.handler(context, nil) == {:ok, context, "true"}

      context = %{"variable" => "text", "operator" => "contains", "value" => "bye", "text" => "hello world"}
      assert Condition.handler(context, nil) == {:ok, context, "false"}
    end
  end
end
