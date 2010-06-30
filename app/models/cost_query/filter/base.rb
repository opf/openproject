module CostQuery::Filter
  class Base < CostQuery::Chainable
    CostQuery::Operator.load

    inherited_attribute   :available_operators,
                            :list => true, :map => :to_operator,
                            :uniq => true
    inherited_attribute   :default_operator, :map => :to_operator

    accepts_property :values, :value, :operator

    attr_accessor :values

    def value=(val)
      self.values = [val]
    end

    def self.default_operators
      available_operators "=", "!"
    end
    default_operators

    def self.date_operators
      available_operators "<>d", ">d", "<d", "=d"
    end

    def self.time_operators
      available_operators "t", "w", "t-", "t+", ">t-", "<t-", ">t+", "<t+"
    end
    
    def self.string_operators
      available_operators "!~", "~"
    end
    
    def self.null_operators
      available_operators "*", "!*"
    end
    
    def self.integer_operators
      available_operators "<", ">", "<=", ">="
    end

    def self.new(*args, &block) # :nodoc:
      # this class is abstract. instances are only allowed from child classes
      raise "#{self.name} is an abstract class" if base?
      super
    end

    def self.inherited(klass)
      if base?
        self.dont_display!
        klass.display!
      end
      super
    end

    def self.display!
      display true
    end

    def self.display?
      !!display
    end

    def self.dont_display!
      display false
    end

    def self.available_values(project)
      raise NotImplementedError, "subclass responsibility"
    end

    def self.underscore_name
      name.demodulize.underscore
    end

    def correct_position?
      child.nil? or child.is_a? CostQuery::Filter::Base
    end

    def from_for(scope)
      super + self.class.table_joins
    end

    def filter?
      true
    end

    def group_by_fields
      []
    end

    def initialze(child = nil, options = {})
      raise ArgumentError, "Child has to be a Filter." if child and not child.filter?
      @values = []
      super
    end

    def might_be_responsible
      parent
    end

    def operator
      (@operator || self.class.default_operator || CostQuery::Operator.default_operator).to_operator
    end

    def operator=(value)
      @operator = value.to_operator.tap do |o|
        raise ArgumentError, "#{o.inspect} not supported by #{inspect}." unless available_operators.include? o
      end
    end

    def responsible_for_sql?
      top?
    end

    def to_hash
      raise NotImplementedError
    end

    def sql_statement
      super.tap do |query|
        operator.modify(query, field, *values)
      end
    end
  end
end