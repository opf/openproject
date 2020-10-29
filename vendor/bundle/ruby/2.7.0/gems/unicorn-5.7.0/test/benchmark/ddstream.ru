# This app is intended to test large HTTP responses with or without
# a fully-buffering reverse proxy such as nginx. Without a fully-buffering
# reverse proxy, unicorn will be unresponsive when client count exceeds
# worker_processes.
#
# To demonstrate how bad unicorn is at slowly reading clients:
#
#   # in one terminal, start unicorn with one worker:
#   unicorn -E none -l 127.0.0.1:8080 test/benchmark/ddstream.ru
#
#   # in a different terminal, start more slow curl processes than
#   # unicorn workers and watch time outputs
#   curl --limit-rate 8K --trace-time -vsN http://127.0.0.1:8080/ >/dev/null &
#   curl --limit-rate 8K --trace-time -vsN http://127.0.0.1:8080/ >/dev/null &
#   wait
#
# The last client won't see a response until the first one is done reading
#
# nginx note: do not change the default "proxy_buffering" behavior.
# Setting "proxy_buffering off" prevents nginx from protecting unicorn.

# totally standalone rack app to stream a giant response
class BigResponse
  def initialize(bs, count)
    @buf = "#{bs.to_s(16)}\r\n#{' ' * bs}\r\n"
    @count = count
    @res = [ 200,
      { 'Transfer-Encoding' => -'chunked', 'Content-Type' => 'text/plain' },
      self
    ]
  end

  # rack response body iterator
  def each
    (1..@count).each { yield @buf }
    yield -"0\r\n\r\n"
  end

  # rack app entry endpoint
  def call(_env)
    @res
  end
end

# default to a giant (128M) response because kernel socket buffers
# can be ridiculously large on some systems
bs = ENV['bs'] ? ENV['bs'].to_i : 65536
count = ENV['count'] ? ENV['count'].to_i : 2048
warn "serving response with bs=#{bs} count=#{count} (#{bs*count} bytes)"
run BigResponse.new(bs, count)
