defmodule FusionFlow.Runtime.Executor do
  @moduledoc """
  Defines the behaviour for language executors in FusionFlow.
  """

  @callback execute(code :: String.t(), context :: map()) ::
              {:ok, map()} | {:result, any()} | {:error, any()}
end
