require "json"

class Config
  include JSON::Serializable

  getter github : GithubConfig
  getter telegram : TelegramConfig
  getter general : GeneralConfig
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

class GeneralConfig
  include JSON::Serializable

  getter duplicates : Bool
  getter search : String
  getter results : Int32
end
