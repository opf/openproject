require 'forwardable'

class Report < ActiveRecord::Base
  InheritedNamespace.activate unless defined? Rails && Rails.version =~ /^3./

  extend Forwardable
  include Enumerable
  #belongs_to :user
  #belongs_to :project
  #attr_protected :user_id, :project_id, :created_at, :updated_at
  self.abstract_class = true #lets have subclasses have their own SQL tables

  def self.accepted_properties
    @@accepted_properties ||= []
  end

  def self.chain_initializer
    @chain_initializer ||= []
  end

  def self.deserialize(hash)
    self.new.tap do |q|
      # have to take the reverse to regain the original order
      hash[:filters].reverse.each {|name, opts| q.filter(name, opts) }
      hash[:group_bys].reverse.each {|name, opts| q.group_by(name, opts) }
    end
  end

  def serialize
    { :filters => filters.collect(&:serialize), :group_bys => group_bys.collect(&:serialize) }
  end

  def available_filters
    self.class::Filter.all
  end

  def transformer
    @transformer ||= self.class::Transformer.new self
  end

  def walker
    @walker ||= self.class::Walker.new self
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
    self.class::Filter.all && self.class::GroupBy.all

    minimal_chain!
    self.class.chain_initializer.each { |block| block.call self }
  end

  def filter(name, options = {})
    add_chain self.class::Filter, name, options
  end

  def group_by(name, options = {})
    add_chain self.class::GroupBy, name, options.reverse_merge(:type => :column)
  end

  def column(name, options = {})
    group_by name, options.merge(:type => :column)
  end

  def row(name, options = {})
    group_by name, options.merge(:type => :row)
  end

  def table
    @table = self.class::Table.new(self)
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
                    :units, :size, :final_number
  def_delegators  :table, :row_index, :colum_index

  def to_a
    chain.to_a
  end

  def to_s
    chain.to_s
  end

  private

  def minimal_chain!
    @chain = self.class::Filter::NoFilter.new
  end

end
