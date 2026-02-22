defmodule FusionFlow.Nodes.EvalTest do
  use ExUnit.Case, async: true
  alias FusionFlow.Nodes.Eval

  describe "handler/2" do
    test "executes Elixir code correctly" do
      context = %{
        "language" => "elixir",
        "code_elixir" => "1 + 2",
        "a" => 10,
        "b" => 20
      }

      # The eval node currently puts the result in {:ok, result} or similar
      # Looking at handler: result = case language do ... end; result

      # Let's check a more complex Elixir snippet that uses context
      context = %{
        "language" => "elixir",
        "code_elixir" => "variable(:a) + variable!(:b)",
        "a" => 10,
        "b" => 20
      }

      assert {:result, 30} = Eval.handler(context, nil)
    end

    test "executes Python code correctly" do
      context = %{
        "language" => "python",
        "code_python" => "a + b",
        "a" => 10,
        "b" => 20
      }

      # For Python, we use an expression to get the result
      # Python execution depends on pythonx
      # We'll test if it returns the expected result
      assert {:result, 30} = Eval.handler(context, nil)
    end

    test "handles Elixir errors gracefully" do
      context = %{
        "language" => "elixir",
        "code_elixir" => "raise \"error\""
      }

      assert {:error, _reason} = Eval.handler(context, nil)
    end

    test "handles Python errors gracefully" do
      context = %{
        "language" => "python",
        "code_python" => "raise Exception('error')"
      }

      assert {:error, _reason} = Eval.handler(context, nil)
    end
  end
end
