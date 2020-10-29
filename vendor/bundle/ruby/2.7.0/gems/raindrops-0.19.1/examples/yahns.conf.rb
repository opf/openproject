# Inlined rack app using yahns server (git clone git://yhbt.net/yahns.git)
# Usage: yahns -c /path/to/this/file.conf.rb
# There is no separate config.ru file for this example,
# but rack_app may also be a string pointing to the path of a
# config.ru file

require 'rack'
rack_app = Rack::Builder.new do
  use Rack::Head
  addr = %w(0.0.0.0:9418 0.0.0.0:443 [::]:443 0.0.0.0:80 [::]:80
	    127.0.0.1:6081 127.0.0.1:280 0.0.0.0:119 [::]:119)
  use Raindrops::Middleware, listeners: addr
  run Raindrops::Watcher.new(listeners: addr)
end.to_app
# rack_app = '/path/to/config.ru' # a more standard config

app(:rack, rack_app) do
  # I keep IPv4 and IPv6 on separate sockets to avoid ugly
  # IPv4-mapped-IPv6 addresses:
  listen 8080
  listen '[::]:8080', ipv6only: true
  client_max_body_size 0 # no POST or any uploads
  client_timeout 5
  output_buffering false # needed for /tail/ endpoint to avoid ENOSPC
  queue { worker_threads 30 }
end

# logging is optional, but recommended for diagnosing problems
# stderr_path '/var/log/yahns/stderr-raindrops.log'
# stdout_path '/var/log/yahns/stdout-raindrops.log'
