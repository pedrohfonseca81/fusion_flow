defmodule FusionFlowWeb.FlowListLiveTest do
  use FusionFlowWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import FusionFlow.FlowsFixtures

  describe "mount" do
    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/flows")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "renders flow list", %{conn: conn} do
      flow_fixture(%{name: "My Flow"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/flows")

      assert html =~ "My Flow"
      assert html =~ "My Flows"
    end

    test "shows empty state when no flows", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/flows")

      assert html =~ "No flows created yet"
      assert html =~ "Get started"
    end

    test "displays flow count", %{conn: conn} do
      flow_fixture(%{name: "Flow 1"})
      flow_fixture(%{name: "Flow 2"})
      flow_fixture(%{name: "Flow 3"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/flows")

      assert html =~ "3 Flows available"
    end
  end

  describe "create_flow" do
    test "creates a new flow when button is clicked", %{conn: conn} do
      user = FusionFlow.AccountsFixtures.user_fixture()

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/flows")

      lv
      |> element("button", "New Flow")
      |> render_click()
    end
  end
end
