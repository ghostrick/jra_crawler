defmodule JraCrawler do
  alias JraCrawler.{CrawlUtils, SaveUtils}

  def run(year) do
    g1_urls = CrawlUtils.fetch_race_urls(year, "g1")
    jyusyo_urls = CrawlUtils.fetch_race_urls(year, "jyusyo")

    urls =
      jyusyo_urls
      |> Enum.concat(g1_urls)
      |> Enum.uniq()

    urls
    |> Enum.map(fn url ->
      IO.inspect("fetch #{url}")
      CrawlUtils.fetch_race(url)
    end)
    |> SaveUtils.save(year)
  end
end
