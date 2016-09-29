defmodule Mazurka.Plug do
  @missing_router __MODULE__.UNDEFINED

  defmacro __using__(opts) do
    router = opts[:router] || @missing_router
    router_key = opts[:router_key] || :mazurka_router

    quote do
      @behaviour Plug

      def init(opts) when is_list(opts) do
        opts
        |> :maps.from_list()
        |> init()
      end
      def init(opts) when is_map(opts) do
        opts =
          %{router: unquote(router),
            router_key: unquote(router_key)}
          |> Map.merge(opts)

        {%{router: router,
           router_key: router_key}, opts} =
          Map.split(opts, [:router, :router_key])

        {router, router_key, opts}
      end

      def call(%{private: private} = conn, {unquote(@missing_router), router_key, opts}) do
        router = Map.get(private, router_key)
        call(conn, {router, router_key, opts})
      end
      def call(%{private: private} = conn, {router, router_key, opts}) do
        import Mazurka.Plug.Helpers
        accepts = get_accepts(conn)
        {params, input, conn} = get_params(conn)

        {body, content_type, conn} =
          action(accepts, params, input, conn, router, opts)

        conn
        |> handle_body(body, content_type)
        |> handle_transition()
        |> handle_invalidation()
        |> handle_response()
        |> Plug.Conn.send_resp()
      rescue
        err in [Mazurka.UnacceptableContentTypeException,
                Mazurka.ConditionException,
                Mazurka.ValidationException,
                Mazurka.MissingParametersException,
                Mazurka.MissingRouterException] ->
          %{conn: conn} = err
          Plug.Conn.WrapperError.reraise(conn, :error, err)
      end

      defoverridable [init: 1, call: 2]
    end
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
