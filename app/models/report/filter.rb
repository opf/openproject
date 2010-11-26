require "set"

module Report::Filter
  extend self

  def all
    @all ||= Set[]
  end

  def all_grouped
    all.group_by { |f| f.applies_for }.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
  end

  def from_hash
    raise NotImplementedError
  end
end
