defmodule MazurkaPlugTest do
  use ExUnit.Case
  use Plug.Test

  defmodule Resource do
    use Mazurka.Resource
    use Mazurka.Plug

    param foo
    input bar

    condition foo != "foo", "Foo can't be 'foo'"
    validation foo != "baz"

    mediatype Hyper do
      action do
        %{
          "foo" => foo,
          "bar" => if bar == "link_to" do
            link_to(__MODULE__, foo: "bang")
          else
            bar
          end
        }
      end
    end

    mediatype HTML do
      action do
        {"div", %{}, [
          foo,
          " ",
          bar
        ]}
      end
    end
  end

  @opts Resource.init([])

  test "success json" do
    conn(:get, "/")
    |> put_params(%{"foo" => "bar"})
    |> Resource.call(@opts)
  end

  test "success input json" do
    conn(:get, "/")
    |> Map.put(:query_string, "bar=123")
    |> put_params(%{"foo" => "456"})
    |> Resource.call(@opts)
  end

  test "success html" do
    conn(:get, "/")
    |> put_req_header("accept", "text/html")
    |> put_params(%{"foo" => "bar"})
    |> Resource.call(@opts)
  end

  test "success input" do
    conn(:get, "/")
    |> put_req_header("accept", "text/html")
    |> Map.put(:query_string, "bar=123")
    |> put_params(%{"foo" => "456"})
    |> Resource.call(@opts)
  end

  test "unacceptable content type" do
    assert_raise Plug.Conn.WrapperError, fn ->
      conn(:get, "/")
      |> put_req_header("accept", "foo/bar")
      |> put_params(%{"foo" => "not_gunna_happen"})
      |> Resource.call(@opts)
    end
  end

  test "condition exception" do
    assert_raise Plug.Conn.WrapperError, fn ->
      conn(:get, "/")
      |> put_params(%{"foo" => "foo"})
      |> Resource.call(@opts)
    end
  end

  test "validation exception" do
    assert_raise Plug.Conn.WrapperError, fn ->
      conn(:get, "/")
      |> put_params(%{"foo" => "baz"})
      |> Resource.call(@opts)
    end
  end

  test "missing params exception" do
    assert_raise Plug.Conn.WrapperError, fn ->
      conn(:post, "/")
      |> put_params(%{})
      |> Resource.call(@opts)
    end
  end

  test "missing router exception" do
    assert_raise Plug.Conn.WrapperError, fn ->
      conn(:get, "/")
      |> Map.put(:query_string, "bar=link_to")
      |> put_params(%{"foo" => "bar"})
      |> Resource.call(@opts)
    end
  end

  defp put_params(conn, params) do
    %{conn | params: params}
  end
end
