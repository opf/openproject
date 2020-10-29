require 'test_helper'
require 'benchmark'
require 'benchmark/ips'

Song = Struct.new(:title)


class SongCell < Cell::ViewModel
  self.view_paths = ['test/fixtures']
  property :title

  def show
    render
  end
end

ary = 1000.times.collect { |i| Song.new(i) }

Benchmark.ips do |x|
  x.report("collection, call") { SongCell.(collection: ary).() }
  x.report("collection, join") { SongCell.(collection: ary).join { |cell, i| cell.() } }
  # x.report("collection, joinstr") { SongCell.(collection: ary).joinstr { |cell, i| cell.() } }
  # x.report("collection, joincollect") { SongCell.(collection: ary).joincollect { |cell, i| cell.() } }
  # x.report("ACellWithBuilder") { ACellWithBuilder.().() }
  x.compare!
end

__END__

Calculating -------------------------------------
    collection, call     3.000  i/100ms
    collection, join     3.000  i/100ms
-------------------------------------------------
    collection, call     33.403  (± 3.0%) i/s -    168.000
    collection, join     33.248  (± 3.0%) i/s -    168.000

Comparison:
    collection, call:       33.4 i/s
    collection, join:       33.2 i/s - 1.00x slower



Comparison:
    collection, join:       32.8 i/s
    collection, call:       32.6 i/s - 1.01x slower
 collection, joinstr:       32.6 i/s - 1.01x slower
collection, joincollect:       32.4 i/s - 1.01x slower # each_with_index.collect.join
