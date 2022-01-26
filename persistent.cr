require "json"

class Persistent(T)
  @obj : T
  forward_missing_to @obj

  def initialize(filename : String)
    if File.exists? filename
      @obj = T.from_json File.read(filename)
    else
      @obj = T.new
    end

    at_exit {
      File.write filename, @obj.to_json
    }
  end
end
