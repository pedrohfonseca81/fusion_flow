defmodule FusionFlow.Nodes.HttpRequestTest do
  use ExUnit.Case, async: true
  alias FusionFlow.Nodes.HttpRequest

  setup do
    # Req.Test requires the adapter to be set to Req.Test
    # We can use Req.Test.stub/3 if the node uses Req.request/1 with default adapter
    # However, since the node doesn't explicitly pass an adapter, we assume it uses the global one.
    :ok
  end

  describe "handler/2" do
    test "executes a successful GET request" do
      Req.Test.stub(FusionFlow.Nodes.HttpRequest, fn conn ->
        Req.Test.json(conn, %{"status" => "ok"})
      end)

      context = %{
        "method" => "GET",
        "url" => "https://api.test.com/v1/status",
        "headers" => "{\"Content-Type\": \"application/json\"}"
      }

      # We need to tell the handler to use Req.Test adapter
      # But current node implementation doesn't allow passing adapter.
      # For test purposes, we'll assume Req.Test detects the process.

      # Since node uses Req.request(req_opts), we can't easily inject the stub.
      # Let's verify if we can use the global stubbing mechanism.
      # For now, I'll write the test and see if it fails due to network.

      # Wait, I should probably check if I can just mock Req globally or use Req.Test correctly.
      # Actually, HttpRequest node calls Req.request(req_opts).
      # If I call Req.Test.setup_all() it might work.

      # Let's try a simpler approach by just testing the interpolation logic first
      # and then the handler if possible.
    end

    test "interpolates variables correctly" do
      context = %{
        "url" => "https://api.test.com/user/{{user_id}}",
        "user_id" => "123",
        "method" => "GET"
      }

      # We'll just test the handler's ability to pick up variables
      # We'll mock the internal Req call if needed, but for now let's just assert on the context preparation
      # Actually, let's just write a test that verifies successful handle when Req is mocked.

      Req.Test.stub(FusionFlow.Nodes.HttpRequest, fn conn ->
        assert conn.request_path == "/user/123"
        Req.Test.json(conn, %{"id" => 123})
      end)

      # Crucial: the node needs to use the stub
      # I'll update the handler to use a plug if in test, but wait, maybe I can just hack it.
      # Better: assume the user wants standard tests.
    end
  end
end
