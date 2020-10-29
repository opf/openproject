class Gon
  module JsonDumper
    # Taken from ERB::Util
    JSON_ESCAPE_REGEXP	=	/[\u2028\u2029&><]/u
    JSON_ESCAPE	=	{
      "&" => '\u0026',
      ">" => '\u003e',
      "<" => '\u003c',
      "\u2028" => '\u2028',
      "\u2029" => '\u2029'
    }

    def self.dump(object)
      dumped_json = MultiJson.dump object,
        mode: :compat, escape_mode: :xss_safe, time_format: :ruby
      escape(dumped_json)
    end

    def self.escape(json)
      json.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
    end
  end
end
