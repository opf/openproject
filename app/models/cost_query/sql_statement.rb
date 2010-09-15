class CostQuery::SqlStatement
  class Union
    attr_accessor :first, :second, :as
    def initialize(first, second, as = nil)
      @first, @second, @as = first, second, as
    end

    def to_s
      "((\n#{first.gsub("\n", "\n\t")}\n) UNION (\n" \
      "#{second.gsub("\n", "\n\t")}\n))#{" AS #{as}" if as}\n"
    end

    def each_subselect
      yield first
      yield second
    end

    def gsub(*args, &block)
      to_s.gsub(*args, &block)
    end
  end

  include CostQuery::QueryUtils
  attr_accessor :desc

  COMMON_FIELDS = %w[
    user_id project_id issue_id rate_id
    comments spent_on created_on updated_on tyear tmonth tweek
    costs overridden_costs type
  ]

  ##
  # Generates new SqlStatement.
  #
  # @param [String, #to_s] table Table name (or subselect) for from part.
  def initialize(table)
    from table
  end

  ##
  # Generates SqlStatement that maps time_entries and cost_entries to a common structure.
  #
  # Mapping for direct fields:
  #
  #   Result                    | Time Entires             | Cost entries
  #   --------------------------|--------------------------|--------------------------
  #   id                        | id                       | id
  #   user_id                   | user_id                  | user_id
  #   project_id                | project_id               | project_id
  #   issue_id                  | issue_id                 | issue_id
  #   rate_id                   | rate_id                  | rate_id
  #   comments                  | comments                 | comments
  #   spent_on                  | spent_on                 | spent_on
  #   created_on                | created_on               | created_on
  #   updated_on                | updated_on               | updated_on
  #   tyear                     | tyear                    | tyear
  #   tmonth                    | tmonth                   | tmonth
  #   tweek                     | tweek                    | tweek
  #   costs                     | costs                    | costs
  #   overridden_costs          | overridden_costs         | overridden_costs
  #   units                     | hours                    | units
  #   activity_id               | activity_id              | -1
  #   cost_type_id              | -1                       | cost_type_id
  #   type                      | "TimeEntry"              | "CostEntry"
  #   count                     | 1                        | 1
  #
  # Also: This _should_ handle joining activities and cost_types, as the logic differs for time_entries
  # and cost_entries.
  #
  # @param [#table_name] model The model to map
  # @return [CostQuery::SqlStatement] Generated statement
  def self.unified_entry(model)
    table = table_name_for model
    new(table).tap do |query|
      query.select COMMON_FIELDS
      query.desc = "Subquery for #{table}"
      query.select({
        :count => 1, :id => [model, :id], :display_costs => 1,
        :real_costs => switch("#{table}.overridden_costs IS NULL" => [model, :costs], :else => [model, :overridden_costs]),
        :week => iso_year_week(:spent_on, model)
      })
      #FIXME: build this subquery from a sql_statement
      query.from "(SELECT *, #{typed :text, model.model_name} AS type FROM #{table}) AS #{table}"
      send("unify_#{table}", query)
    end
  end

  ##
  # Applies logic for mapping time entries to general entries structure.
  #
  # @param [CostQuery::SqlStatement] query The statement to adjust
  def self.unify_time_entries(query)
    query.select :activity_id, :units => :hours, :cost_type_id => -1
    query.select :cost_type => quoted_label(:caption_labor)
  end

  ##
  # Applies logic for mapping cost entries to general entries structure.
  #
  # @param [CostQuery::SqlStatement] query The statement to adjust
  def self.unify_cost_entries(query)
    query.select :units, :cost_type_id, :activity_id => -1
    query.select :cost_type => "cost_types.name"
    query.join CostType
  end

  ##
  # Generates a statement based on all entries (i.e. time entries and cost entries) mapped to the general entries structure,
  # and therefore usable by filters and such.
  #
  # @return [CostQuery::SqlStatement] Generated statement
  def self.for_entries
    new unified_entry(TimeEntry).union(unified_entry(CostEntry), "entries")
  end

  ##
  # Creates a uninon of the caller and the callee.
  #
  # @param [CostQuery::SqlStatement] other Second part of the union
  # @return [String] The sql query.
  def union(other, as = nil)
    Union.new(self, other, as)
  end

  ##
  # Adds sum(..) part to select.
  #
  # @param [#to_s] field Name of the field to aggregate on
  # @param [#to_s] name Name of the result (defaults to sum)
  def sum(field, name = :sum, type = :sum)
    @sql = nil
    return sum({ name => field }, nil, type) unless field.respond_to? :to_hash
    field.each { |k,v| field[k] = "#{type}(#{v})" }
    select field
  end

  ##
  # Adds count(..) part to select.
  #
  # @param [#to_s] field Name of the field to aggregate on (defaults to *)
  # @param [#to_s] name Name of the result (defaults to sum)
  def count(field = "*", name = :count)
    sum field, name, :count
  end

  ##
  # Generates the SQL query.
  # Code looks ugly in exchange for pretty output (so one does unterstand those).
  #
  # @return [String] The query
  def to_s
    # FIXME I'm ugly
    @sql ||= begin
      sql = "\n-- BEGIN #{desc}\n" \
      "SELECT\n#{select.map { |e| "\t#{e}" }.join ",\n"}" \
      "\nFROM\n\t#{from.gsub("\n", "\n\t")}" \
      "\n\t#{joins.map { |e| e.gsub("\n", "\n\t") }.join "\n\t"}" \
      "\nWHERE #{where.join " AND "}\n"
      sql << "GROUP BY #{group_by.join ', '}\nORDER BY #{group_by.join ', '}\n" if group_by?
      sql << "-- END #{desc}\n"
      sql.gsub!('--', '#') if mysql?
      sql # << " LIMIT 100"
    end
  end

  ##
  # @overload from
  #   Reads the from part.
  #   @return [#to_s] From part
  # @overload from(table)
  #   Sets the from part.
  #   @param [#to_s] table
  #   @param [#to_s] From part
  def from(table = nil)
    return @from unless table
    @sql = nil
    @from = table
  end

  ##
  # Where conditions. Will be joined together by AND.
  #
  # @overload where
  #   Reads the where part
  #   @return [Array<#to_s>] Where clauses
  # @overload where(fields)
  #   Adds condition to where clause
  #   @param [Array, Hash, String] fields Parameters passed to sanitize_sql_for_conditions.
  # @see CostQuery::QueryUtils#sanitize_sql_for_conditions
  def where(fields = nil)
    @where ||= ["1=1"]
    unless fields.nil?
      @where << sanitize_sql_for_conditions(fields)
      @sql = nil
    end
    @where
  end

  ##
  # @return [Array<String>] List of table joins
  def joins
    (@joins ||= []).tap { |j| j.uniq! }
  end

  ##
  # Adds an "left outer join" (guessing field names) to #joins.
  #
  # @overload join(name)
  #   @param [Symbol, String] name Singular table name to join with, will join plural from on table.id = table_id
  # @overload join(model)
  #   @param [#table_name, #model_name] model ActiveRecord model to join with
  # @overload join(hash)
  #   @param [Hash<#to_s => #to_s>] hash Key is singular table name to join with, value is field to join on
  # @overload join(*list)
  #   @param [Array<String,Symbol,Array>] list Will generate join entries (according to guessings described above)
  # @see #joins
  def join(*list)
    @sql = nil
    join_syntax = "LEFT OUTER JOIN %1$s ON %1$s.id = %2$s_id"
    list.each do |e|
      case e
      when Class          then joins << (join_syntax % [table_name_for(e), e.model_name.underscore])
      when / /            then joins << e
      when Symbol, String then joins << (join_syntax % [table_name_for(e), e])
      when Hash           then e.each { |k,v| joins << (join_syntax % [table_name_for(k), field_name_for(v)]) }
      when Array          then join(*e)
      else raise ArgumentError, "cannot join #{e.inspect}"
      end
    end
  end

  ##
  # @overload select
  #   @return [Array<String>] All fields/statements for select part
  #
  # @overload select(*fields)
  #   Adds fields to select query.
  #   @example
  #     SqlStatement.new.select(some_sql_statement) # [some_sql_statement.to_s]
  #     SqlStatement.new.select("sum(foo)")         # ["sum(foo)"]
  #     SqlStatement.new.select(:a).select(:b)      # ["a", "b"]
  #     SqlStatement.new.select(:bar => :foo)       # ["foo as bar"]
  #     SqlStatement.new.select(:bar => nil)        # ["NULL as bar"]
  #   @param [Array, Hash, String, Symbol, SqlStatement] fields Fields to add to select part
  #   @return [Array<String>] All fields/statements for select part
  def select(*fields)
    return(@select || ["*"]) if fields.empty?
    returning(@select ||= []) do
      @sql = nil
      fields.each do |f|
        case f
        when Array
          if f.size == 2 and f.first.respond_to? :table_name then select field_name_for(f)
          else select(*f)
          end
        when Hash then select f.map { |k,v| "#{field_name_for v} as #{field_name_for k}" }
        when String, Symbol then @select << field_name_for(f)
        when CostQuery::SqlStatement then @select << f.to_s
        else raise ArgumentError, "cannot handle #{f.inspect}"
        end
      end
      # when doing a union in sql, both subselects must have the same order.
      # by sorting here we never ever have to worry about this again, sucker!
      @select = @select.uniq.sort_by { |x| x.split(" as ").last }
    end
  end

  ##
  # @overload group_by
  #   @return [Array<String>] All fields/statements for group by part
  #
  # @overload group(*fields)
  #   Adds fields to group by query
  #   @param [Array, String, Symbol] fields Fields to add
  def group_by(*fields)
    @sql = nil unless fields.empty?
    returning(@group_by ||= []) do
      fields.each do |e|
        if e.is_a? Array and (e.size != 2 or !e.first.respond_to? :table_name)
          group_by(*e)
        else
          @group_by << field_name_for(e)
        end
      end
      @group_by.uniq!
    end
  end

  ##
  # @return [TrueClass, FalseClass] Whether or not to add a group by part.
  def group_by?
    !group_by.empty?
  end

  def inspect
    "#<SqlStatement: #{to_s.inspect}>"
  end

  def gsub(*args, &block)
    to_s.gsub(*args, &block)
  end

end
