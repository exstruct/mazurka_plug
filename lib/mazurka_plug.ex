defmodule Mazurka.Plug do
  defmacro __using__(opts) do
    router_key = opts[:router_key] || :mazurka_router
    plug_init = Keyword.get(opts, :plug_init, true)
    serialize = Keyword.get(opts, :serialize, &__MODULE__.serialize/2)

    quote do
      unquote(if plug_init do
        quote do
          @before_compile unquote(__MODULE__)
          use Plug.Builder
        end
      end)

      @doc false
      def action(conn, opts) when is_list(opts) do
        action(conn, :maps.from_list(opts))
      end
      def action(%{private: private} = conn, opts) when is_map(opts) do
        import Mazurka.Plug.Helpers
        accepts = get_accepts(conn)
        {params, input, conn} = get_params(conn)
        router = Map.get(private, unquote(router_key))

        {body, content_type, conn} =
          action(accepts, params, input, conn, router, opts)

        conn
        |> handle_body(body, content_type, unquote(serialize))
        |> handle_transition()
        |> handle_invalidation()
        |> handle_response()
      rescue
        err in [Mazurka.UnacceptableContentTypeException,
                Mazurka.ConditionException,
                Mazurka.ValidationException,
                Mazurka.MissingParametersException,
                Mazurka.MissingRouterException] ->
        %{conn: conn} = err
        Plug.Conn.WrapperError.reraise(conn, :error, err)
      end

      def send_resp(conn, _opts) do
        Plug.Conn.send_resp(conn)
      end

      defoverridable [action: 2, send_resp: 2]
    end
  end

  def serialize({"application", "json", _}, body) do
    Poison.encode_to_iodata!(body)
  end
  def serialize({"text", "html", _}, body) when is_tuple(body) do
    HTMLBuilder.encode_to_iodata!(body)
  end
  def serialize({"text", _, _}, body) do
    body
  end

  def update_affordance(%{path: path} = affordance,
                        %{host: host, port: port, scheme: scheme, script_name: sn}) do
    %{affordance |
       host: host,
       port: port,
       scheme: to_string(scheme),
       path: format_path(sn, path)}
  end

  defp format_path([], path) do
    path
  end
  defp format_path(_, nil) do
    nil
  end
  defp format_path(sn, path) when is_list(path) do
    "/" <> (Stream.concat(sn, path) |> Enum.join("/"))
  end
  defp format_path(sn, "/" <> _ = path) do
    "/" <> (Enum.join(sn, "/")) <> path
  end

  defmacro __before_compile__(_) do
    quote do
      if !Enum.member?(@plugs, {:action, [], true}) do
        require Plug.Builder
        Plug.Builder.plug :action
      end

      if !Enum.member?(@plugs, {:send_resp, [], true}) do
        require Plug.Builder
        Plug.Builder.plug :send_resp
      end
    end
  end
end

defimpl Mazurka.Conn, for: Plug.Conn do
  def transition(%{private: private} = conn, affordance) do
    private = Map.put(private, :mazurka_transition, affordance)
    %{conn | private: private}
  end

  def invalidate(%{private: private} = conn, affordance) do
    private = Map.update(private, :mazurka_invalidations, [affordance], &[affordance | &1])
    %{conn | private: private}
  end
end

defimpl Plug.Exception, for: Mazurka.UnacceptableContentTypeException do
  def status(_) do
    406
  end
end

defimpl Plug.Exception, for: Mazurka.ConditionException do
  def status(_) do
    401
  end
end

defimpl Plug.Exception, for: Mazurka.ValidationException do
  def status(_) do
    400
  end
end

defimpl Plug.Exception, for: [Mazurka.MissingParametersException,Mazurka.MissingRouterException] do
  def status(_) do
    500
  end
end
