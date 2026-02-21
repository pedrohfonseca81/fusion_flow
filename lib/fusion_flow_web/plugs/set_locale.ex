defmodule FusionFlowWeb.Plugs.SetLocale do
  import Plug.Conn

  @supported_locales Gettext.known_locales(FusionFlowWeb.Gettext)

  def init(_options), do: nil

  def call(conn, _options) do
    locale =
      cond do
        locale_from_params = conn.params["locale"] ->
          if locale_from_params in @supported_locales, do: locale_from_params, else: nil

        locale_from_session = get_session(conn, :locale) ->
          if locale_from_session in @supported_locales, do: locale_from_session, else: nil

        true ->
          extract_from_header(get_req_header(conn, "accept-language"))
      end

    if locale do
      Gettext.put_locale(FusionFlowWeb.Gettext, locale)

      conn
      |> put_session(:locale, locale)
      |> assign(:locale, locale)
    else
      conn
      |> assign(:locale, Gettext.get_locale(FusionFlowWeb.Gettext))
    end
  end

  defp extract_from_header([header | _]) when is_binary(header) do
    header
    |> String.split(",")
    |> Enum.map(&String.split(&1, ";"))
    |> Enum.map(&List.first/1)
    |> Enum.map(&String.split(&1, "-"))
    |> Enum.map(&List.first/1)
    |> Enum.map(&String.trim/1)
    |> Enum.find(&(&1 in @supported_locales))
  end

  defp extract_from_header(_), do: nil

  # LiveView Hook
  def on_mount(:default, params, session, socket) do
    locale =
      cond do
        locale_from_params = params["locale"] ->
          if locale_from_params in @supported_locales, do: locale_from_params, else: nil

        locale_from_session = session["locale"] ->
          if locale_from_session in @supported_locales, do: locale_from_session, else: nil

        true ->
          nil
      end

    locale = locale || Gettext.get_locale(FusionFlowWeb.Gettext)
    Gettext.put_locale(FusionFlowWeb.Gettext, locale)
    {:cont, Phoenix.Component.assign(socket, :locale, locale)}
  end
end
