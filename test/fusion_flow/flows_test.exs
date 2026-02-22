defmodule FusionFlow.FlowsTest do
  use FusionFlow.DataCase

  alias FusionFlow.Flows

  describe "flows" do
    alias FusionFlow.Flows.Flow

    import FusionFlow.FlowsFixtures

    test "list_flows/0 returns all flows" do
      flow = flow_fixture()
      assert Flows.list_flows() |> Enum.map(& &1.id) |> Enum.member?(flow.id)
    end

    test "get_flow!/1 returns the flow with given id" do
      flow = flow_fixture()
      assert Flows.get_flow!(flow.id).id == flow.id
    end

    test "create_flow/1 with valid data creates a flow" do
      attrs = %{name: "Test Flow", nodes: [], connections: []}
      assert {:ok, flow} = Flows.create_flow(attrs)
      assert flow.name == "Test Flow"
      assert flow.nodes == []
      assert flow.connections == []
    end

    test "create_flow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Flows.create_flow(%{})
    end

    test "update_flow/2 with valid data updates the flow" do
      flow = flow_fixture()
      assert {:ok, updated} = Flows.update_flow(flow, %{name: "Updated Flow"})
      assert updated.name == "Updated Flow"
    end

    test "delete_flow/1 deletes the flow" do
      flow = flow_fixture()
      assert {:ok, _} = Flows.delete_flow(flow)
      assert_raise Ecto.NoResultsError, fn -> Flows.get_flow!(flow.id) end
    end

    test "change_flow/1 returns a flow changeset" do
      flow = flow_fixture()
      assert %Ecto.Changeset{} = Flows.change_flow(flow)
    end

    test "get_first_or_create_default_flow/0 returns existing flow" do
      flow = flow_fixture()
      assert {:ok, result} = Flows.get_first_or_create_default_flow()
      assert result.id == flow.id
    end

    test "get_first_or_create_default_flow/0 creates default when none exist" do
      assert Flows.list_flows() == []
      assert {:ok, flow} = Flows.get_first_or_create_default_flow()
      assert flow.name == "My First Flow"
    end
  end

  describe "execution_logs" do
    alias FusionFlow.Flows.ExecutionLog

    import FusionFlow.FlowsFixtures

    test "create_execution_log/1 with valid data creates a log" do
      flow = flow_fixture()
      attrs = %{flow_id: flow.id, status: "running", context: %{}}

      assert {:ok, log} = Flows.create_execution_log(attrs)
      assert log.status == "running"
    end

    test "create_execution_log/1 without context returns error" do
      flow = flow_fixture()
      attrs = %{flow_id: flow.id, status: "running"}

      assert {:error, %Ecto.Changeset{}} = Flows.create_execution_log(attrs)
    end
  end
end
