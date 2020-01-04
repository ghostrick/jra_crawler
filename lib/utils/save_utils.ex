defmodule JraCrawler.SaveUtils do
  def save(map, year) do
    file_name = "jra-#{year}.json"

    File.write("output/#{file_name}", Poison.encode!(map, indent: 2, pretty: true))
  end
end
