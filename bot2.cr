require "tourmaline"
require "./code_search_api"
require "./config"
require "./utils"

config = Config.from_json(File.read("./config.json"))
api = CodeSearch::API.new config.github.user, config.github.token
bot = Tourmaline::Client.new bot_token: config.telegram.token

images_for_sending = fetch(api, config)
  .throttle(90.seconds)
  .flatten
  .reject_duplicates
  .map { |x| image_to_message x }
  .each_slice(10)
  .throttle(60.seconds)

loop do
  images = images_for_sending.next
  break if images.is_a? Iterator::Stop

  ::Log.info { "Starting sending #{images.size}" }
  begin
    bot.send_media_group(config.telegram.channel, images)
  rescue e
    ::Log.error(exception: e) { "Can't send :(" }
  end
  ::Log.info { "Sent some images #{images.size}" }
end
