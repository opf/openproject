module Haml
  module Helpers
    include ::EscapeUtils::HtmlSafety

    alias html_escape _escape_html
  end
end