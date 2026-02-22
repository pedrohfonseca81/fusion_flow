defmodule FusionFlowWeb.FlowAiCreatorLiveTest do
  use FusionFlowWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "mount" do
    test "requires authentication", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/flows/new/ai")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end
  end
end
