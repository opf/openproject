require 'test/unit'
require 'net/http'
require 'webrick'

require 'testutil'
require 'util'

require 'openid/fetchers'

require 'stringio'

begin
  require 'net/https'
rescue LoadError
  # We need these names for testing.

  module OpenSSL
    module SSL
      class SSLError < StandardError; end
    end
  end
end

module HttpResultAssertions
  def assert_http_result_is(expected, result)
    assert_equal expected.code, result.code
    assert_equal expected.body, result.body
    assert_equal expected.final_url, result.final_url
  end
end

class BogusFetcher
  RESPONSE = "bogus"

  def fetch(url, body=nil, headers=nil, redirect_limit=5)
    return BogusFetcher::RESPONSE
  end
end

class FetcherTestCase < Test::Unit::TestCase
  include HttpResultAssertions
  include OpenID::TestUtil

  @@test_header_name = 'X-test-header'
  @@test_header_value = 'marmoset'

  class ExpectedResponse < Net::HTTPResponse
    attr_reader :final_url

    def initialize(code, final_url, body="the expected body",
                   httpv="1.1", msg=nil)
      super(httpv, code, msg)
      @code = code
      @body = body
      @final_url = final_url
    end

    def body
      @body
    end
  end

  @@cases =
    [
     # path, status code, expected url (nil = default to path)
     ['/success', 200, nil],
     ['/notfound', 404, nil],
     ['/badreq', 400, nil],
     ['/forbidden', 403, nil],
     ['/error', 500, nil],
     ['/server_error', 503, nil],
     ['/301redirect', 200, '/success'],
     ['/302redirect', 200, '/success'],
     ['/303redirect', 200, '/success'],
     ['/307redirect', 200, '/success'],
    ]

  def _redirect_with_code(code)
    lambda { |req, resp|
      resp.status = code
      resp['Location'] = _uri_build('/success')
    }
  end

  def _respond_with_code(code)
    lambda { |req, resp|
      resp.status = code
      resp.body = "the expected body"
    }
  end

  def _require_header
    lambda { |req, resp|
      assert_equal @@test_header_value, req[@@test_header_name]
      assert_match 'ruby-openid', req['User-agent']
    }
  end

  def _require_post
    lambda { |req, resp|
      assert_equal 'POST', req.request_method
      assert_equal "postbody\n", req.body
    }
  end

  def _redirect_loop
    lambda { |req, resp|
      @_redirect_counter += 1
      resp.status = 302
      resp['Location'] = _uri_build('/redirect_loop')
      resp.body = "Fetched #{@_redirect_counter} times."
      assert_block("Fetched too many times.") { @_redirect_counter < 10 }
    }
  end
  
  def setup
    @fetcher = OpenID::StandardFetcher.new
    @logfile = StringIO.new
    @weblog = WEBrick::Log.new(logfile=@logfile)
    @server = WEBrick::HTTPServer.new(:Port => 0,
                                      :Logger => @weblog,
                                      :AccessLog => [])
    @server_thread = Thread.new {
      @server.mount_proc('/success', _respond_with_code(200))
      @server.mount_proc('/301redirect', _redirect_with_code(301))
      @server.mount_proc('/302redirect', _redirect_with_code(302))
      @server.mount_proc('/303redirect', _redirect_with_code(303))
      @server.mount_proc('/307redirect', _redirect_with_code(307))
      @server.mount_proc('/badreq', _respond_with_code(400))
      @server.mount_proc('/forbidden', _respond_with_code(403))
      @server.mount_proc('/notfound', _respond_with_code(404))
      @server.mount_proc('/error', _respond_with_code(500))
      @server.mount_proc('/server_error', _respond_with_code(503))
      @server.mount_proc('/require_header', _require_header)
      @server.mount_proc('/redirect_to_reqheader') { |req, resp|
        resp.status = 302
        resp['Location'] = _uri_build('/require_header')
      }
      @server.mount_proc('/post', _require_post)
      @server.mount_proc('/redirect_loop', _redirect_loop)
      @server.start
    }
    @uri = _uri_build
    sleep 0.2
  end

  def _uri_build(path='/')
    u = URI::HTTP.build({
                          :host => @server.config[:ServerName],
                          :port => @server.config[:Port],
                          :path => path,
                        })
    return u.to_s
  end

  def teardown
    @server.shutdown
    # Sleep a little because sometimes this blocks forever.
    @server_thread.join
  end

