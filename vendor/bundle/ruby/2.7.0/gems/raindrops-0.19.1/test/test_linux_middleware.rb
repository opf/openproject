# -*- encoding: binary -*-
require 'test/unit'
require 'tempfile'
require 'raindrops'
require 'socket'
$stderr.sync = $stdout.sync = true

class TestLinuxMiddleware < Test::Unit::TestCase

  def setup
    @resp_headers = { 'Content-Type' => 'text/plain', 'Content-Length' => '0' }
    @response = [ 200, @resp_headers, [] ]
    @app = lambda { |env| @response }
    @to_close = []
  end

  def teardown
    @to_close.each { |io| io.close unless io.closed? }
  end

  def test_unix_listener
    tmp = Tempfile.new("")
    File.unlink(tmp.path)
    @to_close << UNIXServer.new(tmp.path)
    app = Raindrops::Middleware.new(@app, :listeners => [tmp.path])
    linux_extra = "#{tmp.path} active: 0\n#{tmp.path} queued: 0\n"
    response = app.call("PATH_INFO" => "/_raindrops")

    expect = [
      200,
      {
        "Content-Type" => "text/plain",
        "Content-Length" => (22 + linux_extra.size).to_s
      },
      [
        "calling: 0\nwriting: 0\n#{linux_extra}" \
      ]
    ]
    assert_equal expect, response
  end

  def test_unix_listener_queued
    tmp = Tempfile.new("")
    File.unlink(tmp.path)
    @to_close << UNIXServer.new(tmp.path)
    @to_close << UNIXSocket.new(tmp.path)
    app = Raindrops::Middleware.new(@app, :listeners => [tmp.path])
    linux_extra = "#{tmp.path} active: 0\n#{tmp.path} queued: 1\n"
    response = app.call("PATH_INFO" => "/_raindrops")

    expect = [
      200,
      {
        "Content-Type" => "text/plain",
        "Content-Length" => (22 + linux_extra.size).to_s
      },
      [
        "calling: 0\nwriting: 0\n#{linux_extra}" \
      ]
    ]
    assert_equal expect, response
  end

end if RUBY_PLATFORM =~ /linux/
