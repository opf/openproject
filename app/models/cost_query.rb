require_dependency "entry"
require 'forwardable'

class CostQuery < ActiveRecord::Base
  extend Forwardable
  include Enumerable
  #belongs_to :user
  #belongs_to :project
  #attr_protected :user_id, :project_id, :created_at, :updated_at

  def self.accepted_properties
    @accepted_properties ||= []
  end

  def self.chain_initializer
    return @chain_initializer ||= []
  end

  def self.deserialize(hash)
    self.new.tap do |q|
      hash[:filters].each {|name, opts| q.filter(name, opts) }
      hash[:group_bys].each {|name, opts| q.group_by(name, opts) }
    end
  end

  def serialize
    { :filters => filters.collect(&:serialize), :group_bys => group_bys.collect(&:serialize) }
  end

  def available_filters
    CostQuery::Filter.all
  end

  def transformer
    @transformer ||= CostQuery::Transformer.new self
  end

  def walker
    @walker ||= CostQuery::Walker.new self
  end

  def add_chain(type, name, options)
    chain type.const_get(name.to_s.camelcase), options
    @transformer, @table, @depths, @walker = nil, nil, nil, nil
    self
  end

  def chain(klass = nil, options = {})
    build_new_chain unless @chain
    @chain = klass.new @chain, options if klass
    @chain = @chain.parent until @chain.top?
    @chain
  end

  def build_new_chain
    #FIXME: is there a better way to load all filter and groups?
    Filter.all && GroupBy.all

    minimal_chain!
    self.class.chain_initializer.each { |block| block.call self }
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

  def table
    @table = Table.new(self)
  end

  def group_bys
    chain.select { |c| c.group_by? }
  end

  def filters
    chain.select { |c| c.filter? }
  end

  def depth_of(name)
    @depths ||= {}
    @depths[name] ||= chain.inject(0) { |sum, child| child.type == name ? sum + 1 : sum }
  end

  def_delegators  :transformer, :column_first, :row_first
  def_delegators  :chain, :empty_chain, :top, :bottom, :chain_collect, :sql_statement, :all_group_fields, :child, :clear, :result
  def_delegators  :result, :each_direct_result, :recursive_each, :recursive_each_with_level, :each, :each_row, :count,
                    :units, :real_costs, :size, :final_number
  def_delegators  :table, :row_index, :colum_index

  def to_a
    chain.to_a
  end

  def to_s
    chain.to_s
  end
  
  private
  
  def minimal_chain!
    @chain = Filter::NoFilter.new
  end

end
