# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class QueryColumn  
  attr_accessor :name, :sortable, :default_order
  include GLoc
  
  def initialize(name, options={})
    self.name = name
    self.sortable = options[:sortable]
    self.default_order = options[:default_order]
  end
  
  def caption
    set_language_if_valid(User.current.language)
    l("field_#{name}")
  end
end

class QueryCustomFieldColumn < QueryColumn

  def initialize(custom_field)
    self.name = "cf_#{custom_field.id}".to_sym
    self.sortable = false
    @cf = custom_field
  end
  
  def caption
    @cf.name
  end
  
  def custom_field
    @cf
  end
end

class Query < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  serialize :filters
  serialize :column_names
  
  attr_protected :project_id, :user_id
  
  validates_presence_of :name, :on => :save
  validates_length_of :name, :maximum => 255
    
  @@operators = { "="   => :label_equals, 
                  "!"   => :label_not_equals,
                  "o"   => :label_open_issues,
                  "c"   => :label_closed_issues,
                  "!*"  => :label_none,
                  "*"   => :label_all,
                  ">="   => '>=',
                  "<="   => '<=',
                  "<t+" => :label_in_less_than,
                  ">t+" => :label_in_more_than,
                  "t+"  => :label_in,
                  "t"   => :label_today,
                  "w"   => :label_this_week,
                  ">t-" => :label_less_than_ago,
                  "<t-" => :label_more_than_ago,
                  "t-"  => :label_ago,
                  "~"   => :label_contains,
                  "!~"  => :label_not_contains }

  cattr_reader :operators
    
  @@operators_by_filter_type = { :list => [ "=", "!" ],
                                 :list_status => [ "o", "=", "!", "c", "*" ],
                                 :list_optional => [ "=", "!", "!*", "*" ],
                                 :list_subprojects => [ "*", "!*", "=" ],
                                 :date => [ "<t+", ">t+", "t+", "t", "w", ">t-", "<t-", "t-" ],
                                 :date_past => [ ">t-", "<t-", "t-", "t", "w" ],
                                 :string => [ "=", "~", "!", "!~" ],
                                 :text => [  "~", "!~" ],
                                 :integer => [ "=", ">=", "<=", "!*", "*" ] }

  cattr_reader :operators_by_filter_type

  @@available_columns = [
    QueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position"),
    QueryColumn.new(:status, :sortable => "#{IssueStatus.table_name}.position"),
    QueryColumn.new(:priority, :sortable => "#{Enumeration.table_name}.position", :default_order => 'desc'),
    QueryColumn.new(:subject, :sortable => "#{Issue.table_name}.subject"),
    QueryColumn.new(:author),
    QueryColumn.new(:assigned_to, :sortable => "#{User.table_name}.lastname"),
    QueryColumn.new(:updated_on, :sortable => "#{Issue.table_name}.updated_on", :default_order => 'desc'),
    QueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name"),
    QueryColumn.new(:fixed_version, :sortable => "#{Version.table_name}.effective_date", :default_order => 'desc'),
    QueryColumn.new(:start_date, :sortable => "#{Issue.table_name}.start_date"),
    QueryColumn.new(:due_date, :sortable => "#{Issue.table_name}.due_date"),
    QueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours"),
    QueryColumn.new(:done_ratio, :sortable => "#{Issue.table_name}.done_ratio"),
    QueryColumn.new(:created_on, :sortable => "#{Issue.table_name}.created_on", :default_order => 'desc'),
  ]
  cattr_reader :available_columns
  
  def initialize(attributes = nil)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
    set_language_if_valid(User.current.language)
  end
  
  def after_initialize
    # Store the fact that project is nil (used in #editable_by?)
    @is_for_all = project.nil?
  end
  
  def validate
    filters.each_key do |field|
      errors.add label_for(field), :activerecord_error_blank unless 
          # filter requires one or more values
          (values_for(field) and !values_for(field).first.blank?) or 
          # filter doesn't require any value
          ["o", "c", "!*", "*", "t", "w"].include? operator_for(field)
    end if filters
  end
  
  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (!is_public && self.user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public && !@is_for_all && user.allowed_to?(:manage_public_queries, project)
  end
  
  def available_filters
    return @available_filters if @available_filters
    
    trackers = project.nil? ? Tracker.find(:all, :order => 'position') : project.rolled_up_trackers
    
    @available_filters = { "status_id" => { :type => :list_status, :order => 1, :values => IssueStatus.find(:all, :order => 'position').collect{|s| [s.name, s.id.to_s] } },       
                           "tracker_id" => { :type => :list, :order => 2, :values => trackers.collect{|s| [s.name, s.id.to_s] } },                                                                                                                
                           "priority_id" => { :type => :list, :order => 3, :values => Enumeration.find(:all, :conditions => ['opt=?','IPRI'], :order => 'position').collect{|s| [s.name, s.id.to_s] } },
                           "subject" => { :type => :text, :order => 8 },  
                           "created_on" => { :type => :date_past, :order => 9 },                        
                           "updated_on" => { :type => :date_past, :order => 10 },
                           "start_date" => { :type => :date, :order => 11 },
                           "due_date" => { :type => :date, :order => 12 },
                           "estimated_hours" => { :type => :integer, :order => 13 },
                           "done_ratio" =>  { :type => :integer, :order => 14 }}
    
    user_values = []
    user_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    if project
      user_values += project.users.sort.collect{|s| [s.name, s.id.to_s] }
    else
      # members of the user's projects
      user_values += User.current.projects.collect(&:users).flatten.uniq.sort.collect{|s| [s.name, s.id.to_s] }
    end
    @available_filters["assigned_to_id"] = { :type => :list_optional, :order => 4, :values => user_values } unless user_values.empty?
    @available_filters["author_id"] = { :type => :list, :order => 5, :values => user_values } unless user_values.empty?
  
    if project
      # project specific filters
      unless @project.issue_categories.empty?
        @available_filters["category_id"] = { :type => :list_optional, :order => 6, :values => @project.issue_categories.collect{|s| [s.name, s.id.to_s] } }
      end
      unless @project.versions.empty?
        @available_filters["fixed_version_id"] = { :type => :list_optional, :order => 7, :values => @project.versions.sort.collect{|s| [s.name, s.id.to_s] } }
      end
      unless @project.active_children.empty?
        @available_filters["subproject_id"] = { :type => :list_subprojects, :order => 13, :values => @project.active_children.collect{|s| [s.name, s.id.to_s] } }
      end
      add_custom_fields_filters(@project.all_issue_custom_fields)
    else
      # global filters for cross project issue list
      add_custom_fields_filters(IssueCustomField.find(:all, :conditions => {:is_filter => true, :is_for_all => true}))
    end
    @available_filters
  end
  
  def add_filter(field, operator, values)
    # values must be an array
    return unless values and values.is_a? Array # and !values.first.empty?
    # check if field is defined as an available filter
    if available_filters.has_key? field
      filter_options = available_filters[field]
      # check if operator is allowed for that filter
      #if @@operators_by_filter_type[filter_options[:type]].include? operator
      #  allowed_values = values & ([""] + (filter_options[:values] || []).collect {|val| val[1]})
      #  filters[field] = {:operator => operator, :values => allowed_values } if (allowed_values.first and !allowed_values.first.empty?) or ["o", "c", "!*", "*", "t"].include? operator
      #end
      filters[field] = {:operator => operator, :values => values }
    end
  end
  
  def add_short_filter(field, expression)
    return unless expression
    parms = expression.scan(/^(o|c|\!|\*)?(.*)$/).first
    add_filter field, (parms[0] || "="), [parms[1] || ""]
  end
  
  def has_filter?(field)
    filters and filters[field]
  end
  
  def operator_for(field)
    has_filter?(field) ? filters[field][:operator] : nil
  end
  
  def values_for(field)
    has_filter?(field) ? filters[field][:values] : nil
  end
  
  def label_for(field)
    label = available_filters[field][:name] if available_filters.has_key?(field)
    label ||= field.gsub(/\_id$/, "")
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = Query.available_columns
    @available_columns += (project ? 
                            project.all_issue_custom_fields :
                            IssueCustomField.find(:all, :conditions => {:is_for_all => true})
                           ).collect {|cf| QueryCustomFieldColumn.new(cf) }      
  end
  
  def columns
    if has_default_columns?
      available_columns.select {|c| Setting.issue_list_default_columns.include?(c.name.to_s) }
    else
      # preserve the column_names order
      column_names.collect {|name| available_columns.find {|col| col.name == name}}.compact
    end
  end
  
  def column_names=(names)
    names = names.select {|n| n.is_a?(Symbol) || !n.blank? } if names
    names = names.collect {|n| n.is_a?(Symbol) ? n : n.to_sym } if names
    write_attribute(:column_names, names)
  end
  
  def has_column?(column)
    column_names && column_names.include?(column.name)
  end
  
  def has_default_columns?
    column_names.nil? || column_names.empty?
  end
  
  def project_statement
    project_clauses = []
    if project && !@project.active_children.empty?
      ids = [project.id]
      if has_filter?("subproject_id")
        case operator_for("subproject_id")
        when '='
          # include the selected subprojects
          ids += values_for("subproject_id").each(&:to_i)
        when '!*'
          # main project only
        else
          # all subprojects
          ids += project.child_ids
        end
      elsif Setting.display_subprojects_issues?
        ids += project.child_ids
      end
      project_clauses << "#{Project.table_name}.id IN (%s)" % ids.join(',')
    elsif project
      project_clauses << "#{Project.table_name}.id = %d" % project.id
    end
    project_clauses <<  Project.allowed_to_condition(User.current, :view_issues)
    project_clauses.join(' AND ')
  end

  def statement
    # filters clauses
    filters_clauses = []
    filters.each_key do |field|
      next if field == "subproject_id"
      v = values_for(field).clone
      next unless v and !v.empty?
            
      sql = ''
      is_custom_filter = false
      if field =~ /^cf_(\d+)$/
        # custom field
        db_table = CustomValue.table_name
        db_field = 'value'
        is_custom_filter = true
        sql << "#{Issue.table_name}.id IN (SELECT #{Issue.table_name}.id FROM #{Issue.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Issue' AND #{db_table}.customized_id=#{Issue.table_name}.id AND #{db_table}.custom_field_id=#{$1} WHERE "
      else
        # regular field
        db_table = Issue.table_name
        db_field = field
        sql << '('
      end
      
      # "me" value subsitution
      if %w(assigned_to_id author_id).include?(field)
        v.push(User.current.logged? ? User.current.id.to_s : "0") if v.delete("me")
      end
      
      sql = sql + sql_for_field(field, v, db_table, db_field, is_custom_filter)
      
      sql << ')'
      filters_clauses << sql
    end if filters and valid?
    
    (filters_clauses << project_statement).join(' AND ')
  end
  
  private
  
  # Helper method to generate the WHERE sql for a +field+ with a value (+v+)
  def sql_for_field(field, v, db_table, db_field, is_custom_filter)
    sql = ''
    case operator_for field
    when "="
      sql = "#{db_table}.#{db_field} IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
    when "!"
      sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + "))"
    when "!*"
      sql = "#{db_table}.#{db_field} IS NULL"
      sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
    when "*"
      sql = "#{db_table}.#{db_field} IS NOT NULL"
      sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
    when ">="
      sql = "#{db_table}.#{db_field} >= #{v.first.to_i}"
    when "<="
      sql = "#{db_table}.#{db_field} <= #{v.first.to_i}"
    when "o"
      sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
    when "c"
      sql = "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
    when ">t-"
      sql = date_range_clause(db_table, db_field, - v.first.to_i, 0)
    when "<t-"
      sql = date_range_clause(db_table, db_field, nil, - v.first.to_i)
    when "t-"
      sql = date_range_clause(db_table, db_field, - v.first.to_i, - v.first.to_i)
    when ">t+"
      sql = date_range_clause(db_table, db_field, v.first.to_i, nil)
    when "<t+"
      sql = date_range_clause(db_table, db_field, 0, v.first.to_i)
    when "t+"
      sql = date_range_clause(db_table, db_field, v.first.to_i, v.first.to_i)
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
      sql = "#{db_table}.#{db_field} LIKE '%#{connection.quote_string(v.first)}%'"
    when "!~"
      sql = "#{db_table}.#{db_field} NOT LIKE '%#{connection.quote_string(v.first)}%'"
    end
    
    return sql
  end
  
  def add_custom_fields_filters(custom_fields)
    @available_filters ||= {}
    
    custom_fields.select(&:is_filter?).each do |field|
      case field.field_format
      when "text"
        options = { :type => :text, :order => 20 }
      when "list"
        options = { :type => :list_optional, :values => field.possible_values, :order => 20}
      when "date"
        options = { :type => :date, :order => 20 }
      when "bool"
        options = { :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
      else
        options = { :type => :string, :order => 20 }
      end
      @available_filters["cf_#{field.id}"] = options.merge({ :name => field.name })
    end
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
