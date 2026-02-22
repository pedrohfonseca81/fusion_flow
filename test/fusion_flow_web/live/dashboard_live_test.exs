defmodule FusionFlowWeb.DashboardLiveTest do
  use FusionFlowWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "renders dashboard with flows", %{conn: conn} do
      flow = FusionFlow.FlowsFixtures.flow_fixture(%{name: "Test Flow"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/")

      assert html =~ "Dashboard"
      assert html =~ "Test Flow"
      assert html =~ "Total Workflows"
    end

    test "shows empty state when no flows", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/")

      assert html =~ "No flows"
      assert html =~ "Create Flow"
    end

    test "displays flow count", %{conn: conn} do
      FusionFlow.FlowsFixtures.flow_fixture(%{name: "Flow 1"})
      FusionFlow.FlowsFixtures.flow_fixture(%{name: "Flow 2"})

      {:ok, _lv, html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/")

      assert html =~ "2"
    end

    test "handles change_locale event", %{conn: conn} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(FusionFlow.AccountsFixtures.user_fixture())
        |> live(~p"/")

      {:ok, conn} =
        lv
        |> form("#locale-form")
        |> render_change(%{locale: "pt_BR"})
        |> follow_redirect(conn, ~p"/?locale=pt_BR")

      assert conn.assigns.locale == "pt_BR"
    end
  end
end