=begin
# XXX This test no longer works since we're not dealing with URI
# objects internally.
  def test_final_url_tainted
    uri = _uri_build('/301redirect')
    result = @fetcher.fetch(uri)

    final_url = URI::parse(result.final_url)

    assert final_url.host.tainted?
    assert final_url.path.tainted?
  end
=end

  def test_headers
    headers = {
      @@test_header_name => @@test_header_value
    }
    uri = _uri_build('/require_header')
    result = @fetcher.fetch(uri, nil, headers)
    # The real test runs under the WEBrick handler _require_header,
    # this just checks the return code from that.
    assert_equal '200', result.code, @logfile.string
  end

  def test_headers_after_redirect
    headers = {
      @@test_header_name => @@test_header_value
    }
    uri = _uri_build('/redirect_to_reqheader')
    result = @fetcher.fetch(uri, nil, headers)
    # The real test runs under the WEBrick handler _require_header,
    # this just checks the return code from that.
    assert_equal '200', result.code, @logfile.string
  end

  def test_post
    uri = _uri_build('/post')
    result = @fetcher.fetch(uri, "postbody\n")
    # The real test runs under the WEBrick handler _require_header,
    # this just checks the return code from that.
    assert_equal '200', result.code, @logfile.string
  end

  def test_redirect_limit
    @_redirect_counter = 0
    uri = _uri_build('/redirect_loop')
    assert_raise(OpenID::HTTPRedirectLimitReached) {
      @fetcher.fetch(uri)
    }
  end

  def test_cases
    for path, expected_code, expected_url in @@cases
      uri = _uri_build(path)
      if expected_url.nil?
        expected_url = uri
      else
        expected_url = _uri_build(expected_url)
      end

      expected = ExpectedResponse.new(expected_code.to_s, expected_url)
      result = @fetcher.fetch(uri)

      begin
        assert_http_result_is expected, result
      rescue Test::Unit::AssertionFailedError => err
        if result.code == '500' && expected_code != 500
          # Looks like our WEBrick harness broke.
          msg = <<EOF
Status #{result.code} from case #{path}.  Logs:
#{@logfile.string}
EOF
          raise msg
        end

        # Wrap failure messages so we can tell which case failed.
        new_msg = "#{path}: #{err.message.to_s}"
        new_err = Test::Unit::AssertionFailedError.new(new_msg)
        new_err.set_backtrace(err.backtrace)
        raise new_err
      end
    end
  end

  def test_https_no_openssl
    # Override supports_ssl? to always claim that connections don't
    # support SSL.  Test the behavior of fetch() for HTTPS URLs in
    # that case.
    f = OpenID::StandardFetcher.new
    f.extend(OpenID::InstanceDefExtension)

    f.instance_def(:supports_ssl?) do |conn|
      false
    end

    begin
      f.fetch("https://someurl.com/")
      flunk("Expected RuntimeError")
    rescue RuntimeError => why
      assert_equal(why.to_s, "SSL support not found; cannot fetch https://someurl.com/")
    end
  end

  class FakeConnection < Net::HTTP
    attr_reader :use_ssl, :ca_file

    def initialize *args
      super
      @ca_file = nil
    end

    def use_ssl=(v)
      @use_ssl = v
    end

    def ca_file=(ca_file)
      @ca_file = ca_file
    end
  end

  def test_ssl_with_ca_file
    f = OpenID::StandardFetcher.new
    ca_file = "BOGUS"
    f.ca_file = ca_file

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_http) do |uri|
      FakeConnection.new(uri.host, uri.port)
    end

    testcase = self

    f.instance_def(:set_verified) do |conn, verified|
      testcase.assert(verified)
    end

    conn = f.make_connection(URI::parse("https://someurl.com"))
    assert_equal(conn.ca_file, ca_file)
  end

  def test_ssl_without_ca_file
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_http) do |uri|
      FakeConnection.new(uri.host, uri.port)
    end

    testcase = self

    f.instance_def(:set_verified) do |conn, verified|
      testcase.assert(!verified)
    end

    conn = nil
    assert_log_matches(/making https request to https:\/\/someurl.com without verifying/) {
      conn = f.make_connection(URI::parse("https://someurl.com"))
    }

    assert(conn.ca_file.nil?)
  end

  def test_make_http_nil
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_http) do |uri|
      nil
    end

    assert_raise(RuntimeError) {
      f.make_connection(URI::parse("http://example.com/"))
    }
  end

  def test_make_http_invalid
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_http) do |uri|
      "not a Net::HTTP object"
    end

    assert_raise(RuntimeError) {
      f.make_connection(URI::parse("http://example.com/"))
    }
  end

  class BrokenSSLConnection
    def start(&block)
      raise OpenSSL::SSL::SSLError
    end
  end

  def test_sslfetchingerror
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_connection) do |uri|
      BrokenSSLConnection.new
    end

    assert_raise(OpenID::SSLFetchingError) {
      f.fetch("https://bogus.com/")
    }
  end

  class TimeoutConnection
    def start(&block)
      raise Timeout::Error
    end
  end

  def test_fetchingerror
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_connection) do |uri|
      TimeoutConnection.new
    end

    assert_raise(OpenID::FetchingError) {
      f.fetch("https://bogus.com/")
    }
  end
  
  class TestingException < OpenID::FetchingError; end

  class NoSSLSupportConnection
    def supports_ssl?
      false
    end

    def start
      yield
    end

    def request_get(*args)
      raise TestingException
    end

    def post_connection_check(hostname)
      raise RuntimeError
    end

    def use_ssl?
      true
    end
  end

  class NoUseSSLConnection < NoSSLSupportConnection
    def use_ssl?
      false
    end
  end

  def test_post_connection_check_no_support_ssl
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_connection) do |uri|
      NoSSLSupportConnection.new
    end

    # post_connection_check should not be called.
    assert_raise(TestingException) {
      f.fetch("https://bogus.com/")
    }
  end

  def test_post_connection_check_no_use_ssl
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_connection) do |uri|
      NoUseSSLConnection.new
    end

    # post_connection_check should not be called.
    assert_raise(TestingException) {
      f.fetch("https://bogus.com/")
    }
  end

  class PostConnectionCheckException < OpenID::FetchingError; end

  class UseSSLConnection < NoSSLSupportConnection
    def use_ssl?
      true
    end

    def post_connection_check(hostname)
      raise PostConnectionCheckException
    end
  end

  def test_post_connection_check
    f = OpenID::StandardFetcher.new

    f.extend(OpenID::InstanceDefExtension)
    f.instance_def(:make_connection) do |uri|
      UseSSLConnection.new
    end

    f.instance_def(:supports_ssl?) do |conn|
      true
    end

    # post_connection_check should be called.
    assert_raise(PostConnectionCheckException) {
      f.fetch("https://bogus.com/")
    }
  end
