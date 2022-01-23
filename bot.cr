require "tourmaline"
require "tourmaline/extra/format"
require "tasker"
require "./code_search_api"

include Tourmaline::Format
TLink = Tourmaline::Format::Link

api = CodeSearch::API.new ENV["GH_USER"], ENV["GH_TOKEN"]
CHANNEL = ENV["CHANNEL"].to_i64

bot = Tourmaline::Client.new bot_token: ENV["BOT_TOKEN"]

schedule = Tasker.instance
schedule.every(30.seconds) do
  ::Log.info { "Posting to channel" }
  result = api.search "extension:jpg extension:png", per_page: 1, sort: "indexed"
  case result
  when CodeSearch::Result
    image = result.items[0]
    caption = Section.new(
      TLink.new("original image", image.html_url),
      TLink.new("repository", image.repository.html_url),
      indent: 0
    )
    bot.send_photo(CHANNEL, image.raw_url, caption: caption.to_md)
  else
    ::Log.warn { "Error with API: #{result}" }
  end
end

bot.poll
