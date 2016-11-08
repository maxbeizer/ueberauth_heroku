defmodule Ueberauth.Strategy.Heroku do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Heroku.

  ### Setup

  Create an application in Heroku for you to use.

  Register a new application at: [your heroku developer page](https://heroku.com/settings/developers) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          heroku: { Ueberauth.Strategy.Heroku, [] }
        ]

  Then include the configuration for heroku.

      config :ueberauth, Ueberauth.Strategy.Heroku.OAuth,
        client_id: System.get_env("HEROKU_CLIENT_ID"),
        client_secret: System.get_env("HEROKU_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          heroku: { Ueberauth.Strategy.Heroku, [default_scope: "identity,read"] }
        ]

  Deafult is "identity"
  """
  @heroku_api_account_url "https://api.heroku.com/account"
  use Ueberauth.Strategy, default_scope: "identity",
                          oauth2_module: Ueberauth.Strategy.Heroku.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the heroku authentication page.

  To customize the scope (permissions) that are requested by Heroku include them as part of your url:

      "/auth/heroku?scope=global"

  You can also include a `state` param that Heroku will return to you.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Heroku. When there is a failure from Heroku the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Heroku is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Heroku response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:heroku_user, nil)
    |> put_private(:heroku_token, nil)
  end

  @doc """
  Fetches the uid field from the Heroku response, which is `email` for Heroku.
  """
  def uid(conn) do
    conn.private.heroku_user["email"]
  end

  @doc """
  Includes the credentials from the Heroku response.
  """
  def credentials(conn) do
    token = conn.private.heroku_token
    scopes = (token.other_params["scope"] || "")
    |> String.split(",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.heroku_user

    %Info{
      name: user["name"],
      email: user["email"],
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Heroku callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.heroku_token,
        user: conn.private.heroku_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :heroku_token, token)
    case OAuth2.AccessToken.get(token, @heroku_api_account_url) do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :heroku_user, user)
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end
end
