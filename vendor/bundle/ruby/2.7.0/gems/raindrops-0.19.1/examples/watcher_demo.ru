# This is a snippet of the config that powers
# https://yhbt.net/raindrops-demo/
# This may be used with the packaged zbatery.conf.rb
#
# zbatery -c zbatery.conf.ru watcher_demo.ru -E none
require "raindrops"
use Raindrops::Middleware
listeners = %w(
  0.0.0.0:9418
  0.0.0.0:80
  /tmp/.r
)
run Raindrops::Watcher.new :listeners => listeners
