use Rack::ContentLength
use Rack::ContentType, "text/plain"
run lambda { |env|

  # our File objects for stderr/stdout should always have #path
  # and be sync=true
  ok = $stderr.sync &&
       $stdout.sync &&
       String === $stderr.path &&
       String === $stdout.path

  [ 200, {}, [ "#{ok}\n" ] ]
}
