# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :fish_phx_live,
  ecto_repos: [FishPhxLive.Repo]

# Configures the endpoint
config :fish_phx_live, FishPhxLiveWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Rd4X/YtqC3Z60ghaAUmmiM6xCCk7Q2kQ1BYA8s5py56JuIaLcMQZ+EuAeOrammkm",
  render_errors: [view: FishPhxLiveWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: :fish_pubsub,
  live_view: [signing_salt: "F1jHEDnF"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
