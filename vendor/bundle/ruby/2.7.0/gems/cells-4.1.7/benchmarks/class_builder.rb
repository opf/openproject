require 'bundler/setup'
require 'benchmark/ips'
require "cells"
require 'cell/view_model'

class ACell < Cell::ViewModel
  def show
    ""
  end
end

class ACellWithBuilder < Cell::ViewModel
  include Cell::Builder

  def show
    ""
  end
end

Benchmark.ips do |x|
  x.report("ACell") { ACell.().() }
  x.report("ACellWithBuilder") { ACellWithBuilder.().() }
  x.compare!
end

__END__

Calculating -------------------------------------
               ACell    25.710k i/100ms
    ACellWithBuilder    19.948k i/100ms
-------------------------------------------------
               ACell    419.631k (± 5.0%) i/s -      2.108M
    ACellWithBuilder    291.924k (± 5.7%) i/s -      1.476M

Comparison:
               ACell:   419630.8 i/s
    ACellWithBuilder:   291923.5 i/s - 1.44x slower