end

class DefaultFetcherTest < Test::Unit::TestCase
  def setup
    OpenID.fetcher = nil
  end

  def test_default_fetcher
    assert(OpenID.fetcher.is_a?(OpenID::StandardFetcher))

    # A custom fetcher can be set
    OpenID.fetcher = BogusFetcher.new

    # A test fetch should call the new fetcher
    assert(OpenID.fetch('not-a-url') == BogusFetcher::RESPONSE)

    # Set the fetcher to nil again
    OpenID.fetcher = nil
    assert(OpenID.fetcher.is_a?(OpenID::StandardFetcher))
  end
end

class ProxyTest < Test::Unit::TestCase
  def test_proxy_unreachable
    begin
      f = OpenID::StandardFetcher.new('127.0.0.1', 1)
      # If this tries to connect to the proxy (on port 1), I expect
      # a 'connection refused' error.  If it tries to contact the below
      # URI first, it will get some other sort of error.
      f.fetch("http://unittest.invalid")
    rescue OpenID::FetchingError => why
      # XXX: Is this a translatable string that is going to break?
      if why.message =~ /Connection refused/
        return
      end
      raise why
    end
    flunk "expected Connection Refused, but it passed."
  end

  def test_proxy_env
    ENV['http_proxy'] = 'http://127.0.0.1:3128/'
    OpenID.fetcher_use_env_http_proxy
    
    # make_http just to give us something with readable attributes to inspect.
    conn = OpenID.fetcher.make_http(URI.parse('http://127.0.0.2'))
    assert_equal('127.0.0.1', conn.proxy_address)
    assert_equal(3128, conn.proxy_port)
  end
  # These aren't fully automated tests, but if you start a proxy
  # on port 8888 (tinyproxy's default) and check its logs...
#   def test_proxy
#     f = OpenID::StandardFetcher.new('127.0.0.1', 8888)
#     result = f.fetch("http://www.example.com/")
#     assert_match(/RFC.*2606/, result.body)
#   end

#   def test_proxy_https
#     f = OpenID::StandardFetcher.new('127.0.0.1', 8888)
#     result = f.fetch("https://www.myopenid.com/")
#     assert_match(/myOpenID/, result.body)
#   end
end
