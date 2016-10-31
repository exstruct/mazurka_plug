defmodule Test.Mazurka.Plug.Test.Subject do
  defmodule Resource do
    use Mazurka.Resource
    use Mazurka.Plug

    mediatype Hyper do
      action do
        %{
          "hello" => "world"
        }
      end
    end
  end

  defmodule Router do
    use Plug.Builder

    plug Resource

    def resolve(_resource, params) do
      {"GET", ["param", params[:param]]}
    end
  end
end

defmodule Test.Mazurka.Plug.Test do
  alias __MODULE__.Subject
  use Mazurka.Plug.Test, router: Subject.Router,
                         resource: Subject.Resource

  test "action" do
    request do
      params param: "bar"
    end
  after conn ->
    conn
    |> assert_status(200)
  end

  test "affordance" do
    affordance do
      params param: "foo"
    end
  after _conn ->
    :ok
  end
end
