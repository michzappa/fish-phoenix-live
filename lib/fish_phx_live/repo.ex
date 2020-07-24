defmodule FishPhxLive.Repo do
  use Ecto.Repo,
    otp_app: :fish_phx_live,
    adapter: Ecto.Adapters.Postgres
end
