require "http/client"
require "json"

module CodeSearch
  class API
    Log      = ::Log.for(self)
    API_HOST = "api.github.com"
    HEADERS  = HTTP::Headers{
      "Accept"     => "application/vnd.github.v3+json",
      "User-Agent" => "Last Indexed Picture",
    }

    @client : HTTP::Client

    def initialize(user : String, token : String)
      @client = HTTP::Client.new API_HOST, tls: true
      @client.basic_auth(user, token)
    end

    def search(q : String, sort : String? = nil, order : String? = nil, per_page : Int? = nil, page : Int? = nil)
      path = URI.new(
        path: "/search/code",
        query: URI::Params.build { |form|
          form.add "q", q
          form.add "sort", sort if !sort.nil?
          form.add "order", order if !order.nil?
          form.add "per_page", per_page.to_s if !per_page.nil?
          form.add "page", page.to_s if !page.nil?
        }
      )
      response = @client.get path.to_s, headers: HEADERS

      case response.status
      when .ok?
        Result.from_json response.body
      when .not_modified?
        # Note: there isn't body at docs
        NotModified.new
      when .service_unavailable?
        ServiceUnavailable.from_json response.body
      when .unprocessable_entity?
        ValidationFailed.from_json response.body
      when .forbidden?
        Forbidden.from_json response.body
      else
        Error.new
      end
    end
  end

  class Result
    include JSON::Serializable

    property total_count : Int64
    property incomplete_results : Bool
    property items : Array(ResultItem)
  end

  class ResultItem
    include JSON::Serializable

    property score : Float64
    property name : String
    property path : String
    property sha : String
    property git_url : String
    property html_url : String
    property url : String 
    property repository : MinimalRepository

    def raw_url
      URI.parse(@html_url).tap { |uri|
        uri.host = "raw.githubusercontent.com"
        uri.path = uri.path.sub("/blob/", "/")
      }.to_s
    end
  end

  class MinimalRepository
    include JSON::Serializable

    # TODO: Add all fields
    property name : String
    property full_name : String
    property html_url : String
  end

  class Error
  end

  class NotModified < Error
  end

  class ServiceUnavailable < Error
    include JSON::Serializable

    getter code : String
    getter message : String
    getter documentation_url : String
  end

  class ValidationFailed < Error
    include JSON::Serializable

    # TODO: Implement all fields
    getter message : String
    getter documentation_url : String
  end

  class Forbidden < Error
    include JSON::Serializable

    # TODO: Implement all fields
    getter message : String
    getter documentation_url : String
  end
end
