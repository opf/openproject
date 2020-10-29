#\-E none
#
# Example application that echoes read data back to the HTTP client.
# This emulates the old echo protocol people used to run.
#
# An example of using this in a client would be to run:
#   curl --no-buffer -T- http://host:port/
#
# Then type random stuff in your terminal to watch it get echoed back!

class EchoBody < Struct.new(:input)

  def each(&block)
    while buf = input.read(4096)
      yield buf
    end
    self
  end

end

use Rack::Chunked
run lambda { |env|
  /\A100-continue\z/i =~ env['HTTP_EXPECT'] and return [100, {}, []]
  [ 200, { 'Content-Type' => 'application/octet-stream' },
    EchoBody.new(env['rack.input']) ]
}
