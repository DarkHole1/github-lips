require "tourmaline"
require "./config.cr"

CONFIG = Config.from_json(File.read("./config.json"))

class Listener < Tourmaline::Client
    @[On(:photo)]
    def check_photo(ctx)
        msg = ctx.message
        return unless ctx.forwarded_message?
        return if msg.nil?
        chat = msg.forward_from_chat
        msg_id = msg.forward_from_message_id
        return if chat.nil?
        return if chat.id != CONFIG.telegram.channel
        # TODO: Don't send twice based on msg_id
        # TODO: Forward album
        msg.forward(CONFIG.telegram.best_channel)
    end
    
    # Maybe someday there will be api for forwarding media groups... But not today.
    # https://github.com/tdlib/telegram-bot-api/issues/297
    # @[On(:media_group)]
    # def forward_group(ctx)
    #     WTF
    # end
end

bot = Listener.new(bot_token: CONFIG.telegram.token)
bot.poll