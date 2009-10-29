require_dependency 'query'

class CostQueryColumn < QueryColumn
  attr_reader :scope
  
  def initialize(name, options={})
    self.scope = (optione.delete(:scope) || :issues)
    super
  end
end

class CostQueryCustomFieldColumn < QueryCustomFieldColumn
  attr_accessor :scope
  
  def initialize(custom_field)
    self.reader = :issues
    super
  end
end

class Filter
  # FIXME: this is redmine 0.8 specific
  # current trunk uses the I18n module instead of GLoc
  include GLoc


  def initialize(scope, column_name, column)
    @scope = scope
    @column_name = column_name
    @column = column
    
    @enabled = true
    
    default_operator = CostQuery.filter_types[@column[:type]][:default]
    @operator = default_operator if default_operator
  end
  attr_reader :scope, :column_name, :column
  
  attr_reader :values
  def values=(v)
    if available_values
      available_value_keys = available_values.collect {|o| o[1].to_s }
      # FIXME: HACK
      available_value_keys << User.current.id.to_s if available_value_keys.include? "me"
      v.each do |value|
        unless available_value_keys.include? value.to_s
          raise ArgumentError.new("Forbidden value (#{value.inspect} not in #{available_value_keys.inspect})")
        end
      end
    end
    
    @values = v
  end
  
  attr_reader :operator
  def operator=(o)
    raise ArgumentError.new("Forbidden operator #{o}") unless available_operators.include? o
    @operator = o
  end
  
  attr_accessor :enabled
  
  def type_name
    @column[:type]
  end
  
  def label
    @column[:name] || l(("field_"+@column_name.gsub(/\_id$/, "")).to_sym)
  end
  
  def available_operators
    CostQuery.filter_types[@column[:type]][:operators]
  end
  
  def available_values
    @column[:values]
  end
  
  def new_record?
    return true
  end
end

