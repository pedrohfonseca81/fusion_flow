defmodule FusionFlowWeb.FlowControllerTest do
  use FusionFlowWeb.ConnCase, async: true

  alias FusionFlow.Flows
  import FusionFlow.FlowsFixtures

  describe "index" do
    test "lists all flows", %{conn: conn} do
      flow = flow_fixture()
      conn = get(conn, ~p"/api/flows")

      assert %{
               "data" => [
                 %{
                   "id" => _id,
                   "name" => "Test Flow"
                 }
               ]
             } = json_response(conn, 200)
    end
  end

  describe "create flow" do
    test "creates flow with valid data", %{conn: conn} do
      attrs = %{name: "New Flow", nodes: [], connections: []}

      conn = post(conn, ~p"/api/flows", flow: attrs)

      assert %{"id" => _id, "name" => "New Flow"} = json_response(conn, :created)["data"]
    end

    test "returns error with invalid data", %{conn: conn} do
      attrs = %{nodes: [], connections: []}

      conn = post(conn, ~p"/api/flows", flow: attrs)

      assert json_response(conn, :unprocessable_entity)
    end
  end

  describe "show flow" do
    test "shows a specific flow", %{conn: conn} do
      flow = flow_fixture()
      conn = get(conn, ~p"/api/flows/#{flow}")

      assert %{"id" => id, "name" => "Test Flow"} = json_response(conn, 200)["data"]
      assert id == flow.id
    end
  end

  describe "update flow" do
    test "updates flow with valid data", %{conn: conn} do
      flow = flow_fixture()
      attrs = %{name: "Updated Flow"}

      conn = put(conn, ~p"/api/flows/#{flow}", flow: attrs)

      assert %{"name" => "Updated Flow"} = json_response(conn, 200)["data"]
    end
  end

  describe "delete flow" do
    test "deletes a flow", %{conn: conn} do
      flow = flow_fixture()

      conn = delete(conn, ~p"/api/flows/#{flow}")

      assert response(conn, :no_content)
      assert_raise Ecto.NoResultsError, fn -> Flows.get_flow!(flow.id) end
    end
  end
end
