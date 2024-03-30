defmodule Jieba.MixProject do
  use Mix.Project

  @source_url "https://github.com/awong-dev/jieba"
  @version "0.1.0"

  def project do
    [
      app: :jieba,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.31.0",  runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp description() do
    """
    Elixir API to Rust Jieba-RS Chinese segmenter.
    """
  end

  defp package() do
    [
      maintainers: ["Albert J. Wong"],
      files: ["lib", ".formatter.exs", "mix.exs", "mix.lock", "README.md", "LICENSE*", "native"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "Jieba-RS",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/jason",
      source_url: @source_url,
      extras: ["README.md", "LICENSE"]
    ]
  end
end
