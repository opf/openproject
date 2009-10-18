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
  end
  attr_reader :scope, :column_name, :column
  
  attr_reader :values
  def values=(v)
    if available_values
      available_value_keys = available_values.collect {|o| o[1]}
      v.each do |value|
        raise ArgumentException("Forbidden value") unless available_value_keys.include? value
      end
    end
    
    @values = v
  end
  
  attr_reader :operator
  def operator=(o)
    raise ArgumentException("Forbidden operator") unless available_operators.include? o
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
  belongs_to :user
  belongs_to :project
  
  serialize :filters
  serialize :group_by
  
  attr_protected :user_id, :project_id, :created_at, :updated_at

  def after_initialize
    display_time_entries = true if display_time_entries.nil?
    display_cost_entries = true if display_cost_entries.nil?
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
        "0" => {:label => :label_zero, :simple => true},
        "y" => {:label => :label_yes, :simple => true},
        "n" => {:label => :label_no, :simple => true}
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
        :integer_zero => {:operators => [ "=", ">=", "<=", "0", "*" ], :multiple => true},
        :boolean => {:operators => [ "y", "n" ], :multiple => false}
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
        "cost_type_id" => { :type => :list_optional, :order => 2, :applies => [:cost_entries], :flags => [], :values => CostType.find(:all, :order => 'name').collect{|s| [s.name, s.id.to_s] }},
        # FIXME: this has to be changed for Redmine 0.9 as r2777 of Redmine introduces STI for enumerations
        "activity" => { :type => :list_optional, :order => 3, :applies => [:time_entries], :flags => [], :values => Enumeration.find(:all, :conditions => ['opt=?','ACTI'], :order => 'position').collect{|s| [s.name, s.id.to_s] }},
        "created_on" => { :type => :date_past, :applies => [:time_entries, :cost_entries], :flags => [], :order => 4 },                        
        "updated_on" => { :type => :date_past, :applies => [:time_entries, :cost_entries], :flags => [], :order => 5 },
        "spent_on" => { :type => :date, :applies => [:time_entries, :cost_entries], :flags => [], :order => 6 },
        "overridden" => { :type => :boolean, :applies => [:time_entries, :cost_entries], :flags => [], :order => 7 },
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
        v[:db_field] = value
        v[:flags] << :custom_field
      elsif k == "watcher_id"
        v[:db_table] = Watcher.table_name
        v[:db_field] = 'user_id'
        v[:flags] << :watcher
      else
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
    Filter.new(scope, column_name, available_filters[scope][column_name])
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
  
  
  def project_statement
    "1=1"
  end
  
  
  def statement(applies_type)
    # applies_type can currently be one of :cost_entries, :time:entries
    
    filter_clauses = []
    if filters and valid?
      filters.each do |filter|
        v = filter[:values]
        operator = filter[:operator]
        
        if available_filters[filter[:scope].to_sym][filter[:column_name]][:flags].include? :user
          v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")
        end
        
        sql = ''
        case applies_type
        when :issues

        when :costs
        end
        
        # FIXME
        sql = "1=1" if sql.blank?
        
        filter_clauses << sql
      end
    end
    
    (filter_clauses << project_statement).join(' AND ')
  end




  
end
