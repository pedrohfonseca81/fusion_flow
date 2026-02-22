defmodule FusionFlowWeb.Plugs.SetLocaleTest do
  use FusionFlowWeb.ConnCase, async: true

  alias FusionFlowWeb.Plugs.SetLocale

  describe "call/2" do
    test "sets locale from params", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Map.put(:params, %{"locale" => "pt_BR"})
        |> Plug.Conn.fetch_query_params()

      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "pt_BR"
    end

    test "ignores unsupported locale from params", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Map.put(:params, %{"locale" => "invalid"})
        |> Plug.Conn.fetch_query_params()

      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "en"
    end

    test "sets locale from session", %{conn: conn} do
      conn = init_test_session(conn, %{locale: "pt_BR"})
      conn = Plug.Conn.fetch_query_params(conn)
      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "pt_BR"
    end

    test "ignores unsupported locale from session", %{conn: conn} do
      conn = init_test_session(conn, %{locale: "invalid"})
      conn = Plug.Conn.fetch_query_params(conn)
      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "en"
    end

    test "sets locale from accept-language header", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Plug.Conn.fetch_query_params()

      conn = %{conn | req_headers: [{"accept-language", "pt_BR,en;q=0.9"}]}
      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "pt_BR"
    end

    test "defaults to en when no locale provided", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> Plug.Conn.fetch_query_params()

      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "en"
    end

    test "params take precedence over session", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{locale: "pt_BR"})
        |> Map.put(:params, %{"locale" => "en"})
        |> Plug.Conn.fetch_query_params()

      conn = SetLocale.call(conn, nil)

      assert conn.assigns.locale == "en"
    end
  end
end
