class Report::Operator
  include Report::QueryUtils
  include Report::Validation
  extend Forwardable

  #############################################################################################
  # Wrapped so we can place this at the top of the file.
  def self.define_operators # :nodoc:

    # Defaults
    defaults do

      def_delegators :'singleton_class', :forced?, :force!, :forced

      def sql_operator
        name
      end

      def where_clause
        "%s %s '%s'"
      end

      def modify(query, field, *values)
        query.where [where_clause, field, sql_operator, *values]
        query
      end

      def label
        @label ||= self.class.name.to_sym
      end
    end

    # Operators from Redmine
    new ">t-", :label => :label_less_than_ago do
      include DateRange
      def modify(query, field, value)
        super query, field, -value.to_i, 0
      end
    end

    new "w", :arity => 0, :label => :label_this_week do
      def modify(query, field, offset = nil)
        offset  ||= 0
        first_day = begin
          Integer I18n.t(:general_first_day_of_week)
        rescue ArgumentError
          1 # assume mondays
        end

        from  = Time.now.at_beginning_of_week + ((first_day % 7) - 1).days
        from -= offset.days
        '<>d'.to_operator.modify query, field, from, from + 7.days
      end
    end

    new "t+", :label => :label_in do
      include DateRange
      def modify(query, field, *values)
        super query, field, values.first.to_i, values.first.to_i
      end
    end

    new "<=", :label => :label_less_or_equal

    new "!", :label => :label_not_equals do
      def modify(query, field, *values)
        where_clause = "(#{field} IS NULL"
        where_clause += " OR #{field} NOT IN #{collection(*values)}" unless values.compact.empty?
        where_clause += ")"
        query.where where_clause
        query
      end
    end

    new "t-", :label => :label_ago do
      include DateRange
      def modify(query, field, *values)
        super query, field, -values.first.to_i, -values.first.to_i
      end
    end

    new "!~", :arity => 1, :label => :label_not_contains do
      def modify(query, field, *values)
        value = values.first || ''
        query.where "LOWER(#{field}) NOT LIKE '%#{quote_string(value.to_s.downcase)}%'"
        query
      end
    end

    new "=", :label => :label_equals do
      def modify(query, field, *values)
        case
        when values.size == 1 && values.first.nil?
          query.where "#{field} IS NULL"
        when values.compact.empty?
          query.where "1=0"
        else
          query.where "#{field} IN #{collection(*values)}"
        end
        query
      end
    end

    new "~", :arity => 1, :label => :label_contains do
      def modify(query, field, *values)
        value = values.first || ''
        query.where "LOWER(#{field}) LIKE '%#{quote_string(value.to_s.downcase)}%'"
        query
      end
    end

    new "<t+", :label => :label_in_less_than do
      include DateRange
      def modify(query, field, value)
        super query, field, 0, value.to_i
      end
    end

    new "t", :label => :label_today do
      include DateRange
      def modify(query, field)
        super query, field, 0, 0
      end
    end

    new ">=", :label => :label_greater_or_equal

    new "!*", :arity => 0, :where_clause => "%s IS NULL", :label => :label_none

    new "<t-", :label => :label_more_than_ago do
      include DateRange
      def modify(query, field, value)
        super query, field, nil, -value.to_i
      end
    end

    new ">t+", :label => :label_in_more_than do
      include DateRange
      def modify(query, field, value)
        super query, field, value.to_i, nil
      end
    end

    new "*", :arity => 0, :where_clause => "%s IS NOT NULL", :label => :label_all

    # Our own operators
    new "<", :label => :label_less
    new ">", :label => :label_greater

    new "=n", :label => :label_equals do
      def modify(query, field, value)
        query.where "#{field} = #{clean_currency(value)}"
        query
      end
    end

    new "0", :label => :label_none, :where_clause => "%s = 0"
    new "y", :label => :label_yes, :arity => 0, :where_clause => "%s IS NOT NULL"
    new "n", :label => :label_no, :arity => 0, :where_clause => "%s IS NULL"

    new "<d", :label => :label_less_or_equal, :validate => :dates do
      def modify(query, field, value)
        return query if value.to_s.empty?
        "<=".to_operator.modify query, field, quoted_date(value)
      end
    end

    new ">d", :label => :label_greater_or_equal, :validate => :dates do
      def modify(query, field, value)
        return query if value.to_s.empty?
        ">=".to_operator.modify query, field, quoted_date(value)
      end
    end

    new "<>d", :label => :label_between, :validate => :dates do
      def modify(query, field, from, to)
        return query if from.to_s.empty? || to.to_s.empty?
        query.where "#{field} BETWEEN '#{quoted_date from}' AND '#{quoted_date to}'"
        query
      end
    end

    new "=d", :label => :label_date_on, :validate => :dates do
      def modify(query, field, value)
        return query if value.to_s.empty?
        "=".to_operator.modify query, field, quoted_date(value)
      end
    end

    new ">=d", :label => :label_days_ago, :validate => :integers do
      force! :integers

      def modify(query, field, value)
        now = Time.now
        from = (now - value.to_i.days).beginning_of_day
        '<>d'.to_operator.modify query, field, from, now
      end
    end

    new "?=", :label => :label_null_or_equal do
      def modify(query, field, *values)
        where_clause = "(#{field} IS NULL"
        where_clause += " OR #{field} IN #{collection(*values)}" unless values.compact.empty?
        where_clause += ")"
        query.where where_clause
        query
      end
    end

    new "?!", :label => :label_not_null_and_not_equal do
      def modify(query, field, *values)
        where_clause = "(#{field} IS NOT NULL"
        where_clause += " AND #{field} NOT IN #{collection(*values)}" unless values.compact.empty?
        where_clause += ")"
        query.where where_clause
        query
      end
    end

  end
  #############################################################################################

  module CoreExt
    ::String.send :include, self
    ::Symbol.send :include, self
    def to_operator
      Report::Operator.find self
    end
  end

  def self.force!(type)
    @force = type
  end

  def self.forced?
    !!@force
  end

  def self.forced
    @force
  end

  def self.new(name, values = {}, &block)
    all[name.to_s] ||= super
  end

  #TODO: this should be inheritable by subclasses
  def self.all
    @@all_operators ||= {}
  end

  def self.load
    return if @done
    @done = true
    define_operators
  end

  def self.find(name)
    all[name.to_s] or raise ArgumentError, "Operator #{name.inspect} not defined"
  end

  def self.exists?(name)
    all.has_key?(name.to_s)
  end

  def self.defaults(&block)
    class_eval &block
  end

  def self.default_operator
    find "="
  end

  def self.integer_operators
    ["<", ">", "<=", ">="].map { |s| s.to_operator}
  end

  def self.null_operators
    ["*", "!*"].map { |s| s.to_operator}
  end

  def self.string_operators
    ["!~", "~"].map { |s| s.to_operator}
  end

  def self.time_operators
    #["t-", "t+", ">t-", "<t-", ">t+", "<t+"].map { |s| s.to_operator}
    ["t", "w", "<>d", ">d", "<d", "=d", ">=d"].map { |s| s.to_operator}
  end

  def self.default_operators
    ["=", "!"].map { |s| s.to_operator}
  end

  attr_reader :name

  def initialize(name, values = {}, &block)
    @name = name.to_s
    validation_methods = values.delete(:validate)
    register_validations(validation_methods) unless validation_methods.nil?
    values.each do |key, value|
      singleton_class.class_eval { define_method(key) { value } }
    end
    singleton_class.class_eval(&block) if block
  end

  def to_operator
    self
  end

  def to_s
    name
  end

  def arity
    @arity ||= begin
      num = method(:modify).arity
      # modify takes two more arguments before the values
      num < 0 ? num + 2 : num - 2
    end
  end

  def inspect
    "#<#{self.class.name}:#{name.inspect}>"
  end

  def <=>(other)
    self.name <=> other.name
  end

  ## Creates an alias for a given operator.
  def aka(alt_name, alt_label)
    all = self.class.all
    alt = alt_name.to_s
    raise ArgumentError, "Can't alias operator with an existing one's name ( #{alt} )." if all.has_key?(alt)
    op = all[name].clone
    op.send(:rename_to, alt_name)
    op.singleton_class.send(:define_method, 'label') { alt_label }
    all[alt] = op
  end

  module DateRange
    def modify(query, field, from, to)
      query.where ["#{field} > '%s'", quoted_date((Date.yesterday + from).to_time.end_of_day)] if from
      query.where ["#{field} <= '%s'", quoted_date((Date.today + to).to_time.end_of_day)] if to
      query
    end
  end

  private

  def rename_to(new_name)
    @name = new_name
  end

  # Done with class method definition, let's initialize the operators
  load

end
