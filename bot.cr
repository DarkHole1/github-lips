require "tourmaline"
require "tourmaline/extra/format"
require "tasker"
require "./code_search_api"

include Tourmaline::Format
TLink = Tourmaline::Format::Link

api = CodeSearch::API.new ENV["GH_USER"], ENV["GH_TOKEN"]
CHANNEL = ENV["CHANNEL"].to_i64

bot = Tourmaline::Client.new bot_token: ENV["BOT_TOKEN"]
sent_images_hashes = Set(String).new

schedule = Tasker.instance
schedule.every(30.seconds) do
  ::Log.info { "Posting to channel" }
  result = api.search "extension:jpg extension:png size:>1000", per_page: 100, sort: "indexed"
  case result
  when CodeSearch::Result
    ::Log.info { "Get #{result.items.size} images" }
    images = Array(Tourmaline::InputMediaPhoto).new
    result.items.each { |image|
      if sent_images_hashes.includes? image.sha
        next
      end
      sent_images_hashes << image.sha

      caption = Section.new(
        TLink.new("original image", image.html_url),
        TLink.new("repository", image.repository.html_url),
        indent: 0
      )
      # bot.send_photo(CHANNEL, image.raw_url, caption: caption.to_html, parse_mode: :html)
      images << Tourmaline::InputMediaPhoto.new(image.raw_url, caption: caption.to_html, parse_mode: :html)
    }
    if images.size > 0
      ::Log.info { "Sending #{images.size} photos" }
      bot.send_media_group(CHANNEL, images)
    end
  else
    ::Log.warn { "Error with API: #{result}" }
  end
end

bot.poll
