defmodule UeberauthHeroku.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :ueberauth_heroku,
      version: @version,
      name: "Ueberauth Heroku",
      package: package(),
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      source_url:   "https://github.com/maxbeizer/ueberauth_heroku",
      homepage_url: "https://github.com/maxbeizer/ueberauth_heroku",
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [
      applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.6"},
      {:oauth2, "~>2.0"},

      # docs dependencies
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"]
    ]
  end

  defp description do
    "An Ueberauth strategy for using Heroku to authenticate your users."
  end

  defp package do
    [
      files: [
        "lib", "mix.exs", "README.md", "LICENSE"
      ],
      maintainers: ["Max Beizer"],
      licenses: ["MIT"],
      links: %{"GitHub": "https://github.com/maxbeizer/ueberauth_heroku"}
    ]
  end
end
