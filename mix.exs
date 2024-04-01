defmodule Jieba.MixProject do
  use Mix.Project

  @source_url "https://github.com/awong-dev/jieba"
  # Note, release.yml uses a regexp to parse the version from this line.
  @version "0.3.0"

  def project do
    [
      app: :jieba,
      version: @version,
      elixir: "~> 1.7",
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:rustler, "~> 0.31.0", runtime: false},
      {:rustler_precompiled, "~> 0.7.1"}
    ]
  end

  defp description() do
    """
    Elixir API to Rust Jieba-RS Chinese segmenter.
    """
  end

  defp package() do
    [
      description: "Rustler wrapper for the jieba_rs Chiense segmenter",
      maintainers: ["Albert J. Wong"],
      exclude_patterns: [
        ~r/.*~$/,
        ~r/.*\.swp$/,
        ~r/.*\.swo$/,
        ~r/lib\/jieba\/mix\/.*$/,
        ~r/native\/rustler_jieba\/target\/.*$/
      ],
      files: [
        ".formatter.exs",
        "CHANGELOG.md",
        "LICENSE",
        "README.md",
        "checksum-*.exs",
        "lib",
        "mix.exs",
        "mix.lock",
        "native"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "Jieba",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/jieba",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md", "LICENSE"]
    ]
  end
end
