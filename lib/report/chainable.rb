# Provides convinience layer and logic shared between GroupBy::Base and Filter::Base.
# Implements a double linked list (FIXME: is that the correct term?).
class Report < ActiveRecord::Base
  class Chainable
    include Enumerable
    include Report::QueryUtils
    extend Report::InheritedAttribute

    # this attr. should point to a symbol useable for translations
    inherited_attribute :applies_for, :default => :label_cost_entry_attributes

    def self.accepts_property(*list)
      engine.accepted_properties.push(*list.map(&:to_s))
    end

    def self.chain_list(*list)
      options = list.extract_options!
      options[:list] = true
      list << options
      inherited_attribute(*list)
    end

    def self.base?
      superclass == engine::Chainable or self == engine::Chainable or
      superclass == Chainable or self == Chainable or
      self == engine::Filter::Base or self == engine::GroupBy::Base
    end

    def self.base
      return self if base?
      superclass.base
    end

    def self.from_base(&block)
      base.instance_eval(&block)
    end

    def self.available
      from_base { @available ||= [] }
    end

    def self.register(label)
      available << klass
      set_inherited_attribute "label", label
    end

    def self.table_joins
      (@table_joins ||= []).clone
    end

    def self.table_from(value)
      return value.table_name if value.respond_to? :table_name
      return value unless value.respond_to? :to_ary or value.respond_to? :to_hash
      table_from value.to_a.first
    end

    def self.join_table(*args)
      @last_table = table_from(args.last)
      (@table_joins ||= []) << args
    end

    def self.underscore_name
      name.demodulize.underscore
    end

    def self.put_sql_table_names(table_prefix_placement = {})
      @table_prefix_placement ||= {}
      @table_prefix_placement.merge! table_prefix_placement
      @table_prefix_placement
    end

    ##
    # The given block is called when a new chain is created for a report.
    # The query will be given to the block as a parameter.
    # Example:
    # initialize_query_with { |query| query.filter Report::Filter::City, :operators => '=', :values => 'Berlin, da great City' }
    def self.initialize_query_with(&block)
      engine.chain_initializer.push block
    end

    inherited_attribute :label, :default => :translation_needed
    inherited_attribute :properties, :list => true

    class << self
      alias inherited_attributes inherited_attribute
      alias accepts_properties accepts_property
    end

    attr_accessor :parent, :child, :type
    accepts_property :type

    def each(&block)
      yield self
      child.try(:each, &block)
    end

    def row?
      type == :row
    end

    def column?
      type == :column
    end

    def group_by?
      !filter?
    end

    def to_a
      [to_hash].tap { |a| a.unshift(*child.to_a) unless bottom? }
    end

    def top
      return self if top?
      parent.top
    end

    def top?
      parent.nil?
    end

    def bottom?
      child.nil?
    end

    def bottom
      return self if bottom?
      child.bottom
    end

    def initialize(child = nil, options = {})
      @options = options
      options.each do |key, value|
        unless self.class.extra_options.include? key
          raise ArgumentError, "may not set #{key}" unless engine.accepted_properties.include? key.to_s
          send "#{key}=", value
        end
      end
      self.child, child.parent = child, self if child
      move_down until correct_position?
      clear
    end

    def to_a
      cached :compute_to_a
    end

    def compute_to_a
      [[self.class.field, @options], *child.try(:to_a)].compact
    end

    def to_s
      URI.escape to_a.map(&:join).join(',')
    end

    def serialize
      [self.class.to_s.demodulize, @options]
    end

    def move_down
      reorder parent, child, self, child.child
    end

    ##
    # Reorder given elements of a doubly linked list to follow the lists order.
    # Don't use this for evil. Assumes there are no elements inbetween, does
    # not touch the first element's parent and the last element's child.
    # Does not touch elements not part of the list.
    #
    # @param [Array] *list Part of the linked list
    def reorder(*list)
      list.each_with_index do |entry, index|
        next_entry = list[index + 1]
        entry.try(:child=, next_entry) if index < list.size - 1
        next_entry.try(:parent=, entry)
      end
    end

    def chain_collect(name, *args, &block)
      top.subchain_collect(name, *args, &block)
    end

    # See #chain_collect
    def subchain_collect(name, *args, &block)
      subchain = child.subchain_collect(name, *args, &block) unless bottom?
      [* send(name, *args, &block) ].push(*subchain).compact.uniq
    end

    # overwrite in subclass to maintain constisten state
    # ie automatically turning
    #   FilterFoo.new(GroupByFoo.new(FilterBar.new))
    # into
    #   GroupByFoo.new(FilterFoo.new(FilterBar.new))
    # Returning false will make the
    def correct_position?
      true
    end

    def clear
      @cached = nil
      child.try :clear
    end

    def result
      cached(:compute_result)
    end

    def compute_result
      engine::Result.new engine.connection.select_all(sql_statement.to_s), {}, type
    end

    def table_joins
      self.class.table_joins
    end

    def cached(*args)
      @cached ||= {}
      @cached[args] ||= send(*args)
    end

    def sql_statement
      raise "should not get here (#{inspect})" if bottom?
      child.cached(:sql_statement).tap do |q|
        chain_collect(:table_joins).each { |args| q.join(*args) } if responsible_for_sql?
      end
    end

    inherited_attribute :db_field
    def self.field
      db_field || (name[/[^:]+$/] || name).to_s.underscore
    end

    inherited_attribute :display, :default => true
    def self.display!
      display true
    end

    def self.display?
      !!display
    end

    def self.dont_display!
      display false
      not_selectable!
    end

    inherited_attribute :selectable, :default => true
    def self.selectable!
      selectable true
    end

    def self.selectable?
      !!selectable
    end

    def self.not_selectable!
      selectable false
    end

    # Extra options this chainable accepts that are not defined in accepted_properties
    def self.extra_options(*symbols)
      @extra_option ||= []
      @extra_option += symbols
    end

    # This chainable type can only ever occur once in a chain
    def self.singleton
      class << self
        def new(chain = nil, options = {})
          return chain if chain and chain.collect(&:class).include? self
          super
        end
      end
    end

    def self.last_table
      @last_table ||= engine::Filter::NoFilter.table_name
    end

    def self.table_name(value = nil)
      @table_name = table_name_for(value) if value
      @table_name || last_table
    end

    def display?
      self.class.display?
    end

    def table_name
      self.class.table_name
    end

    def with_table(fields)
      fields.map do |f|
        place_field_name = self.class.put_sql_table_names[f] || self.class.put_sql_table_names[f].nil?
        place_field_name ? (field_name_for f, self) : f
      end
    end

    def field
      self.class.field
    end

    def mapping
      self.class.method(:mapping).to_proc
    end

    def self.mapping(value)
      value.to_s
    end

    def self.mapping_for(field)
      @field_map ||= (engine::Filter.all + engine.GroupBy.all).inject(Hash.new {|h,k| h[k] = []}) do |hash,cbl|
        hash[cbl.field] << cbl.mapping
      end
      @field_map[field]
    end

    def help_text
      self.class.help_text
    end

    ##
    # Sets a help text to be displayed for this kind of Chainable.
    def self.help_text=(sym)
      @help_text = sym
    end

    def self.help_text(sym = nil)
      @help_text = sym if sym
      @help_text
    end

  end
end
