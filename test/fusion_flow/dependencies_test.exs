defmodule FusionFlow.DependenciesTest do
  use FusionFlow.DataCase

  alias FusionFlow.Dependencies

  describe "list_dependencies/0" do
    test "returns all dependencies" do
      deps = Dependencies.list_dependencies()
      assert is_list(deps)
    end
  end

  describe "list_installed_mix_deps/0" do
    test "returns list of installed mix dependencies" do
      deps = Dependencies.list_installed_mix_deps()
      assert is_list(deps)

      if deps != [] do
        dep = hd(deps)
        assert is_map(dep)
        assert Map.has_key?(dep, :name)
        assert Map.has_key?(dep, :version)
        assert Map.has_key?(dep, :language)
      end
    end

    test "dependencies have required fields" do
      deps = Dependencies.list_installed_mix_deps()

      for dep <- deps do
        assert is_binary(dep.name)
        assert is_binary(dep.version)
        assert dep.language == "elixir"
      end
    end
  end

  describe "add_dependency/3" do
    test "creates a dependency record with javascript" do
      name = "test_js_dep_#{:rand.uniform(999_999)}"
      result = Dependencies.add_dependency(name, "1.0.0", "javascript")

      assert {:ok, dep} = result
      assert dep.name == name
      assert dep.version == "1.0.0"
      assert dep.language == "javascript"
    end

    test "creates a dependency record with python" do
      name = "test_py_dep_#{:rand.uniform(999_999)}"
      result = Dependencies.add_dependency(name, "1.0.0", "python")

      assert {:ok, dep} = result
      assert dep.name == name
      assert dep.language == "python"
    end

    test "updates existing dependency" do
      name = "test_js_dep_update_#{:rand.uniform(999_999)}"
      {:ok, _} = Dependencies.add_dependency(name, "1.0.0", "javascript")

      {:ok, updated} = Dependencies.add_dependency(name, "2.0.0", "javascript")
      assert updated.version == "2.0.0"
    end
  end
end
