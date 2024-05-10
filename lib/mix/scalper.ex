defmodule Mix.Tasks.Scalper do
  use Mix.Task

  alias GoogleApi.Sheets.V4.Api.Spreadsheets
  alias GoogleApi.Sheets.V4.Connection
  alias GoogleApi.Sheets.V4.Model.{BatchUpdateValuesRequest, ValueRange}

  require Logger

  @user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

  @impl Mix.Task
  def run(_) do
    spreadsheet_id = System.get_env("SPREADSHEET_ID")
    Application.ensure_all_started(:scalper)

    {:ok, token} = Goth.fetch(Scalper.Goth)
    conn = Connection.new(token.token)

    {:ok, %ValueRange{values: [_header | urls]}} =
      Spreadsheets.sheets_spreadsheets_values_get(conn, spreadsheet_id, "C:D")

    urls
    |> Enum.with_index(2)
    |> Task.async_stream(
      fn {[url, unavailabity_text], row} ->
        unavailabity_text = unavailabity_text |> String.downcase() |> String.trim()

        case Req.get(url, user_agent: @user_agent) do
          {:ok, %Req.Response{status: status, body: body}} when status in [200, 201] ->
            unavailability =
              body
              |> Floki.parse_document!()
              |> Floki.text()
              |> decode()
              |> String.downcase()
              |> String.contains?(unavailabity_text)

            {:ok,
             %{
               row: row,
               status: status,
               availability: !unavailability,
               updated_at: now()
             }}

          {:ok, %Req.Response{status: status}} ->
            Logger.error("received #{status} from #{url}")
            {:error, %{row: row, status: status, updated_at: now()}}

          {:error, e} ->
            Logger.error("received #{inspect(e)} from #{url}")
            {:error, %{row: row, updated_at: now()}}
        end
      end,
      timeout: :infinity
    )
    |> Enum.filter(&(elem(&1, 0) == :ok))
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(fn {_, %{row: row}} -> row end)
    |> Enum.map(fn
      {:ok, %{row: row, status: status, availability: availability, updated_at: updated_at}} ->
        %ValueRange{range: "E#{row}:G#{row}", values: [[availability, updated_at, status]]}

      {:error, %{row: row, status: status, updated_at: updated_at}} ->
        %ValueRange{range: "F#{row}:G#{row}", values: [[updated_at, status]]}

      {:error, %{row: row, updated_at: updated_at}} ->
        %ValueRange{range: "F#{row}:G#{row}", values: [[updated_at, "unknown error"]]}
    end)
    |> values_batch_update(conn, spreadsheet_id)
  end

  defp decode(text) do
    case CharsetDetect.guess(text) do
      {:ok, "UTF-8"} -> text
      {:ok, "windows-1251"} -> :unicode.characters_to_binary(text, :latin1)
      {:ok, "windows-1252"} -> :unicode.characters_to_binary(text, :latin1)
    end
  end

  defp now do
    DateTime.now!("Europe/Paris") |> Calendar.strftime("%d/%m/%Y %H:%M:%S")
  end

  defp values_batch_update(data, conn, spreadsheetId) do
    request = %BatchUpdateValuesRequest{
      valueInputOption: "USER_ENTERED",
      data: data
    }

    {:ok, _} =
      Spreadsheets.sheets_spreadsheets_values_batch_update(conn, spreadsheetId, body: request)
  end
end
