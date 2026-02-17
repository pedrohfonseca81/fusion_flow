defmodule FusionFlow.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :fusion_flow

  def setup do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def create do
    load_app()

    for repo <- repos() do
      case repo.__adapter__.storage_up(repo.config) do
        :ok ->
          IO.puts("The database for #{inspect(repo)} has been created")

        {:error, :already_up} ->
          IO.puts("The database for #{inspect(repo)} has already been created")

        {:error, term} ->
          IO.puts("The database for #{inspect(repo)} could not be created: #{inspect(term)}")
      end
    end
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
