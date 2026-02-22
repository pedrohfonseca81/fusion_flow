defmodule FusionFlowTest.CodeParserTest do
  use ExUnit.Case
  alias FusionFlow.CodeParser

  test "parses select field" do
    code = """
    ui do
      select :method, ["GET", "POST", "PUT"], default: "GET"
    end
    """

    {:ok, fields} = CodeParser.parse_ui_definition(code)

    assert length(fields) == 1
    assert hd(fields).type == "select"
    assert hd(fields).name == "method"
    assert hd(fields).value == "GET"
    assert length(hd(fields).options) == 3
  end

  test "parses text field" do
    code = """
    ui do
      text :url, label: "Endpoint URL", default: "https://api.example.com"
    end
    """

    {:ok, fields} = CodeParser.parse_ui_definition(code)

    assert length(fields) == 1
    assert hd(fields).type == "text"
    assert hd(fields).name == "url"
    assert hd(fields).label == "Url"
    assert hd(fields).value == ""
  end

  test "parses multiple fields" do
    code = """
    ui do
      select :method, ["GET", "POST"], default: "GET"
      text :url, label: "URL", default: "https://example.com"
    end

    # Implementation
    IO.puts("hello")
    """

    {:ok, fields} = CodeParser.parse_ui_definition(code)

    assert length(fields) == 2
  end

  test "handles code without ui block" do
    code = """
    # Just implementation
    IO.puts("hello")
    """

    {:ok, fields} = CodeParser.parse_ui_definition(code)

    assert fields == [] or fields == nil
  end
end
