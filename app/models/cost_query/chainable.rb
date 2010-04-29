# Proviedes convinience layer and logic shared between GroupBy::Base and Filter::Base.
# Implements a dubble linked list (FIXME: is that the correct term?).
class CostQuery < ActiveRecord::Base
  class Chainable
    include CostQuery::QueryUtils

    def self.accepts_property(*list)
      CostQuery.accepted_properties.push(*list.map(&:to_s))
    end

    def self.inherited_attribute(*attributes, &block)
      options = attributes.extract_options!
      list    = options[:list]
      default = options[:default]
      uniq    = options[:uniq]
      map     = options[:map] || proc { |e| e }
      default ||= [] if list
      attributes.each do |name|
        define_singleton_method(name) do |*values|
          return get_inherited_attribute(name, default, list, uniq) if values.empty?
          return set_inherited_attribute(name, values.map(&map)) if list
          raise ArgumentError, "wrong number of arguments (#{values.size} for 1)" if values.size > 1
          set_inherited_attribute name, map.call(values.first)
        end
        define_method(name) { |*values| self.class.send(name, *values) }
      end
    end

    def self.define_singleton_method(name, &block)
      attr_writer name
      metaclass.class_eval { define_method(name, &block) }
      define_method(name) { instance_variable_get("@#{name}") or metaclass.send(name) }
    end

    def self.get_inherited_attribute(name, default = nil, list = false, uniq = false)
      return get_inherited_attribute(name, default, list, false).uniq if list and uniq
      result       = instance_variable_get("@#{name}")
      super_result = superclass.get_inherited_attribute(name, default, list) if superclass.respond_to? :get_inherited_attribute
      if result
        list && super_result ? result + super_result : result
      else
        super_result || default
      end
    end

    def self.set_inherited_attribute(name, value)
      instance_variable_set "@#{name}", value
    end

    def self.chain_list(*list)
      options = list.extract_options!
      options[:list] = true
      list << options
      inherited_attribute(*list)
    end

    def self.base?
      superclass == Chainable or self == Chainable
    end

    def self.base
      return self if base?
      super
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
      @table_joins ||= []
    end

    def self.table_from(value)
      return value unless value.respond_to? :to_ary or value.respond_to? :to_hash
      table_from value.to_a.first
    end

    def self.join_table(*args)
      @last_table = table_from(args.last)
      table_joins << args
    end

    inherited_attribute :label
    inherited_attribute :properties, :list => true

    class << self
      alias inherited_attributes inherited_attribute
      alias accepts_properties accepts_property
    end

    attr_accessor :parent
    attr_reader :child

    def child=(obj)
      @child = obj
    end

    def to_a
      returning([to_hash]) { |a| a.unshift(*child.to_a) unless bottom? }
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
      @child, child.parent = child, self if child
      options.each do |key, value|
        raise ArgumentError, "may not set #{key}" unless CostQuery.accepted_properties.include? key.to_s
        send "#{key}=", value
      end
      until correct_position?
        child_was = child
        child_was.parent, self.parent = parent, child_was
        child_was.child, self.child = self, child.child
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

    def result
      Result.new ActiveRecord::Base.connection.select_all(sql_statement.to_s)
    end

    def table_joins
      self.class.table_joins
    end

    def sql_statement
      raise "should not get here (#{inspect})" if bottom?
      child.sql_statement.tap { |q| chain_collect(:table_joins).each { |args| q.join(*args) } if responsible_for_sql? }
    end

    inherited_attributes :db_field, :display
    def self.field
      db_field || name[/[^:]+$/].underscore
    end

    def self.last_table
      @last_table ||= 'entries'
    end

    def last_table
      self.class.last_table
    end

    def with_table(fields)
      fields.map { |f| field_name_for f, last_table }
    end

    def field
      self.class.field
    end

  end
end