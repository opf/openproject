require "set"

module CostQuery::Filter
  def self.all
    @all ||= Set[
      CostQuery::Filter::ActivityId]
  end

  def self.from_hash
    raise NotImplementedError
  end
end
