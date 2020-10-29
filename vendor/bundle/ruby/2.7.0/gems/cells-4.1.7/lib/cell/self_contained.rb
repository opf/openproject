# Enforces the new trailblazer directory layout where cells (or concepts in general) are
# fully self-contained in its own directory.
module Cell::SelfContained
  def self_contained!
    extend Prefixes
  end

  module Prefixes
    def _local_prefixes
      super.collect { |prefix| "#{prefix}/views" }
    end
  end
end