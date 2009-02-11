# http://trac.openidenabled.com/trac/ticket/156
module OpenID
  @@timeout_threshold = 20

  def self.timeout_threshold
    @@timeout_threshold
  end

  def self.timeout_threshold=(value)
    @@timeout_threshold = value
  end

  class StandardFetcher
    def make_http(uri)
      http = @proxy.new(uri.host, uri.port)
      http.read_timeout = http.open_timeout = OpenID.timeout_threshold
      http
    end
  end
end