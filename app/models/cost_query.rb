require_dependency "entry"
require 'forwardable'

class CostQuery < ActiveRecord::Base
  extend Forwardable
  #belongs_to :user
  #belongs_to :project
  #attr_protected :user_id, :project_id, :created_at, :updated_at

  def self.accepted_properties
    @accepted_properties ||= []
  end

  # FIXME: (RE)MOVE ME
  def self.example
    @example ||= CostQuery.new.group_by(:issue_id).column(:tweek).row(:project_id).row(:user_id)
  end

  def walker
    @walker ||= CostQuery::Walker.new self
  end

  def add_chain(type, name, options)
    chain type.const_get(name.to_s.camelcase), options
    @walker = nil
    self
  end

  def chain(klass = nil, options = {})
    @chain ||= Filter::NoFilter.new
    @chain = klass.new @chain, options if klass
    @chain = @chain.parent until @chain.top?
    @chain
  end

  def filter(name, options = {})
    add_chain Filter, name, options
  end

  def group_by(name, options = {})
    add_chain GroupBy, name, options.reverse_merge(:type => :column)
  end

  def column(name, options = {})
    group_by name, options.merge(:type => :column)
  end

  def row(name, options = {})
    group_by name, options.merge(:type => :row)
  end

  def_delegators :walker, :walk, :column_first, :row_first
  def_delegators :chain, :top, :bottom, :chain_collect, :sql_statement, :all_group_fields, :child, :clear

  def to_a
    chain.to_a
  end

  def to_s
    chain.to_s
  end

  def result
    Rails.cache.fetch(to_s, :expires_in => 30.minutes) { chain.result }
  end

end
