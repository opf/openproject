class ERB
  module Util
    include ::EscapeUtils::HtmlSafety

    alias html_escape _escape_html
    alias h html_escape
    module_function :h
    module_function :html_escape
  end
end