require "tourmaline"
require "tourmaline/extra/format"
require "tasker"
require "./code_search_api"

include Tourmaline::Format
TLink = Tourmaline::Format::Link

api = CodeSearch::API.new ENV["GH_USER"], ENV["GH_TOKEN"]
CHANNEL = ENV["CHANNEL"].to_i64

bot = Tourmaline::Client.new bot_token: ENV["BOT_TOKEN"]
sent_images_hashes = Set(String).from_json(File.read("sent_image_hashes.json"))

at_exit {
  File.write("sent_image_hashes.json", sent_images_hashes.to_json)
}

def task(api, sent_images_hashes, bot)
  ::Log.info { "Posting to channel" }
  begin
    result = api.search "extension:jpg extension:png size:>5000", per_page: 100, sort: "indexed"
  rescue e
    ::Log.error(exception: e) { "Can't search :(" }
  end

  case result
  when CodeSearch::Result
    ::Log.info { "Get #{result.items.size} images" }
    images = Array(Tourmaline::InputMediaPhoto).new
    result.items.each { |image|
      next if sent_images_hashes.includes? image.sha
      sent_images_hashes << image.sha

      caption = Section.new(
        TLink.new("original image", image.html_url),
        TLink.new("repository", image.repository.html_url),
        indent: 0
      )
      images << Tourmaline::InputMediaPhoto.new(image.raw_url, caption: caption.to_html, parse_mode: Tourmaline::ParseMode::HTML)
    }
    if images.size > 0
      ::Log.info { "Sending #{images.size} photos" }
      images.each_slice(10) { |some_images|
        ::Log.info { "Starting sending #{some_images.size}" }
        begin
          bot.send_media_group(CHANNEL, some_images)
        rescue e
          ::Log.error(exception: e) { "Can't send :(" }
        end
        ::Log.info { "Sent some images #{some_images.size}" }
        sleep 60.seconds
      }
    end
  else
    ::Log.warn { "Error with API: #{result}" }
  end
end

task(api, sent_images_hashes, bot)

Tasker.every(5.minutes) do
  task(api, sent_images_hashes, bot)
end

bot.poll
