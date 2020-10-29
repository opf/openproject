class CGI
  def self.escape(s)
    EscapeUtils.escape_url(s.to_s)
  end
  def self.unescape(s)
    EscapeUtils.unescape_url(s.to_s)
  end
end