require "set"

class Report::GroupBy
  include Report::QueryUtils

  def self.all
    Set[engine::GroupBy::SingletonValue]
  end

  def self.all_grouped
    all.group_by { |f| f.applies_for }.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
  end

  def self.from_hash
    raise NotImplementedError
  end
end
