use Rack::ContentLength
use Rack::ContentType, "text/plain"
names = Unicorn.listener_names.inspect # rely on preload_app=true
run(lambda { |_| [ 200, {}, [ names ] ] })
