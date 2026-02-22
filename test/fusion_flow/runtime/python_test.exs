defmodule FusionFlow.Runtime.PythonTest do
  use ExUnit.Case, async: true

  describe "execute/2" do
    test "executes simple python code and returns result" do
      code = "1 + 1"
      context = %{}

      result = FusionFlow.Runtime.Python.execute(code, context)
      assert {:result, 2} = result
    end

    test "executes code with input from context" do
      code = "input * 2"
      context = %{"input" => 5}

      result = FusionFlow.Runtime.Python.execute(code, context)
      assert {:result, 10} = result
    end

    test "returns error for invalid syntax" do
      code = "1 +"
      context = %{}

      result = FusionFlow.Runtime.Python.execute(code, context)
      assert {:error, _} = result
    end

    test "returns error for undefined variable" do
      code = "undefined_var + 1"
      context = %{}

      result = FusionFlow.Runtime.Python.execute(code, context)
      assert {:error, _} = result
    end

    test "executes code that returns a dict" do
      code = "{\"key\": input}"
      context = %{"input" => "value"}

      result = FusionFlow.Runtime.Python.execute(code, context)
      assert {:ok, %{"key" => "value"}} = result
    end

    test "handles nil code gracefully" do
      code = nil
      context = %{}

      result = FusionFlow.Runtime.Python.execute(code, context)
      assert match?({:result, _}, result) or match?({:error, _}, result)
    end
  end
end
