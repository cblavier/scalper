defmodule Scalper.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link(
      [
        {Goth, name: Scalper.Goth, source: goth_source()}
      ],
      name: Scalper.Supervisor,
      strategy: :one_for_one
    )
  end

  defp goth_source do
    {:service_account, goth_credentials(),
     scopes: [
       "https://www.googleapis.com/auth/spreadsheets",
       "https://www.googleapis.com/auth/drive"
     ]}
  end

  defp goth_credentials do
    %{
      "type" => "service_account",
      "private_key" => System.fetch_env!("GOOGLE_PRIVATE_KEY") |> String.replace("\\n", "\n"),
      "client_email" => System.fetch_env!("GOOGLE_CLIENT_EMAIL"),
      "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
      "token_uri" => "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
      "universe_domain" => "googleapis.com"
    }
  end
end
