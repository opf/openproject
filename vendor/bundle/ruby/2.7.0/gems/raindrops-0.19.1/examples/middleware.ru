# sample stand-alone rackup application for Raindrops::Middleware
require 'rack/lobster'
require 'raindrops'
use Raindrops::Middleware
run Rack::Lobster.new