class CostQuery < ActiveRecord::Base
  # FIXME: this is redmine 0.8 specific
  # current trunk uses the I18n module instead of GLoc
  include GLoc

  belongs_to :user
  belongs_to :project
  
  serialize :filters
  serialize :group_by
  
  attr_protected :user_id, :project_id, :created_at, :updated_at

  def after_initialize
    self.display_time_entries = true if display_time_entries.nil?
    self.display_cost_entries = true if display_cost_entries.nil?
    
    self.group_by ||= {}
  end
  
  def self.operators
    # These are the operators used by filter types.
    
    operators = {}
    issue_operators = Query.operators
    
    issue_operators.each_pair do |op, label|
      simple = (["!*", "*", "t", "w", "o", "c"].include? op)
      operators[op] = {:label => label, :simple => simple}
      
    end
    
    operators.merge(
      {
        "=n" => {:label => :label_equals, :simple => false},
        "0" => {:label => :label_none, :simple => true},
        "y" => {:label => :label_yes, :simple => true},
        "n" => {:label => :label_no, :simple => true},
        "<d" => {:label => :label_less_or_equal, :simple => false},
        ">d" => {:label => :label_greater_or_equal, :simple => false},
        "<>d" => {:label => :label_between, :simple => false},
        "=d" => {:label => :label_date_on, :simple => false}
      }
    )
  end
  
  def self.filter_types
    return @filter_types if @filter_types

    filter_types = Query.operators_by_filter_type.inject({}) do |r, f|
      multiple = !([:list, :list_status, :list_optional, :list_subproject].include? f[0])
      r[f[0]] = {:operators => f[1], :multiple => multiple}
      r
    end
    @filter_types = filter_types.merge( 
      {
        :integer_zero => {:operators => [ "=n", ">=", "<=", "0", "*" ], :multiple => true},
        :boolean => {:operators => [ "y", "n" ], :multiple => false},
        :date_exact => {:operators => [ "<d", ">d", "<>d", "=d", "t", "w"], :multiple => true, :default => "w"}
      }
    )
  end
  
  def available_filters
    # This available_filters is different from the Redmine one
    # available_filters[:issues]
    #     --> filters on issue fields. These are the one from redmine itself
    # available_filters[:costs]
    #    --> filters on cost and time entries
    
    return @available_filters if @available_filters

    @available_filters = {
      :costs => {
        "cost_type_id" => { :type => :list_optional, :order => 2, :applies => [:cost_entries], :flags => [], :db_table => CostType.table_name, :db_field => "id", :values => CostType.find(:all, :order => 'name').collect{|s| [s.name, s.id.to_s] }},
        # FIXME: this has to be changed for Redmine 0.9 as r2777 of Redmine introduces STI for enumerations
        "activity_id" => { :type => :list_optional, :order => 3, :applies => [:time_entries], :flags => [], :db_table => Enumeration.table_name, :db_field => "id", :values => Enumeration.find(:all, :conditions => {:opt => 'ACTI'}, :order => 'position').collect{|s| [s.name, s.id.to_s] }},
        "created_on" => { :type => :date_exact, :applies => [:time_entries, :cost_entries], :flags => [], :order => 4 },                        
        "updated_on" => { :type => :date_exact, :applies => [:time_entries, :cost_entries], :flags => [], :order => 5 },
        "spent_on" => { :type => :date_exact, :applies => [:time_entries, :cost_entries], :flags => [], :order => 6},
        "overridden_costs" => { :type => :boolean, :applies => [:time_entries, :cost_entries], :flags => [], :order => 7 },
        "issue_id" => { :type => :list_optional, :order => 8, :applies => [:cost_entries, :time_entries], :flags => [], :db_table => Issue.table_name, :db_field => "id", :values => Issue.find(:all, :order => :id).collect{|s| [s.subject, s.id.to_s] }},
      }
    }
    
    tmp_query = Query.new(:project => project, :name => "_")
    @available_filters[:issues] = tmp_query.available_filters
    # flag columns that contain filters for user columns
    @available_filters[:issues].each_pair do |k,v|
      v[:flags] = []
      v[:flags] << :user if %w(assigned_to_id author_id watcher_id).include?(k)
      if k =~ /^cf_(\d+)$/
        # custom field
        v[:db_table] = CustomValue.table_name
        v[:db_field] = 'value'
        v[:db_field_id] = $1 # this is the numeric part in the regex above
        v[:flags] << :custom_field
      elsif k == "watcher_id"
        v[:db_table] = Watcher.table_name
        v[:db_field] = 'user_id'
        v[:flags] << :watcher
      else
        if ["labor_costs", "material_costs", "overall_costs"].include? k
          v[:type] = :integer_zero
        end
        if [:date_past, :date].include? v[:type]
          v[:type] = :date_exact
        end
        v[:db_table] = Issue.table_name
        v[:db_field] = k
      end
    end
    
    if @available_filters[:issues]["author_id"]
      # add a filter on cost entries for user_id if it is available
      user_values = @available_filters[:issues]["author_id"][:values]
      @available_filters[:costs]["user_id"] = {:type => :list_optional, :order => 1, :applies => [:time_entries, :cost_entries], :values => user_values, :flags => [:user]}
    end
    
    @available_filters
  end
  
  def create_filter(scope, column_name)
    column = available_filters[scope][column_name]
    column ? Filter.new(scope, column_name, column) : nil
  end
  
  def create_filter_from_hash(filter_hash = {})
    scope = filter_hash[:scope].to_sym
    column_name =  filter_hash[:column_name]
    column = available_filters[scope][column_name]

    f = Filter.new(scope, column_name, column)
    f.enabled = filter_hash[:enabled] unless filter_hash[:enabled].nil?
    f.operator = filter_hash[:operator] unless filter_hash[:operator].nil?
    f.values = filter_hash[:values] unless filter_hash[:values].nil?
    
    f
  end
  
  def has_filter?(scope, column_name)
    # returns the first matching filter or nil
    return nil unless filters
    
    match = filters.select {|f| f.scope == scope && f.column_name = column_name}
    return match.blank? ? nil : match[0]
  end
  
  MAGIC_GROUP_KEYS = [:block, :time, :display, :db_field]
  
  def self.grouping_column(*names, &block)
    options = names.extract_options!
    names.each do |name|
      group_by_columns[name] = options.with_indifferent_access.merge(
        :block => block,
        :scope => grouping_scope
      )
      group_by_columns[name][:db_field] ||= name
      group_by_columns[name][:display] ||= Proc.new { |e| e }
      group_by_columns[name][:other_group] ||= "<em>#{l :group_by_others}</em>"
    end
  end
  
  def self.grouping_scope(type = nil)
    @grouping_scope = type || @grouping_scope
    yield if block_given?
    @grouping_scope
  end
  
  def self.group_by_columns
    @group_by_columns ||= {}.with_indifferent_access
  end
  
  def self.get_name(key, value)
    return group_by_columns[key][:other_group] unless value
    group_by_columns[key][:display].call value
  end
  
  def self.from_field(klass, field)
    Proc.new do |id|
      a = klass.find_by_id(id)
      (a ? a.send(field) : id).to_s
    end
  end

  grouping_scope(:issues) do
    grouping_column(:tracker_id, :fixed_version_id, :subproject_id)
    grouping_column(:cost_object_id, :display => from_field(CostObject, :subject))
  end
  
  grouping_scope(:costs) do
    grouping_column :user_id, :display => from_field(User, :name)
    grouping_column :issue_id, :display => from_field(Issue, :subject)
    grouping_column :cost_type_id, :diplay => from_field(CostType, :name), :other_group => l(:caption_labor_costs)
    grouping_column :activity_id, :display => from_field(Enumeration, :name)
    grouping_column(:spent_on, :tyear, :tmonth, :tweek, :time => true) do |column, fields|
      values = []
      
      if fields["spent_on"]
        values = [fields["spent_on"].to_date] * 2
      elsif fields["tyear"]
        if fields["tmonth"]
          start_of_month = Date.civil(fields["tyear"].to_i, fields["tmonth"].to_i , 1)
          values = [start_of_month.to_s, start_of_month.end_of_month.to_s]
        elsif fields["tweek"]
          start_of_week = Date.commercial(fields["tyear"].to_i, fields["tweek"].to_i, 1)
          values = [start_of_week.to_s, start_of_week.end_of_week.to_s]
        else
          start_of_year = Date.civil(fields["tyear"].to_i, 1, 1)
          values = [start_of_year.to_s, start_of_year.end_of_year.to_s]
        end
      end
      
      raise "Invalid group by values" if values.blank?

      {
       :operator => "<>d",
       :values => values,
       :column_name => :spent_on
      }

    end
  end
  
  def filter_from_group_by(fields)
    column_name = group_by[:name].to_sym
    data = self.class.group_by_columns[column_name].dup
    options = {}
    MAGIC_GROUP_KEYS.each do |key|
      options[key] = data.delete key
    end
    block = options[:block] || Proc.new { {} }
    {
      :enabled => 1,
      :operator => "=",
      :column_name => column_name,
      :values => fields[column_name.to_s],
    }.merge(data).merge(block.call(column_name, fields))    
  end
  

  def group_by_columns_for_select
    self.class.group_by_columns.inject([["", ""]]) do |list, (column_name, values)|
      filter = create_filter(values[:scope], column_name.to_s)
      list << [filter.label, column_name] if filter
      list
    end
  end
  
  def time_groups
    # returns an array of group_by names where time == true
    self.class.group_by_columns.inject([]) do |list, (column_name, values)|
      list << column_name if values[:time]
      list
    end
  end
  
  def project_statement
    project_clauses = []
    
    if project && !project.active_children.empty?
      ids = [project.id]
      if subprojects = has_filter?(:issues, "subproject_id")
        case subprojects.operator
        when "="
          # include the selected subprojects
          ids += subprojects.values.each(&:to_i)
        when "!*"
          # main project only
        else
          # all subprojects
          ids += project.descendants.collect(&:id)
        end
      elsif Setting.display_subprojects_issues?
        ids += project.descendants.collect(&:id)
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif project
      project_clauses << "#{Project.table_name}.id = %d" % project.id
    end
    
    # FIXME: Implement rights model here
    #project_clauses <<  Project.allowed_to_condition(User.current, :view_issues)
    if project_clauses.blank?
      "1=1"
    else
      project_clauses.join( 'AND ')
    end
  end
  
  def group_by_fields()
    # returns the db_fields of the current group by query
    
    return [] unless !group_by[:name].blank? && (data = group_by_columns[group_by[:name].to_sym])
    
    if data[:time]
      # We have a group_by_time
      return case group_by[:granularity]
               when "year" then ["tyear"]
               when "month" then ["tyear", "tmonth"]
               when "week" then ["tyear", "tweek"]
               else ["spent_on"]
             end
    else
      [data[:db_field]].flatten
    end
  end
  
  def group_by_columns
    self.class.group_by_columns
  end
  
  def sql_data_for(entry_scope)
    case entry_scope
    when :cost_entries
      model = CostEntry
    when :time_entries
      model = TimeEntry
      from_include_issue = false
    end
    
    my_fields, nil_fields, grouping_fields = [], [], []
    
    group_by_fields.each do |field|
      klass = group_by_columns[field.to_sym][:scope] == :issues ? Issue : model
      if klass.column_names.include? field.to_s
        grouping_fields << field
        my_fields << "#{klass.table_name}.#{field} as #{field}"
      else
        nil_fields << "NULL as #{field}"
      end
    end

    group_by = "GROUP BY #{grouping_fields.join(", ")}" unless grouping_fields.blank?
    [model, (my_fields + nil_fields).join(", "), from_statement(entry_scope), statement(entry_scope), group_by]
  end
  
  def from_statement(entry_scope, include_issue = false)
    case entry_scope
    when :cost_entries
      from = <<-EOS
        #{CostEntry.table_name}
        LEFT OUTER JOIN #{CostType.table_name} ON #{CostType.table_name}.id = #{CostEntry.table_name}.cost_type_id
        LEFT OUTER JOIN #{User.table_name} ON #{User.table_name}.id = #{CostEntry.table_name}.user_id
        LEFT OUTER JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{CostEntry.table_name}.issue_id
      EOS
    when :time_entries
      from = <<-EOS
        #{TimeEntry.table_name}
        LEFT OUTER JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{TimeEntry.table_name}.activity_id
        LEFT OUTER JOIN #{User.table_name} ON #{User.table_name}.id = #{TimeEntry.table_name}.user_id
        LEFT OUTER JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{TimeEntry.table_name}.issue_id
      EOS
    end
  end
  
  def statement(entry_scope)
    # entry_scope can currently be one of :cost_entries, :time_entries
    # To not mix this with the scope (aka :issues vs. :costs)
    
    issue_filter_clauses = []
    entry_filter_clauses = []
    if filters and valid?
      filters.each do |filter|
        filter = create_filter_from_hash(filter)
        
        if filter.column[:flags].include? :user
          filter.values = [filter.values] unless filter.values.is_a? Array
          filter.values.push(User.current.logged? ? User.current.id.to_s : "0") if filter.values.delete("me")
        end
        
        sql = ''
        
        case filter.scope
        when :issues
          if filter.column[:flags].include? :custom_field
            sql << "#{Issue.table_name}.id IN ("
            sql << "  SELECT #{Issue.table_name}.id FROM #{Issue.table_name} LEFT OUTER JOIN #{filter.column[:db_table]} ON #{filter.column[:db_table]}.customized_type='Issue' AND #{filter.column[:db_table]}.customized_id=#{Issue.table_name}.id AND #{filter.column[:db_table]}.custom_field_id=#{filter.column[:db_field_id]} WHERE "
            sql <<    sql_for_filter(filter, nil, true)
            sql << ")"
          elsif filter.column[:flags].include? :watcher
            sql << "#{Issue.table_name}.id #{ field.operator == '=' ? 'IN' : 'NOT IN' } ("
            sql << "  SELECT #{filter.column[:db_table]}.watchable_id FROM #{filter.column[:db_table]} WHERE #{filter.column[:db_table]}.watchable_type='Issue' AND "
            sql <<    sql_for_filter(filter)
            sql << ")"
          else
            sql << '(' + sql_for_filter(filter) + ')'
          end
          issue_filter_clauses << sql
        when :costs
          sql << '(' + sql_for_filter(filter, entry_scope) + ')'
          entry_filter_clauses << sql
        end
      end
    end
    
    issue_filter_clauses = ["1=1"] if issue_filter_clauses.blank?
    # FIXME: This is a hack calling a private ActiveRecord methods
    # from http://pivotallabs.com/users/jsusser/blog/articles/567-hacking-a-subselect-in-activerecord

    from =  "#{Issue.table_name}"
    from << " LEFT OUTER JOIN #{User.table_name} ON #{User.table_name}.id = #{Issue.table_name}.assigned_to_id"
    from << " LEFT OUTER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id"
    from << " LEFT OUTER JOIN #{Tracker.table_name} ON #{Tracker.table_name}.id = #{Issue.table_name}.tracker_id"
    from << " LEFT OUTER JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Issue.table_name}.project_id"
    from << " LEFT OUTER JOIN #{Enumeration.table_name} ON #{Enumeration.table_name}.id = #{Issue.table_name}.priority_id"
    from << " LEFT OUTER JOIN #{IssueCategory.table_name} ON #{IssueCategory.table_name}.id = #{Issue.table_name}.category_id"
    from << " LEFT OUTER JOIN #{Version.table_name} ON #{Version.table_name}.id = #{Issue.table_name}.fixed_version_id"
    
    issue_ids = Issue.send(
                  :construct_finder_sql,
                    :select => "#{Issue.table_name}.id",
                    #:include => [ :assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version ],
                    :from => from,
                    :conditions => (issue_filter_clauses << project_statement).join(' AND '))

    case entry_scope
    when :cost_entries
      entry_filter_clauses << "#{CostEntry.table_name}.issue_id IN (#{issue_ids})"
    when :time_entries
      entry_filter_clauses << "#{TimeEntry.table_name}.issue_id IN (#{issue_ids})"
    end
    
    entry_filter_clauses.join(' AND ')
  end
  


  def sort_criteria=(arg)
    c = []
    if arg.is_a?(Hash)
      arg = arg.keys.sort.collect {|k| arg[k]}
    end
    c = arg.select {|k,o| !k.to_s.blank?}.slice(0,3).collect {|k,o| [k.to_s, o == 'desc' ? o : 'asc']}
    write_attribute(:sort_criteria, c)
  end

  def sort_criteria
    read_attribute(:sort_criteria) || []
  end

  def sort_criteria_key(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].first
  end

  def sort_criteria_order(arg)
    sort_criteria && sort_criteria[arg] && sort_criteria[arg].last
  end


