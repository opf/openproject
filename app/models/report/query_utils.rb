module Report::QueryUtils
  delegate :quoted_false, :quoted_true, :to => "ActiveRecord::Base.connection"

  ##
  # Subclass of Report to be used for constant lookup and such.
  # It is considered public API to override this method i.e. in Tests.
  #
  # @return [Class] subclass
  def engine
    return self.class.engine unless is_a? Module
    Object.const_get name[/^[^:]+/]
  end

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
    return arg if arg.is_a? String and arg =~ /\.| |\(.*\)/
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
    Report.send :sanitize_sql_for_conditions, statement
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
    desc = "#{__method__} #{options.inspect[1..-2]}".gsub(/(Cost|Time)Entry\([^\)]*\)/, '\1Entry')
    options = options.with_indifferent_access
    else_part = options.delete :else
    "-- #{desc}\n\t" \
    "CASE #{options.map { |k,v| "\n\t\tWHEN #{field_name_for k}\n\t\t" \
    "THEN #{field_name_for v}" }}\n\t\tELSE #{field_name_for else_part}\n\tEND"
  end

  def typed(type, value, escape = true)
    value = "'#{quote_string value}'" if escape
    return value unless postgresql?
    "#{value}::#{type}"
  end

  def iso_year_week(field, default_table = nil)
    field = field_name_for(field, default_table)
    "-- code specific for #{adapter_name}\n\t" << \
    if mysql?
      "yearweek(#{field}, 1)"
    elsif postgresql?
      "(EXTRACT(isoyear from #{field})*100 + \n\t\t" \
      "EXTRACT(week from #{field} - \n\t\t" \
      "(EXTRACT(dow FROM #{field})::int+6)%7))"
    elsif sqlite?
      # enjoy
      <<-EOS
        case
        when strftime('%W', strftime('%Y-01-04', #{field})) = '00' then
          -- 01/01 is in week 1 of the current year => %W == week - 1
          case
          when strftime('%W', #{field}) = '52' and strftime('%W', (strftime('%Y', #{field}) + 1) || '-01-04') = '00' then
            -- we are at the end of the year, and it's the first week of the next year
            (strftime('%Y', #{field}) + 1) || '01'
          when strftime('%W', #{field}) < '08' then
            -- we are in week 1 to 9
            strftime('%Y0', #{field}) || (strftime('%W', #{field}) + 1)
          else
            -- we are in week 10 or later
            strftime('%Y', #{field}) || (strftime('%W', #{field}) + 1)
          end
        else
            -- 01/01 is in week 53 of the last year
            case
            when strftime('%W', #{field}) = '52' and strftime('%W', (strftime('%Y', #{field}) + 1) || '-01-01') = '00' then
              -- we are at the end of the year, and it's the first week of the next year
              (strftime('%Y', #{field}) + 1) || '01'
            when strftime('%W', #{field}) = '00' then
              -- we are in the week belonging to last year
              (strftime('%Y', #{field}) - 1) || '53'
            else
              -- everything is fine
              strftime('%Y%W', #{field})
            end
        end
      EOS
    else
      fail "#{adapter_name} not supported"
    end
  end

  def map_field(key, value)
    if key.to_s == "singleton_value"
      value.to_i
    else
      value.to_s
    end
  end

  def adapter_name
    ActiveRecord::Base.connection.adapter_name.downcase.to_sym
  end

  def cache
    Report::QueryUtils.cache
  end

  def mysql?
    [:mysql, :mysql2].include? adapter_name.to_s.downcase.to_sym
  end

  def sqlite?
    adapter_name == :sqlite
  end

  def postgresql?
    adapter_name == :postgresql
  end

  def self.cache
    @cache ||= Hash.new { |h,k| h[k] = {} }
  end

  def self.included(klass)
    super
    klass.extend self
  end
end