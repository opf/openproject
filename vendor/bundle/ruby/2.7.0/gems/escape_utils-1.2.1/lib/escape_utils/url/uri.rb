module URI
  def self.escape(s, unsafe=nil)
    EscapeUtils.escape_uri(s.to_s)
  end
  def self.unescape(s)
    EscapeUtils.unescape_uri(s.to_s)
  end
end