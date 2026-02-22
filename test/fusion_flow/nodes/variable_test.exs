defmodule FusionFlow.Nodes.VariableTest do
  use ExUnit.Case, async: true
  alias FusionFlow.Nodes.Variable

  describe "handler/2" do
    test "sets a string variable correctly" do
      context = %{"var_name" => "name", "var_value" => "Alice", "var_type" => "String"}
      {:ok, updated_context} = Variable.handler(context, nil)
      assert updated_context["name"] == "Alice"
    end

    test "sets an integer variable correctly" do
      context = %{"var_name" => "age", "var_value" => "42", "var_type" => "Integer"}
      {:ok, updated_context} = Variable.handler(context, nil)
      assert updated_context["age"] == 42
    end

    test "sets a JSON variable correctly" do
      context = %{"var_name" => "data", "var_value" => "{\"foo\": \"bar\"}", "var_type" => "JSON"}
      {:ok, updated_context} = Variable.handler(context, nil)
      assert updated_context["data"] == %{"foo" => "bar"}
    end

    test "handles invalid integer gracefully" do
      context = %{"var_name" => "age", "var_value" => "invalid", "var_type" => "Integer"}
      {:ok, updated_context} = Variable.handler(context, nil)
      assert updated_context["age"] == "invalid"
    end

    test "handles invalid JSON gracefully" do
      context = %{"var_name" => "data", "var_value" => "invalid json", "var_type" => "JSON"}
      {:ok, updated_context} = Variable.handler(context, nil)
      assert updated_context["data"] == "invalid json"
    end

    test "does nothing if var_name is missing" do
      context = %{"var_value" => "Alice"}
      assert Variable.handler(context, nil) == {:ok, context}
    end
  end
end
