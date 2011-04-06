require "set"

class Report::Filter
  extend ProactiveAutoloader
  autoload :Base, 'report/filter/base'
  autoload :NoFilter, 'report/filter/no_filter'

  def self.all
    @all ||= Set[]
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
