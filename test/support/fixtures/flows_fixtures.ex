defmodule FusionFlow.FlowsFixtures do
  alias FusionFlow.Flows

  def flow_fixture(attrs \\ %{}) do
    {:ok, flow} =
      attrs
      |> Enum.into(%{
        name: "Test Flow",
        nodes: [],
        connections: []
      })
      |> Flows.create_flow()

    flow
  end
end
