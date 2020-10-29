module Rack
  module Utils
    def escape(url)
      EscapeUtils.escape_url(url.to_s)
    end
    def unescape(url)
      EscapeUtils.unescape_url(url.to_s)
    end
    module_function :escape
    module_function :unescape
  end
end
