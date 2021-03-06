defmodule Redi.Mixfile do
  use Mix.Project

  def project do
    [ app: :redi,
      version: "0.0.9",
      elixir: "~> 0.10.3-dev",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    []
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    [
      { :exredis,"0.0.4",[github: "artemeff/exredis", tag: "v0.0.4"] }
    ]
  end
end
