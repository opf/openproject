# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class Query < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  serialize :filters
  
  attr_protected :project, :user
  attr_accessor :executed_by
  
  validates_presence_of :name, :on => :save
  validates_length_of :name, :maximum => 255
    
  @@operators = { "="   => :label_equals, 
                  "!"   => :label_not_equals,
                  "o"   => :label_open_issues,
                  "c"   => :label_closed_issues,
                  "!*"  => :label_none,
                  "*"   => :label_all,
                  "<t+" => :label_in_less_than,
                  ">t+" => :label_in_more_than,
                  "t+"  => :label_in,
                  "t"   => :label_today,
                  ">t-" => :label_less_than_ago,
                  "<t-" => :label_more_than_ago,
                  "t-"  => :label_ago,
                  "~"   => :label_contains,
                  "!~"  => :label_not_contains }

  cattr_reader :operators
    
  @@operators_by_filter_type = { :list => [ "=", "!" ],
                                 :list_status => [ "o", "=", "!", "c", "*" ],
                                 :list_optional => [ "=", "!", "!*", "*" ],
                                 :list_one_or_more => [ "*", "=" ],
                                 :date => [ "<t+", ">t+", "t+", "t", ">t-", "<t-", "t-" ],
                                 :date_past => [ ">t-", "<t-", "t-", "t" ],
                                 :string => [ "=", "~", "!", "!~" ],
                                 :text => [  "~", "!~" ] }

  cattr_reader :operators_by_filter_type

  def initialize(attributes = nil)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
  end
  
  def executed_by=(user)
    @executed_by = user
    set_language_if_valid(user.language) if user
  end
  
  def validate
    filters.each_key do |field|
      errors.add label_for(field), :activerecord_error_blank unless 
          # filter requires one or more values
          (values_for(field) and !values_for(field).first.empty?) or 
          # filter doesn't require any value
          ["o", "c", "!*", "*", "t"].include? operator_for(field)
    end if filters
  end
  
  def editable_by?(user)
    return false unless user
    return true if !is_public && self.user_id == user.id
    is_public && user.allowed_to?(:manage_pulic_queries, project)
  end
  
  def available_filters
    return @available_filters if @available_filters
    @available_filters = { "status_id" => { :type => :list_status, :order => 1, :values => IssueStatus.find(:all, :order => 'position').collect{|s| [s.name, s.id.to_s] } },       
                           "tracker_id" => { :type => :list, :order => 2, :values => Tracker.find(:all, :order => 'position').collect{|s| [s.name, s.id.to_s] } },                                                                                                                
                           "priority_id" => { :type => :list, :order => 3, :values => Enumeration.find(:all, :conditions => ['opt=?','IPRI']).collect{|s| [s.name, s.id.to_s] } },
                           "subject" => { :type => :text, :order => 8 },  
                           "created_on" => { :type => :date_past, :order => 9 },                        
                           "updated_on" => { :type => :date_past, :order => 10 },
                           "start_date" => { :type => :date, :order => 11 },
                           "due_date" => { :type => :date, :order => 12 } }                          
    unless project.nil?
      # project specific filters
      user_values = []
      user_values << ["<< #{l(:label_me)} >>", "me"] if executed_by
      user_values += @project.users.collect{|s| [s.name, s.id.to_s] }
      
      @available_filters["assigned_to_id"] = { :type => :list_optional, :order => 4, :values => user_values }  
      @available_filters["author_id"] = { :type => :list, :order => 5, :values => user_values }  
      @available_filters["category_id"] = { :type => :list_optional, :order => 6, :values => @project.issue_categories.collect{|s| [s.name, s.id.to_s] } }
      @available_filters["fixed_version_id"] = { :type => :list_optional, :order => 7, :values => @project.versions.sort.collect{|s| [s.name, s.id.to_s] } }
      unless @project.active_children.empty?
        @available_filters["subproject_id"] = { :type => :list_one_or_more, :order => 13, :values => @project.active_children.collect{|s| [s.name, s.id.to_s] } }
      end
      @project.all_custom_fields.select(&:is_filter?).each do |field|
        case field.field_format
        when "string", "int"
          options = { :type => :string, :order => 20 }
        when "text"
          options = { :type => :text, :order => 20 }
        when "list"
          options = { :type => :list_optional, :values => field.possible_values, :order => 20}
        when "date"
          options = { :type => :date, :order => 20 }
        when "bool"
          options = { :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
        end          
        @available_filters["cf_#{field.id}"] = options.merge({ :name => field.name })
      end
      # remove category filter if no category defined
      @available_filters.delete "category_id" if @available_filters["category_id"][:values].empty?
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
    label = @available_filters[field][:name] if @available_filters.has_key?(field)
    label ||= field.gsub(/\_id$/, "")
  end
  
  def statement
    # project/subprojects clause
    clause = ''
    if has_filter?("subproject_id")
      subproject_ids = []
      if operator_for("subproject_id") == "="
        subproject_ids = values_for("subproject_id").each(&:to_i)
      else
        subproject_ids = project.active_children.collect{|p| p.id}
      end
      clause << "#{Issue.table_name}.project_id IN (%d,%s)" % [project.id, subproject_ids.join(",")] if project
    else
      clause << "#{Issue.table_name}.project_id=%d" % project.id if project
    end
    
    # filters clauses
    filters_clauses = []
    filters.each_key do |field|
      next if field == "subproject_id"
      v = values_for(field).clone
      next unless v and !v.empty?
            
      sql = ''      
      if field =~ /^cf_(\d+)$/
        # custom field
        db_table = CustomValue.table_name
        db_field = 'value'
        sql << "#{Issue.table_name}.id IN (SELECT #{db_table}.customized_id FROM #{db_table} where #{db_table}.customized_type='Issue' AND #{db_table}.customized_id=#{Issue.table_name}.id AND #{db_table}.custom_field_id=#{$1} AND "
      else
        # regular field
        db_table = Issue.table_name
        db_field = field
        sql << '('
      end
      
      # "me" value subsitution
      if %w(assigned_to_id author_id).include?(field)
        v.push(executed_by ? executed_by.id.to_s : "0") if v.delete("me")
      end
      
      case operator_for field
      when "="
        sql = sql + "#{db_table}.#{db_field} IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
      when "!"
        sql = sql + "#{db_table}.#{db_field} NOT IN (" + v.collect{|val| "'#{connection.quote_string(val)}'"}.join(",") + ")"
      when "!*"
        sql = sql + "#{db_table}.#{db_field} IS NULL"
      when "*"
        sql = sql + "#{db_table}.#{db_field} IS NOT NULL"
      when "o"
        sql = sql + "#{IssueStatus.table_name}.is_closed=#{connection.quoted_false}" if field == "status_id"
      when "c"
        sql = sql + "#{IssueStatus.table_name}.is_closed=#{connection.quoted_true}" if field == "status_id"
      when ">t-"
        sql = sql + "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((Date.today - v.first.to_i).to_time), connection.quoted_date((Date.today + 1).to_time)]
      when "<t-"
        sql = sql + "#{db_table}.#{db_field} <= '%s'" % connection.quoted_date((Date.today - v.first.to_i).to_time)
      when "t-"
        sql = sql + "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((Date.today - v.first.to_i).to_time), connection.quoted_date((Date.today - v.first.to_i + 1).to_time)]
      when ">t+"
        sql = sql + "#{db_table}.#{db_field} >= '%s'" % connection.quoted_date((Date.today + v.first.to_i).to_time)
      when "<t+"
        sql = sql + "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(Date.today.to_time), connection.quoted_date((Date.today + v.first.to_i + 1).to_time)]
      when "t+"
        sql = sql + "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date((Date.today + v.first.to_i).to_time), connection.quoted_date((Date.today + v.first.to_i + 1).to_time)]
      when "t"
        sql = sql + "#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(Date.today.to_time), connection.quoted_date((Date.today+1).to_time)]
      when "~"
        sql = sql + "#{db_table}.#{db_field} LIKE '%#{connection.quote_string(v.first)}%'"
      when "!~"
        sql = sql + "#{db_table}.#{db_field} NOT LIKE '%#{connection.quote_string(v.first)}%'"
      end
      sql << ')'
      filters_clauses << sql
    end if filters and valid?
    
    clause << (' AND ' + filters_clauses.join(' AND ')) unless filters_clauses.empty?
    clause
  end
end
