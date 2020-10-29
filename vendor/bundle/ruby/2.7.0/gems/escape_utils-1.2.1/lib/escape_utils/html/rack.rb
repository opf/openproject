module Rack
  module Utils
    include ::EscapeUtils::HtmlSafety

    alias escape_html _escape_html
    module_function :escape_html
  end
end
