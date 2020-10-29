require 'json'
require 'time'

module MessageBird
  class Base
    def initialize(json)
      json.each do |k,v|
        begin
          send("#{k}=", v)
        rescue NoMethodError
          # Silently ignore parameters that are not supported.
        end
      end
    end

    def value_to_time(value)
      value ? Time.parse(value) : nil
    end
  end
end
