require "set"

module CostQuery::Filter

  def self.all
    @all ||= Set.new
  end

  def self.from_hash
    raise NotImplementedError
  end

end