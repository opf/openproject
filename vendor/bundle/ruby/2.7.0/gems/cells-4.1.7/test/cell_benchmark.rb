require 'test_helper'
require 'benchmark'

Song = Struct.new(:title)


class SongCell < Cell::ViewModel
  self.view_paths = ['test']
  property :title

  def show
    render
  end
end

time = Benchmark.measure do
  Cell::ViewModel.cell(:song, nil, collection: 1000.times.collect { Song.new("Anarchy Camp") })
end

puts time

# 4.0
  # 0.310000   0.010000   0.320000 (  0.320382)

  # no caching of templates, puts
  #   0.570000   0.030000   0.600000 (  0.600160)

  # caching of templates
  #  0.090000   0.000000   0.090000 (  0.085652)

  # wed, 17.
  #   0.120000   0.010000   0.130000 (  0.127731)
