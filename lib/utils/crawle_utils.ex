defmodule JraCrawler.CrawlUtils do
  @base "http://www.jra.go.jp"

  # jyusyo | g1
  def build_list_url(year, type) do
    "#{@base}/datafile/seiseki/replay/#{year}/#{type}.html"
  end

  def fetch_race_urls(year, type) do
    list_url = build_list_url(year, type)

    %{body: body} = HTTPoison.get!(list_url)

    {:ok, document} = Floki.parse_document(body)

    document
    |> Floki.find("td.result > a")
    |> Floki.attribute("href")
  end

  def fetch_race(url) do
    %{body: body} = HTTPoison.get!(@base <> url)

    {:ok, document} = Floki.parse_document(body)

    ranking = fetch_ranking(document)
    detail = fetch_detail(document)

    %{detail: detail, ranking: ranking}
  end

  defp fetch_detail(document) do
    info_document =
      document
      |> Floki.find(".race_result_unit > table caption")
      |> Enum.fetch!(0)

    weather =
      info_document
      |> Floki.find("li.weather span.txt")
      |> text()

    field =
      info_document
      |> Floki.find("li.turf span.cap, li.durt span.cap")
      |> text()

    course =
      info_document
      |> Floki.find(".type .course")
      |> text(deep: false)
      |> (fn t -> Regex.replace(~r/,/, t, "") end).()
      |> to_integer()

    title =
      info_document
      |> Floki.find(".race_title h2")
      |> text()

    %{title: Regex.replace(~r/\s/, title, ""), course: course, field: field, weather: weather}
  end

  defp fetch_ranking(document) do
    document
    |> Floki.find(".race_result_unit > table tbody tr")
    |> Enum.map(fn node ->
      node
      |> Floki.find("td")
      |> Enum.map(fn item ->
        {
          item |> Floki.attribute("class") |> Enum.fetch!(0),
          item |> text()
        }
      end)
      |> Enum.map(fn {k, v} ->
        {transfer_key(k), v}
      end)
      |> Enum.map(fn {k, v} ->
        if k in ["horse_number", "popular_rank", "rank"],
          do: {k, to_integer(v)},
          else: {k, v}
      end)
      |> Enum.filter(fn {k, _} -> k != nil end)
      |> Enum.into(%{})
    end)
  end

  # 欲しい情報のkeyを適切に変換していらないものはnil
  defp transfer_key(key) do
    case key do
      "place" -> "rank"
      "num" -> "horse_number"
      "horse" -> "horse_name"
      "age" -> "horse_age"
      "jockey" -> "jockey_name"
      "time" -> "time"
      "trainer" -> "trainer_name"
      "pop" -> "popular_rank"
      _ -> nil
    end
  end

  # Floki.text のラッパー
  defp text(node, opt \\ []) do
    node
    |> Floki.text(opt)
    |> String.trim()
    # jraのページがshift-jisなのでutf-8に治す
    |> Mbcs.decode!(:cp932)
  end

  defp to_integer(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      _ -> nil
    end
  end
end
