require "set"

module CostQuery::GroupBy
  def self.all
    @all ||= Set.new
  end

  def self.from_hash
    raise NotImplementedError
  end
end