defmodule FusionFlow.AI do
  def stream_text(messages, opts \\ []) do
    model = Keyword.get(opts, :model, System.get_env("OPENAI_MODEL") || "gpt-4o-mini")
    system = Keyword.get(opts, :system)
    temperature = Keyword.get(opts, :temperature)

    messages =
      if is_list(messages) and system do
        [%{role: "system", content: system} | messages]
      else
        messages
      end

    payload =
      %{
        model: model,
        messages: messages,
        stream: true,
        temperature: temperature
      }
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    stream =
      Stream.resource(
        fn ->
          parent = self()
          ref = make_ref()

          spawn_link(fn ->
            Req.post!(
              "https://api.openai.com/v1/chat/completions",
              auth: {:bearer, System.get_env("OPENAI_API_KEY")},
              json: payload,
              finch: FusionFlow.Finch,
              into: fn {:data, chunk}, acc ->
                send(parent, {:chunk, ref, chunk})
                {:cont, acc}
              end
            )

            send(parent, {:done, ref})
          end)

          %{ref: ref, buffer: ""}
        end,
        fn state ->
          receive do
            {:chunk, ref, chunk} when ref == state.ref ->
              {deltas, new_buffer} = parse_sse(state.buffer <> chunk)
              {deltas, %{state | buffer: new_buffer}}

            {:done, ref} when ref == state.ref ->
              {:halt, state}
          after
            30_000 -> {:halt, state}
          end
        end,
        fn _ -> :ok end
      )

    {:ok, %{stream: stream}}
  end

  defp parse_sse(buffer) do
    if String.contains?(buffer, "\n") do
      lines = String.split(buffer, "\n")
      {complete, [pending]} = Enum.split(lines, -1)

      deltas =
        complete
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&String.starts_with?(&1, "data: "))
        |> Enum.map(&String.replace(&1, "data: ", ""))
        |> Enum.reject(&(&1 == "[DONE]"))
        |> Enum.map(fn json ->
          case Jason.decode(json) do
            {:ok, %{"choices" => [%{"delta" => %{"content" => content}}]}}
            when is_binary(content) ->
              {:text_delta, content}

            _ ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      {deltas, pending}
    else
      {[], buffer}
    end
  end
end
