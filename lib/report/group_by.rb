require "set"

class Report::GroupBy
  extend ProactiveAutoloader
  include Report::QueryUtils
  autoload :Base, 'report/group_by/base'
  autoload :RubyAggregation, 'report/group_by/ruby_aggregation'
  autoload :SingletonValue, 'report/group_by/singleton_value.rb'
  autoload :SqlAggregation, 'report/group_by/sql_aggregation'

  def self.all
    Set[engine::GroupBy::SingletonValue]
  end

  def self.reset!
    @all = nil
  end

  def self.all_grouped
    all.group_by { |f| f.applies_for }.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
  end

  def self.from_hash
    raise NotImplementedError
  end
end
