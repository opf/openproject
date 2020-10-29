#\-E none
require 'digest/sha1'
require 'unicorn/preread_input'
use Rack::ContentLength
use Rack::ContentType, "text/plain"
use Unicorn::PrereadInput
nr = 0
run lambda { |env|
  $stderr.write "app dispatch: #{nr += 1}\n"
  input = env["rack.input"]
  dig = Digest::SHA1.new
  while buf = input.read(16384)
    dig.update(buf)
  end

  [ 200, {}, [ "#{dig.hexdigest}\n" ] ]
}
