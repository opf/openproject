# -*- encoding: binary -*-
require 'test/unit'
require 'raindrops'

class TestMiddleware < Test::Unit::TestCase

  def setup
    @resp_headers = { 'Content-Type' => 'text/plain', 'Content-Length' => '0' }
    @response = [ 200, @resp_headers, [] ]
    @app = lambda { |env| @response }
  end

  def test_setup
    app = Raindrops::Middleware.new(@app)
    response = app.call({})
    assert_equal @response[0,2], response[0,2]
    assert response.last.kind_of?(Raindrops::Middleware::Proxy)
    assert response.last.object_id != app.object_id
    tmp = []
    response.last.each { |y| tmp << y }
    assert tmp.empty?
  end

  def test_alt_stats
    stats = Raindrops::Middleware::Stats.new
    app = lambda { |env|
      if (stats.writing == 0 && stats.calling == 1)
        @app.call(env)
      else
        [ 500, @resp_headers, [] ]
      end
    }
    app = Raindrops::Middleware.new(app, :stats => stats)
    response = app.call({})
    assert_equal 0, stats.calling
    assert_equal 1, stats.writing
    assert_equal 200, response[0]
    assert response.last.kind_of?(Raindrops::Middleware::Proxy)
    tmp = []
    response.last.each do |y|
      assert_equal 1, stats.writing
      tmp << y
    end
    assert tmp.empty?
  end

  def test_default_endpoint
    app = Raindrops::Middleware.new(@app)
    response = app.call("PATH_INFO" => "/_raindrops")
    expect = [
      200,
      { "Content-Type" => "text/plain", "Content-Length" => "22" },
      [ "calling: 0\nwriting: 0\n" ]
    ]
    assert_equal expect, response
  end

  def test_alt_endpoint
    app = Raindrops::Middleware.new(@app, :path => "/foo")
    response = app.call("PATH_INFO" => "/foo")
    expect = [
      200,
      { "Content-Type" => "text/plain", "Content-Length" => "22" },
      [ "calling: 0\nwriting: 0\n" ]
    ]
    assert_equal expect, response
  end

  def test_concurrent
    rda, wra = IO.pipe
    rdb, wrb = IO.pipe
    app = lambda do |env|
      wrb.close
      wra.syswrite('.')
      wra.close

      # wait until parent has run app.call for stats endpoint
      rdb.read
      @app.call(env)
    end
    app = Raindrops::Middleware.new(app)

    pid = fork { app.call({}) }
    rdb.close

    # wait til child is running in app.call
    assert_equal '.', rda.sysread(1)
    rda.close

    response = app.call("PATH_INFO" => "/_raindrops")
    expect = [
      200,
      { "Content-Type" => "text/plain", "Content-Length" => "22" },
      [ "calling: 1\nwriting: 0\n" ]
    ]
    assert_equal expect, response
    wrb.close # unblock child process
    assert Process.waitpid2(pid).last.success?

    # we didn't call close the body in the forked child, so it'll always be
    # marked as writing, a real server would close the body
    response = app.call("PATH_INFO" => "/_raindrops")
    expect = [
      200,
      { "Content-Type" => "text/plain", "Content-Length" => "22" },
      [ "calling: 0\nwriting: 1\n" ]
    ]
    assert_equal expect, response
  end

  def test_middleware_proxy_to_path_missing
    app = Raindrops::Middleware.new(@app)
    response = app.call({})
    body = response[2]
    assert_kind_of Raindrops::Middleware::Proxy, body
    assert ! body.respond_to?(:to_path)
    assert body.respond_to?(:close)
    orig_body = @response[2]

    def orig_body.to_path; "/dev/null"; end
    assert body.respond_to?(:to_path)
    assert_equal "/dev/null", body.to_path

    def orig_body.body; "this is a body"; end
    assert body.respond_to?(:body)
    assert_equal "this is a body", body.body
  end
end
