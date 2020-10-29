#\-E none
require 'unicorn/oob_gc'
use Rack::ContentLength
use Rack::ContentType, "text/plain"
use Unicorn::OobGC, 5, /BAD/
$gc_started = false

# Mock GC.start
def GC.start
  ObjectSpace.each_object(Kgio::Socket) do |x|
    x.closed? or abort "not closed #{x}"
  end
  $gc_started = true
end
run lambda { |env|
  if "/gc_reset" == env["PATH_INFO"] && "POST" == env["REQUEST_METHOD"]
    $gc_started = false
  end
  [ 200, {}, [ "#$gc_started\n" ] ]
}
