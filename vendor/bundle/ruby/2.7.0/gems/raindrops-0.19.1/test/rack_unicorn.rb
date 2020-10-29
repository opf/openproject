# -*- encoding: binary -*-
require "test/unit"
require "raindrops"
require "rack"
require "rack/lobster"
require "open-uri"
begin
  require "unicorn"
  require "rack/lobster"
rescue LoadError => e
  warn "W: #{e} skipping test since Rack or Unicorn was not found"
end
