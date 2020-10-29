class ERB
  module Util
    def url_encode(s)
      EscapeUtils.escape_url(s.to_s)
    end
    alias u url_encode
    module_function :u
    module_function :url_encode
  end
end