defmodule FusionFlow.Nodes.OutputTest do
  use FusionFlow.DataCase, async: true
  alias FusionFlow.Nodes.Output
  alias FusionFlow.Flows
  alias FusionFlow.Flows.ExecutionLog

  describe "handler/2" do
    test "creates an execution log and returns ok" do
      # Create a flow first
      {:ok, flow} = Flows.create_flow(%{name: "Test Flow", nodes: [], connections: []})

      context = %{
        "flow_id" => flow.id,
        "status" => "completed",
        "data" => "some result"
      }

      assert {:ok, result_context} = Output.handler(context, nil)
      assert result_context == context

      # Verify log was created
      [log] = Repo.all(ExecutionLog)
      assert log.flow_id == flow.id
      assert log.status == "completed"
      assert log.context == %{"data" => "some result"}
      assert log.node_id == "Output"
    end

    test "defaults to success status if missing" do
      {:ok, flow} = Flows.create_flow(%{name: "Test Flow", nodes: [], connections: []})
      context = %{"flow_id" => flow.id}

      assert {:ok, _} = Output.handler(context, nil)

      [log] = Repo.all(ExecutionLog)
      assert log.status == "success"
    end
  end
end
