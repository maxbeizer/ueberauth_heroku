# Ueberauth Heroku

> Heroku OAuth2 strategy for Ueberauth.

[tl;dr example repo](https://github.com/maxbeizer/ueberauth_heroku_example)

## Installation

1. Setup your application on [Heroku](https://www.heroku.com). There are three
   ways to register a client: 
  * [Dashboard (easiest)](https://dashboard.heroku.com/account/applications)
  * [heroku-oauth CLI plugin](https://github.com/heroku/heroku-cli-oauth)
  * [using the API directly](https://devcenter.heroku.com/articles/platform-api-reference#oauth-client)

1. Add `:ueberauth_heroku` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_heroku, "~> 0.1"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_heroku]]
    end
    ```

1. Add Heroku to your Ueberauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        heroku: {Ueberauth.Strategy.Heroku, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Heroku.OAuth,
      client_id: System.get_env("HEROKU_CLIENT_ID"),
      client_secret: System.get_env("HEROKU_CLIENT_SECRET")
    ```

1.  Include the Ueberauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth`
   and `Ueberauth.Failure` responses.

For an example implementation see the [Ueberauth Heroku
example](https://github.com/maxbeizer/ueberauth_heroku_example) application.

## Calling

Depending on the configured URL you can initial the request through:

    /auth/heroku

Or with options:

    /auth/heroku?scope=global

By default the requested scope is "identity" ([learn
more](https://devcenter.heroku.com/articles/oauth#scopes)). Scope can be
configured either explicitly as a `scope` query value on the request path or in
your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    heroku: {Ueberauth.Strategy.Heroku, [default_scope: "global"]}
  ]
```

## License

Please see [LICENSE](https://github.com/maxbeizer/ueberauth_heroku/blob/master/LICENSE) for licensing details.
