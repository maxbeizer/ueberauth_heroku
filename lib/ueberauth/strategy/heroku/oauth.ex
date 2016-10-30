defmodule Ueberauth.Strategy.Heroku.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Heroku.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.Heroku.OAuth,
        client_id: System.get_env("HEROKU_CLIENT_ID"),
        client_secret: System.get_env("HEROKU_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://id.heroku.com",
    authorize_url: "https://id.heroku.com/oauth/authorize",
    token_url: "https://id.heroku.com/oauth/token",
  ]

  @doc """
  Construct a client for requests to Heroku.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.Heroku.OAuth.client(redirect_uri: "http://localhost:4000/auth/heroku/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.Heroku`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    opts = Keyword.merge(@defaults, Application.get_env(:ueberauth, Ueberauth.Strategy.Heroku.OAuth))
    |> Keyword.merge(opts)

    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    client(opts)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], options \\ %{}) do
    headers = Dict.get(options, :headers, [])
    options = Dict.get(options, :options, [])
    client_options = Dict.get(options, :client_options, [])
    OAuth2.Client.get_token!(client(client_options), params, headers, options)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
