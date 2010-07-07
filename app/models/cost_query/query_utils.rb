module CostQuery::QueryUtils
  include Redmine::I18n
  delegate :quoted_false, :quoted_true, :to => "ActiveRecord::Base.connection"

  ##
  # Graceful string quoting.
  #
  # @param [Object] str String to quote
  # @return [Object] Quoted version
  def quote_string(str)
    return str unless str.respond_to? :to_str
    ActiveRecord::Base.connection.quote_string(str)
  end

  ##
  # Graceful, internationalized quoted string.
  #
  # @see quote_string
  # @param [Object] str String to quote/translate
  # @return [Object] Quoted, translated version
  def quoted_label(ident)
    "'#{quote_string l(ident)}'"
  end

  ##
  # Creates a SQL fragment representing a collection/array.
  #
  # @see quote_string
  # @param [#flatten] *values Ruby collection
  # @return [String] SQL collection
  def collection(*values)
    "(#{values.flatten.map { |v| "'#{quote_string(v)}'" }.join ", "})"
  end

  def quoted_date(date)
    ActiveRecord::Base.connection.quoted_date date.to_dateish
  end

  ##
  # SQL date quoting.
  # @param [Date,Time] date Date to quote.
  # @return [String] Quoted date.
  def quote_date(date)
    "'#{quoted_date date}'"
  end

  ##
  # Generate a table name for any object.
  #
  # @example Table names
  #   table_name_for Issue    # => 'issues'
  #   table_name_for :issue   # => 'issues'
  #   table_name_for "issue"  # => 'issues'
  #   table_name_for "issues" # => 'issues
  #
  # @param [#table_name, #to_s] object Object you need the table name for.
  # @return [String] The table name.
  def table_name_for(object)
    return object.table_name if object.respond_to? :table_name
    object.to_s.tableize
  end

  ##
  # Generate a field name
  #
  # @example Field names
  #   field_name_for nil                            # => 'NULL'
  #   field_name_for 'foo'                          # => 'foo'
  #   field_name_for [Issue, 'project_id']          # => 'issues.project_id'
  #   field_name_for [:issue, 'project_id'], :entry # => 'issues.project_id'
  #   field_name_for 'project_id', :entry           # => 'entries.project_id'
  #
  # @param [Array, Object] arg Object to generate field name for.
  # @param [Object, optional] default_table Table name to use if no table name is given.
  # @return [String] Field name.
  def field_name_for(arg, default_table = nil)
    return 'NULL' unless arg
    return table_name_for(arg.first || default_table) + '.' << arg.last.to_s if arg.is_a? Array and arg.size == 2
    return arg.to_s unless default_table
    field_name_for [default_table, arg]
  end

  ##
  # Sanitizes sql condition
  #
  # @see ActiveRecord::Base#sanitize_sql_for_conditions
  # @param [Object] statement Not sanitized statement.
  # @return [String] Sanitized statement.
  def sanitize_sql_for_conditions(statement)
    CostQuery.send :sanitize_sql_for_conditions, statement
  end

  ##
  # Generates string representation for a currency.
  #
  # @see CostRate.clean_currency
  # @param [BigDecimal] value
  # @return [String]
  def clean_currency(value)
    CostRate.clean_currency(value).to_f.to_s
  end

  ##
  # Generates a SQL case statement.
  #
  # @example
  #   switch "#{table}.overridden_costs IS NULL" => [model, :costs], :else => [model, :overridden_costs]
  #
  # @param [Hash] options Condition => Result.
  # @return [String] Case statement.
  def switch(options)
    options = options.with_indifferent_access
    else_part = options.delete :else
    "CASE #{options.map { |k,v| "WHEN #{field_name_for k} THEN #{field_name_for v}" }} ELSE #{field_name_for else_part} END"
  end

  def self.included(klass)
    super
    klass.extend self
  end
end