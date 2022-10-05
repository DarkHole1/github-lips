require "tourmaline"
require "tourmaline/extra/format"
require "tasker"
require "./code_search_api"
require "./config.cr"

include Tourmaline::Format
TLink = Tourmaline::Format::Link

config = Config.from_json(File.read("./config.json"))
api = CodeSearch::API.new config.github.user, config.github.token
bot = Tourmaline::Client.new bot_token: config.telegram.token

def task(api, bot, config, hashes)
  ::Log.info { "Posting to channel" }
  begin
    result = api.search "extension:jpg extension:png size:>5000", per_page: 20, sort: "indexed"
  rescue e
    ::Log.error(exception: e) { "Can't search :(" }
  end

  case result
  when CodeSearch::Result
    ::Log.info { "Get #{result.items.size} images" }
    images = Array(Tourmaline::InputMediaPhoto).new
    result.items.each { |image|
      next if hashes.includes? image.sha
      hashes << image.sha

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
          bot.send_media_group(config.telegram.channel, some_images)
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

hashes = Set(String).new

task(api, bot, config, hashes)
Tasker.every(2.minutes) do
  task(api, bot, config, hashes)
end

# bot.poll
