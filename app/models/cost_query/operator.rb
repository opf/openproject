class CostQuery::Operator
  include CostQuery::QueryUtils
  include CostQuery::Validation

  #############################################################################################
  # Wrapped so we can place this at the top of the file.
  def self.define_operators # :nodoc:

    # Defaults
    defaults do
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
        @label ||= Query.operators[name]
      end
    end

    # Operators from Redmine
    new ">t-" do
      include DateRange
      def modify(query, field, value)
        super query, field, -value.to_i, 0
      end
    end

    new "w", :arity => 0 do
      def modify(query, field, offset = nil)
        offset ||= 0
        from = Time.now.at_beginning_of_week - ((l(:general_first_day_of_week).to_i % 7) + 1).days
        from -= offset.days
        '<>d'.to_operator.modify query, field, from, from + 7.days
      end
    end

    new "t+" do
      include DateRange
      def modify(query, field, *values)
        super query, field, values.first.to_i, values.first.to_i
      end
    end

    new "<="

    new "!" do
      def modify(query, field, *values)
        where_clause = "(#{field} IS NULL"
        where_clause += " OR #{field} NOT IN #{collection(*values)}" unless values.compact.empty?
        where_clause += ")"
        query.where where_clause
        query
      end
    end

    new "t-" do
      include DateRange
      def modify(query, field, *values)
        super query, field, -values.first.to_i, -values.first.to_i
      end
    end

    new "c", :arity => 0 do
      def modify(query, field, *values)
        raise "wrong field" if field.to_s.split('.').last != "status_id"
        query.where "(#{IssueStatus.table_name}.is_closed = #{quoted_true})"
        query
      end
    end

    new "o", :arity => 0 do
      def modify(query, field, *values)
        raise "wrong field" if field.to_s.split('.').last != "status_id"
        query.where "(#{IssueStatus.table_name}.is_closed = #{quoted_false})"
        query
      end
    end

    new "!~", :arity => 1 do
      def modify(query, field, *values)
        value = values.first || ''
        query.where "LOWER(#{field}) NOT LIKE '%#{quote_string(value.to_s.downcase)}%'"
        query
      end
    end

    new "=" do
      def modify(query, field, *values)
        if values.compact.empty?
          query.where "1=0"
        else
          query.where "#{field} IN #{collection(*values)}"
        end
        query
      end
    end

    new "~", :arity => 1 do
      def modify(query, field, *values)
        value = values.first || ''
        query.where "LOWER(#{field}) LIKE '%#{quote_string(value.to_s.downcase)}%'"
        query
      end
    end

    new "<t+" do
      include DateRange
      def modify(query, field, value)
        super query, field, 0, value.to_i
      end
    end

    new "t" do
      include DateRange
      def modify(query, field)
        super query, field, 0, 0
      end
    end

    new ">="

    new "!*", :arity => 0, :where_clause => "%s IS NULL"

    new "<t-" do
      include DateRange
      def modify(query, field, value)
        super query, field, nil, -value.to_i
      end
    end

    new ">t+" do
      include DateRange
      def modify(query, field, value)
        super query, field, value.to_i, nil
      end
    end

    new "*", :arity => 0, :where_clause => "%s IS NOT NULL"

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
        "<".to_operator.modify query, field, quoted_date(value)
      end
    end

    new ">d", :label => :label_greater_or_equal, :validate => :dates do
      def modify(query, field, value)
        return query if value.to_s.empty?
        ">".to_operator.modify query, field, quoted_date(value)
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

    new "=_child_projects", :validate => :integers, :label => :label_is_project_with_subprojects do
      def modify(query, field, *values)
        p_ids = []
        values.each do |value|
          p_ids += ([value] << Project.find(value).descendants.map{ |p| p.id })
        end
        "=".to_operator.modify query, field, p_ids
      rescue ActiveRecord::RecordNotFound
        query
      end
    end

    new "!_child_projects", :validate => :integers, :label => :label_is_not_project_with_subprojects do
      def modify(query, field, *values)
        p_ids = []
        values.each do |value|
          p_ids += ([value] << Project.find(value).descendants.map{ |p| p.id })
        end
        "!".to_operator.modify query, field, p_ids
      rescue ActiveRecord::RecordNotFound
        query
      end
    end

  end
  #############################################################################################

  module CoreExt
    ::String.send :include, self
    ::Symbol.send :include, self
    def to_operator
      CostQuery::Operator.find self
    end
  end

  def self.new(name, values = {}, &block)
    all[name.to_s] ||= super
  end

  def self.all
    @all ||= {}
  end

  def self.load
    return if @done
    @done = true
    define_operators
  end

  def self.find(name)
    all[name.to_s] or raise ArgumentError, "Operator not defined"
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
    ["t", "w", "<>d", ">d", "<d", "=d"].map { |s| s.to_operator}
  end

  def self.default_operators
    ["=", "!"].map { |s| s.to_operator}
  end

  attr_reader :name

  def initialize(name, values = {}, &block)
    @name = name.to_s
    validation_methods = values.delete(:validate)
    register_validations(Array(validation_methods)) unless validation_methods.nil?
    values.each do |key, value|
      metaclass.class_eval { define_method(key) { value } }
    end
    metaclass.class_eval(&block) if block
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

  module DateRange
    def modify(query, field, from, to)
      query.where ["#{field} > '%s'", quoted_date((Date.yesterday + from).to_time.end_of_day)] if from
      query.where ["#{field} <= '%s'", quoted_date((Date.today + to).to_time.end_of_day)] if to
      query
    end
  end

  # Done with class method definition, let's initialize the operators
  load

end