# -*- encoding: binary -*-
#
# raindrops may use the {aggregate}[https://github.com/josephruscio/aggregate]
# RubyGem to aggregate statistics from TCP_Info lookups.
module Raindrops::Aggregate
  autoload :PMQ, "raindrops/aggregate/pmq"
  autoload :LastDataRecv, "raindrops/aggregate/last_data_recv"
end
