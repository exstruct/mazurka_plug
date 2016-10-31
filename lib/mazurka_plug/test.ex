defmodule Mazurka.Plug.Test do
  defmodule AffordanceProxy do
    use Mazurka.Resource
    use Mazurka.Plug

    mediatype Hyper do
      provides "application/json"

      action do
        resource = var!(conn).private.mazurka_affordance_test_resource
        link_to(resource, Params.get(), Input.get())
      end
    end
  end

  defmacro __using__(opts) do
    router = Keyword.fetch!(opts, :router)
    resource = Keyword.fetch!(opts, :resource)
    quote do
      @router unquote(router)
      use Fugue, plug: @router
      import Fugue.Assertions, except: [assert_transition: 2, refute_transition: 2]
      import unquote(__MODULE__)
      require unquote(resource)
      @resource unquote(resource)

      defp prepare_request(conn, _context) do
        {method, path_info} = @router.resolve(@resource, conn.private[:mazurka_test_params] || %{})

        request_path = "/" <> Enum.join(path_info, "/")
        body = conn.private[:mazurka_test_body]

        conn
        |> Plug.Adapters.Test.Conn.conn(method, request_path, body)
        |> Map.put(:remote_ip, conn.remote_ip || {127, 0, 0, 1})
        |> Map.put(:query_string, conn.private[:mazurka_test_query] || "")
      end
      defoverridable [prepare_request: 2]
    end
  end

  defmacro affordance(body \\ [do: nil]) do
    quote do
      conn = request(unquote(body))

      conn
      |> Plug.Conn.put_private(:mazurka_affordance_test_resource, @resource)
      |> Plug.Conn.put_private(:mazurka_route, Mazurka.Plug.Test.AffordanceProxy)
      |> Map.put(:params, conn.private[:mazurka_test_params] || %{})
    end
  end

  defmacro params(params) do
    quote do
      conn = var!(conn)
      params = Enum.into(unquote(params), %{})
      params = Mazurka.Router.format_params(@router, params, %{}, conn)
      var!(conn) = Plug.Conn.put_private(conn, :mazurka_test_params, params)
    end
  end

  defmacro query(input) do
    quote do
      conn = var!(conn)
      var!(conn) =
        case unquote(input) do
          input when is_map(input) ->
            input = Mazurka.Router.format_params(@router, input, %{}, conn)
            Plug.Conn.put_private(conn, :mazurka_test_query, URI.encode_query(input))
        end
    end
  end

  for call <- [:assert, :refute] do
    defmacro unquote(:"#{call}_transition")(conn, location) when is_binary(location) do
      call = unquote(call)
      quote do
        conn = unquote(conn)
        location = unquote(location)
        location =
          if location == :proplists.get_value("location", conn.resp_headers) || location =~ ~r|://| do
            location
          else
            %URI{scheme: to_string(conn.scheme || "http"), host: conn.host, port: conn.port, path: location} |> to_string()
          end

        ExUnit.Assertions.unquote(call)(:proplists.get_value("location", conn.resp_headers) == location)
        conn
      end
    end

    defmacro unquote(:"#{call}_transition")(conn, resource, params \\ Macro.escape(%{}), query \\ Macro.escape(%{}), fragment \\ nil) do
      call = unquote(call)

      resource = quote do
        r = unquote(resource)
        @router.resolve_module(r) || r
      end

      match = {:{}, [], [resource, params, query, fragment]}

      quote do
        conn = unquote(conn)

        actual =
          case :proplists.get_value("location", conn.resp_headers) do
            :undefined ->
              {nil, nil, nil, nil}
            transition ->
              transition = URI.parse(transition)
              [_ | path_info] = transition.path |> String.split("/")
              case @router.match("GET", path_info) do
                {module, params} ->
                  qs = URI.decode_query(transition.query || "")
                  {module, params, qs, transition.fragment}
                _ ->
                  {nil, nil, nil, nil}
              end
          end

        unquote(:"#{call}_term_match")(actual, unquote(match), "Expected transition to match")

        conn
      end
    end

    def unquote(:"#{call}_invalidates")(conn, _url) do
      ## TODO
      conn
    end
  end
end
