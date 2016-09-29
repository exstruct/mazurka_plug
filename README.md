# mazurka_plug

[Plug](https://github.com/elixir-lang/plug) integration for [Mazurka](https://github.com/extruct/mazurka).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `mazurka_plug` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:mazurka_plug, "~> 0.1.0"}]
    end
    ```

## Usage

Just use the `Mazurka.Plug` alongside `Mazurka.Router` to give it the standard `Plug` behaviour.

```elixir
defmodule MyApp.Resource do
  use Mazurka.Resource
  use Mazurka.Plug

  param name

  mediatype Hyper do
    action do
      %{
        "hello" => name
      }
    end
  end
end
```

We can now call it just like any other "plug"

```elixir
opts = MyApp.Resource.init([])
MyApp.Resource.call(conn, opts)
```