private
  def sql_for_filter(filter, entry_scope = nil, string_as_null = false)
    db_table = filter.column[:db_table]
    if filter.scope == :costs && !db_table
      case entry_scope
      when :cost_entries
        db_table = CostEntry.table_name
      when :time_entries
        db_table = TimeEntry.table_name
      else
        raise "Need a valid entry scope. Got #{entry_scope.inspect}" unless entry_scope
      end
    end
    
    if filter.scope == :costs && (!filter.column[:applies].include? entry_scope)
      # the current filter does not match the entry_scope so we just ignore it
      return "1=1"
    end
    
    db_field = filter.column[:db_field] || filter.column_name
    
    # Does not work for Redmine 0.8
    #@sql_for_filter_query = Query.new(:name => "_") unless @sql_for_filter_query
    #sql = @sql_for_filter_query.send(
    #  :sql_for_field,
    #  filter.column_name, filter.operator, filter.values, db_table, db_field, string_as_null)

    sql = sql_for_field(filter.column_name, filter.operator, filter.values, db_table, db_field, string_as_null)
    return sql unless sql == "1=1"
    
    # We have an operator that was added by us. So we provide the logic here
    case filter.operator
    when "0"
      sql = "#{db_table}.#{db_field} = 0"
    when "y"
      sql = "#{db_table}.#{db_field} IS NOT NULL"
    when "n"
      sql = "#{db_table}.#{db_field} IS NULL"
    when "=n"
      sql = "#{db_table}.#{db_field} = #{CostRate.clean_currency(filter.values).to_f.to_s}"
    when "<>d"
      begin
        date1 = filter.values.first.to_date
        date2 = filter.values.last.to_date
        sql = "#{db_table}.#{db_field} BETWEEN '#{connection.quoted_date(date1)}' AND '#{connection.quoted_date(date2)}'"
      rescue
      end
    when ">d"
      begin
        date = filter.values.first.to_date
        sql = "#{db_table}.#{db_field} >= '#{connection.quoted_date(date)}'"
      rescue
      end
    when "<d"
      begin
        date = filter.values.first.to_date
        sql = "#{db_table}.#{db_field} <= '#{connection.quoted_date(date)}'"
      rescue
      end
    when "=d"
      begin
        date = filter.values.first.to_date
        sql = "#{db_table}.#{db_field} = '#{connection.quoted_date(date)}'"
      rescue
      end
    end
    
    return sql
  end
  
  # Helper method to generate the WHERE sql for a +field+, +operator+ and a +value+
  # FIXME: This methods comes from redmine trunk. Delete this one and call the one from redmine instead!
  def sql_for_field(field, operator, value, db_table, db_field, is_custom_filter=false)
    sql = ''
    case operator
    when "="
      sql = "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")" unless value.blank?
    when "!"
      sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
    when "!*"
      sql = "#{db_table}.#{db_field} IS NULL"
      sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
    when "*"
      sql = "#{db_table}.#{db_field} IS NOT NULL"
      sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
    when ">="
      sql = "#{db_table}.#{db_field} >= #{value.first.to_i}"
    when "<="
      sql = "#{db_table}.#{db_field} <= #{value.first.to_i}"
    when "o"
      sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
    when "c"
      sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
    when ">t-"
      sql = date_range_clause(db_table, db_field, - value.first.to_i, 0)
    when "<t-"
      sql = date_range_clause(db_table, db_field, nil, - value.first.to_i)
    when "t-"
      sql = date_range_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
    when ">t+"
      sql = date_range_clause(db_table, db_field, value.first.to_i, nil)
    when "<t+"
      sql = date_range_clause(db_table, db_field, 0, value.first.to_i)
    when "t+"
      sql = date_range_clause(db_table, db_field, value.first.to_i, value.first.to_i)
    when "t"
      sql = date_range_clause(db_table, db_field, 0, 0)
    when "w"
      from = l(:general_first_day_of_week) == '7' ?
      # week starts on sunday
      ((Date.today.cwday == 7) ? Time.now.at_beginning_of_day : Time.now.at_beginning_of_week - 1.day) :
        # week starts on monday (Rails default)
        Time.now.at_beginning_of_week
      sql = "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(from + 7.days)]
    when "~"
      sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    when "!~"
      sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{connection.quote_string(value.first.to_s.downcase)}%'"
    end
    
    return sql.blank? ? "1=1" : sql
  end
  
  # Returns a SQL clause for a date or datetime field.
  def date_range_clause(table, field, from, to)
    s = []
    if from
      s << ("#{table}.#{field} > '%s'" % [connection.quoted_date((Date.yesterday + from).to_time.end_of_day)])
    end
    if to
      s << ("#{table}.#{field} <= '%s'" % [connection.quoted_date((Date.today + to).to_time.end_of_day)])
    end
    s.join(' AND ')
  end
end
