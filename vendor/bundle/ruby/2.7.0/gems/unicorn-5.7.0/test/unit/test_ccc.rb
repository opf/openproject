require 'socket'
require 'unicorn'
require 'io/wait'
require 'tempfile'
require 'test/unit'

class TestCccTCPI < Test::Unit::TestCase
  def test_ccc_tcpi
    start_pid = $$
    host = '127.0.0.1'
    srv = TCPServer.new(host, 0)
    port = srv.addr[1]
    err = Tempfile.new('unicorn_ccc')
    rd, wr = IO.pipe
    sleep_pipe = IO.pipe
    pid = fork do
      sleep_pipe[1].close
      reqs = 0
      rd.close
      worker_pid = nil
      app = lambda do |env|
        worker_pid ||= begin
          at_exit { wr.write(reqs.to_s) if worker_pid == $$ }
          $$
        end
        reqs += 1

        # will wake up when writer closes
        sleep_pipe[0].read if env['PATH_INFO'] == '/sleep'

        [ 200, [ %w(Content-Length 0),  %w(Content-Type text/plain) ], [] ]
      end
      ENV['UNICORN_FD'] = srv.fileno.to_s
      opts = {
        listeners: [ "#{host}:#{port}" ],
        stderr_path: err.path,
        check_client_connection: true,
      }
      uni = Unicorn::HttpServer.new(app, opts)
      uni.start.join
    end
    wr.close

    # make sure the server is running, at least
    client = TCPSocket.new(host, port)
    client.write("GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")
    assert client.wait(10), 'never got response from server'
    res = client.read
    assert_match %r{\AHTTP/1\.1 200}, res, 'got part of first response'
    assert_match %r{\r\n\r\n\z}, res, 'got end of response, server is ready'
    client.close

    # start a slow request...
    sleeper = TCPSocket.new(host, port)
    sleeper.write("GET /sleep HTTP/1.1\r\nHost: example.com\r\n\r\n")

    # and a bunch of aborted ones
    nr = 100
    nr.times do |i|
      client = TCPSocket.new(host, port)
      client.write("GET /collections/#{rand(10000)} HTTP/1.1\r\n" \
                   "Host: example.com\r\n\r\n")
      client.close
    end
    sleep_pipe[1].close # wake up the reader in the worker
    res = sleeper.read
    assert_match %r{\AHTTP/1\.1 200}, res, 'got part of first sleeper response'
    assert_match %r{\r\n\r\n\z}, res, 'got end of sleeper response'
    sleeper.close
    kpid = pid
    pid = nil
    Process.kill(:QUIT, kpid)
    _, status = Process.waitpid2(kpid)
    assert status.success?
    reqs = rd.read.to_i
    warn "server got #{reqs} requests with #{nr} CCC aborted\n" if $DEBUG
    assert_operator reqs, :<, nr
    assert_operator reqs, :>=, 2, 'first 2 requests got through, at least'
  ensure
    return if start_pid != $$
    srv.close if srv
    if pid
      Process.kill(:QUIT, pid)
      _, status = Process.waitpid2(pid)
      assert status.success?
    end
    err.close! if err
    rd.close if rd
  end
end
