require "disposable/twin"
require 'ostruct'
require 'benchmark'

class Band < Disposable::Twin
  property :name

  collection :songs do
    property :title
  end
end

songs = 50.times.collect { Struct.new(:title).new("Be Stag") }
band = Struct.new(:name, :songs).new("Teenage Bottlerock", songs)

time = Benchmark.measure do
  1000.times do
    Band.new(band)
  end
end

puts time

# with old Fields.new(to_hash)
#   4.200000
# 20%
# with setup and new(fields).from_object(twin) instead of Fields.new(to_hash)
#   3.680000   0.000000   3.680000 (  3.685796)


# 06/01
# 0.300000   0.000000   0.300000 (  0.298956)
