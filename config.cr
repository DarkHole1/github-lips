require "json"

class Config
  include JSON::Serializable

  getter github : GithubConfig
  getter telegram : TelegramConfig
end

class GithubConfig
  include JSON::Serializable

  getter user : String
  getter token : String
end

class TelegramConfig
  include JSON::Serializable

  getter token : String
  getter channel : Int64
  getter best_channel : Int64
end
