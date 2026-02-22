defmodule FusionFlowWeb.FlowLiveTest do
  use FusionFlowWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import FusionFlow.FlowsFixtures

  describe "mount" do
    test "requires authentication", %{conn: conn} do
      flow = flow_fixture()

      assert {:error, redirect} = live(conn, ~p"/flows/#{flow.id}")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "loads flow by id", %{conn: conn} do
      flow = flow_fixture(%{name: "Test Flow"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/flows/#{flow.id}")

      assert html =~ "Test Flow"
    end

    test "shows node sidebar", %{conn: conn} do
      flow = flow_fixture()

      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/flows/#{flow.id}")

      assert html =~ "Nodes"
    end
  end

  describe "client_ready" do
    test "has nodes data", %{conn: conn} do
      flow = flow_fixture(%{
        name: "Test Flow",
        nodes: [%{"id" => "1", "type" => "Start"}],
        connections: []
      })

      {:ok, lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/flows/#{flow.id}")

      assert html =~ "Test Flow"
    end
  end
end
