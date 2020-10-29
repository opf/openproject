ENV['RACK_ENV'] = 'test'

begin
  require 'rack'
rescue LoadError
  require 'rubygems'
  require 'rack'
end

testdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(testdir) unless $LOAD_PATH.include?(testdir)

libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'test/unit'
require 'rack/accept'

class Test::Unit::TestCase
  attr_reader :context
  attr_reader :response

  def status
    @response && @response.status
  end

  def request(env={}, method='GET', uri='/')
    @context = Rack::Accept.new(fake_app)
    yield @context if block_given?
    mock_request = Rack::MockRequest.new(@context)
    @response = mock_request.request(method.to_s.upcase, uri, env)
    @response
  end

  def fake_app(status=200, headers={}, body=[])
    lambda {|env| Rack::Response.new(body, status, headers).finish }
  end
end
