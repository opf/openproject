class CGI
  extend ::EscapeUtils::HtmlSafety

  class << self
    alias escapeHTML _escape_html

    def unescapeHTML(s)
      EscapeUtils.unescape_html(s.to_s)
    end
  end
end