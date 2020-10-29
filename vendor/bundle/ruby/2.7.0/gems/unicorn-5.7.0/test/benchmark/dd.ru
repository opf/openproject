# This benchmark is the simplest test of the I/O facilities in
# unicorn.  It is meant to return a fixed-sized blob to test
# the performance of things in Unicorn, _NOT_ the app.
#
# Adjusting this benchmark is done via the "bs" (byte size) and "count"
# environment variables.  "count" designates the count of elements of
# "bs" length in the Rack response body.  The defaults are bs=4096, count=1
# to return one 4096-byte chunk.
bs = ENV['bs'] ? ENV['bs'].to_i : 4096
count = ENV['count'] ? ENV['count'].to_i : 1
slice = (' ' * bs).freeze
body = (1..count).map { slice }.freeze
hdr = {
  'Content-Length' => (bs * count).to_s.freeze,
  'Content-Type' => 'text/plain'.freeze
}.freeze
response = [ 200, hdr, body ].freeze
run(lambda { |env| response })
