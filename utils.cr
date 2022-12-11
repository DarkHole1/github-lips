require "./code_search_api"
require "tourmaline/extra/format"

include Tourmaline::Format
TLink = Tourmaline::Format::Link

alias Image = CodeSearch::ResultItem

module Iterator(T)
  class RejectDuplicates
    include Iterator(Image)

    def initialize(@it : Iterator(Image), @max_cache_size : Int32)
      @cache = Set(String).new
    end

    def next
      case value = @it.next
      when Image
        if @cache.includes? value.sha
          self.next
        else
          @cache.add value.sha
          if @cache.size > @max_cache_size
            @cache.clear
          end
          value
        end
      else
        stop
      end
    end
  end

  def reject_duplicates(max_cache_size = 100_000)
    RejectDuplicates.new(self, max_cache_size)
  end

  class ThrottleIterator(T)
    include Iterator(T)

    def initialize(@it : Iterator(T), @time_span : Time::Span)
      ::Log.info { "Throttle was created" }
      @time_last = Time::Span.new
    end

    def next
      ::Log.info { "Throttle was called" }
      now = Time.monotonic
      diff = now - @time_last
      ::Log.info { "Now: #{now} start: #{@time_last} diff #{diff}" }
      if diff <= @time_span
        time_to_sleep = @time_span - diff
        ::Log.info { "Gonna sleep for #{time_to_sleep}" }
        sleep(time_to_sleep)
      end
      @time_last = Time.monotonic
      ::Log.info { "Last time now should be #{@time_last}" }
      ::Log.info { "Calling next from throttle" }
      @it.next
    end
  end

  def throttle(time_span)
    ThrottleIterator.new(self, time_span)
  end
end

class ImageIterator
  include Iterator(Array(Image))

  def initialize(@api : CodeSearch::API, @config : Config)
  end

  def next
    ::Log.info { "Fetch was called" }
    # ::Log.info { "Posting to channel" }
    begin
      result = @api.search @config.general.search, per_page: @config.general.results, sort: "indexed"
    rescue e
      ::Log.error(exception: e) { "Can't search :(" }
    end

    case result
    when CodeSearch::Result
      ::Log.info { "Fetched #{result.items.size} images" }
      result.items
    else
      if result.is_a? CodeSearch::Forbidden
        ::Log.warn { "Error with API: #{result.message}" }
      else
        ::Log.warn { "Error with API: #{result}" }
      end
      sleep(60.seconds)
      self.next
    end
  end
end

def fetch(api : CodeSearch::API, config : Config)
  ImageIterator.new(api, config)
end

def image_to_message(image : Image)
  caption = Section.new(
    TLink.new("original image", image.html_url),
    TLink.new("repository", image.repository.html_url),
    indent: 0
  )
  Tourmaline::InputMediaPhoto.new(image.raw_url, caption: caption.to_html, parse_mode: Tourmaline::ParseMode::HTML)
end
