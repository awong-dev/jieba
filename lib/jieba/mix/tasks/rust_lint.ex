defmodule Mix.Tasks.RustLint do
  @moduledoc "The rust_lint mix task: `mix help rust_lint`"
  use Mix.Task

  @cargo_path "native/rustler_jieba/Cargo.toml"

  @shortdoc "Runs clippy and rustfmt on native."
  def run(args) do
    rust_fmt_cmd = "cargo fmt --manifest-path=#{@cargo_path} --all"
    rust_clippy_cmd = "cargo clippy --manifest-path=#{@cargo_path}"

    if Enum.member?(args, "--fix") do
      Mix.shell().cmd(rust_fmt_cmd)
      Mix.shell().cmd(rust_clippy_cmd)
    else
      Mix.shell().cmd("#{rust_fmt_cmd} -- --check")
      Mix.shell().cmd("#{rust_clippy_cmd} --fix --allow-dirty")
    end
  end
end
