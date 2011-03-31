class Report::Filter
  class Base < Report::Chainable
    include Report::QueryUtils

    engine::Operator.load

    inherited_attribute   :available_operators,
                            :list => true, :map => :to_operator,
                            :uniq => true
    inherited_attribute   :default_operator, :map => :to_operator

    accepts_property :values, :value, :operator

    mattr_accessor :skip_inherited_operators
    self.skip_inherited_operators = [:time_operators, "y", "n"]

    attr_accessor :values

    ##
    # A Filter is 'heavy' if it possibly returns a _hughe_ number of available_values.
    # In that case the UI-guys should think twice about displaying all the values.
    def self.heavy?
      false
    end

    ##
    # A Filter may have a depentent filter. See the following example:
    # Filter::Project.dependent --> Filter::Issue
    # This could result in a UI where, if the Prject-filter was selected,
    # the Issue-filter automatically shows up.
    # Arguments:
    #  - any subclass of Reporting::Filter::Base which shall be the dependent filter
    #    or nil, if you want to remove the dependent relationship
    def self.dependent(*args)
      @dependent = args.first unless args.empty?
      @dependent
    end

    def self.has_dependent?
      !!@dependent
    end

    ##
    # Returns an array of filters of which this filter is a dependent
    def self.dependent_from
      engine::Filter.all.select { |f| Array(f.dependent).include? self}
    end

    ##
    # Returns true/false depending of wether any filter has this filter a a dependent
    def self.is_dependent?
      !dependent_from.empty?
    end

    def self.cached(*args)
      @cached ||= {}
      @cached[args] ||= send(*args)
    end

    ##
    # all_dependents computes the depentends of this filter and recursively
    # all_dependents of this class' dependents.
    def self.all_dependents
      self.cached(:compute_all_dependents)
    end

    def self.compute_all_dependents
      dependents = []
      dep = dependent
      while !dep.nil? do
        dependents << dep
        dep = dep.dependent
      end
      dependents
    end

    def value=(val)
      self.values = [val]
    end

    def self.use(*names)
      operators = []
      names.each do |name|
        dont_inherit :available_operators if skip_inherited_operators.include? name
        case name
        when String, engine::Operator then operators << name.to_operator
        when Symbol then operators.push(*engine::Operator.send(name))
        else fail "dunno what to do with #{name.inspect}"
        end
      end
      available_operators *operators
    end

    use :default_operators

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

    def self.available_values(params = {})
      []
    end

    def correct_position?
      child.nil? or child.filter?
    end

    def from_for(scope)
      super + self.class.table_joins
    end

    def filter?
      true
    end

    def valid?
      @operator ? @operator.validate(values) : true
    end

    def errors
      @operator ? @operator.errors : []
    end

    def group_by_fields
      []
    end

    def initialize(child = nil, options = {})
      # TODO: wtf?
      #raise ArgumentError, "Child has to be a Filter." if child and not child.filter?
      @values = []
      super
    end

    def might_be_responsible
      parent
    end

    def operator
      (@operator || self.class.default_operator || engine::Operator.default_operator).to_operator
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
        arity   = operator.arity
        values  = [*self.values].compact
        #if there is just the nil it might be actually intendet to be there
        values.unshift nil if self.values.size==1 && self.values.first.nil?
        values  = values[0, arity] if values and arity >= 0 and arity != values.size
        operator.modify(query, field, *values) unless field.empty?
      end
    end
  end
end
