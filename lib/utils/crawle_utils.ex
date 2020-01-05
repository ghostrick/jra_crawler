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
    refund = fetch_refund(document)

    %{detail: detail, ranking: ranking, refund: refund}
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

  # 払戻金リストから必要な情報を切り抜く
  def fetch_refund(document) do
    refund_document =
      document
      |> Floki.find(".refund_area")
      |> Enum.fetch!(0)

    trio = fetch_refund_item(refund_document, "trio")
    tierce = fetch_refund_item(refund_document, "tierce")
    umatan = fetch_refund_item(refund_document, "umatan")
    umaren = fetch_refund_item(refund_document, "umaren")
    wide = fetch_refund_item(refund_document, "wide", multiple: true)

    %{trio: trio, wide: wide, tierce: tierce, umaren: umaren, umatan: umatan}
  end

  # 払戻金リストのli要素から必要な情報を切り抜く
  defp fetch_refund_item(document, class, opts \\ []) do
    resp =
      document
      |> Floki.find("li.#{class} .line")
      |> Enum.map(fn {_tag, _attr, children} -> children end)
      |> Enum.map(fn items -> items end)
      |> Enum.map(fn [number, fee, popular_rank] ->
        %{
          number: text(number),
          fee: Regex.replace(~r/円|,/, fee |> text(), "") |> to_integer(),
          popular_rank: text(popular_rank, deep: false) |> to_integer()
        }
      end)

    if opts[:multiple],
      do: resp,
      else: Enum.fetch!(resp, 0)
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
