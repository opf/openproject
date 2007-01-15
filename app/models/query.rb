# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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
  
  validates_presence_of :name, :on => :save
    
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
                                 :date => [ "<t+", ">t+", "t+", "t", ">t-", "<t-", "t-" ],
                                 :date_past => [ ">t-", "<t-", "t-", "t" ],
                                 :text => [  "~", "!~" ] }

  cattr_reader :operators_by_filter_type

  def initialize(attributes = nil)
    super attributes
    self.filters ||= { 'status_id' => {:operator => "o", :values => [""]} }
    self.is_public = true
  end
  
  def validate
    filters.each_key do |field|
      errors.add field.gsub(/\_id$/, ""), :activerecord_error_blank unless 
          # filter requires one or more values
          (values_for(field) and !values_for(field).first.empty?) or 
          # filter doesn't require any value
          ["o", "c", "!*", "*", "t"].include? operator_for(field)
    end if filters
  end
  
  def available_filters
    return @available_filters if @available_filters
    @available_filters = { "status_id" => { :type => :list_status, :order => 1, :values => IssueStatus.find(:all).collect{|s| [s.name, s.id.to_s] } },       
                           "tracker_id" => { :type => :list, :order => 2, :values => Tracker.find(:all).collect{|s| [s.name, s.id.to_s] } },                                                                                                                
                           "priority_id" => { :type => :list, :order => 3, :values => Enumeration.find(:all, :conditions => ['opt=?','IPRI']).collect{|s| [s.name, s.id.to_s] } },
                           "subject" => { :type => :text, :order => 8 },  
                           "created_on" => { :type => :date_past, :order => 9 },                        
                           "updated_on" => { :type => :date_past, :order => 10 },
                           "start_date" => { :type => :date, :order => 11 },
                           "due_date" => { :type => :date, :order => 12 } }                          
    unless project.nil?
      # project specific filters
      @available_filters["assigned_to_id"] = { :type => :list_optional, :order => 4, :values => @project.users.collect{|s| [s.name, s.id.to_s] } }  
      @available_filters["author_id"] = { :type => :list, :order => 5, :values => @project.users.collect{|s| [s.name, s.id.to_s] } }  
      @available_filters["category_id"] = { :type => :list_optional, :order => 6, :values => @project.issue_categories.collect{|s| [s.name, s.id.to_s] } }
      @available_filters["fixed_version_id"] = { :type => :list_optional, :order => 7, :values => @project.versions.collect{|s| [s.name, s.id.to_s] } }
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
  
  def statement
    sql = "1=1" 
    sql << " AND issues.project_id=%d" % project.id if project
    filters.each_key do |field|
      v = values_for field
      next unless v and !v.empty?  
      sql = sql + " AND " unless sql.empty?      
      case operator_for field
      when "="
        sql = sql + "issues.#{field} IN (" + v.each(&:to_i).join(",") + ")"
      when "!"
        sql = sql + "issues.#{field} NOT IN (" + v.each(&:to_i).join(",") + ")"
      when "!*"
        sql = sql + "issues.#{field} IS NULL"
      when "*"
        sql = sql + "issues.#{field} IS NOT NULL"
      when "o"
        sql = sql + "issue_statuses.is_closed=#{connection.quoted_false}" if field == "status_id"
      when "c"
        sql = sql + "issue_statuses.is_closed=#{connection.quoted_true}" if field == "status_id"
      when ">t-"
        sql = sql + "issues.#{field} >= '%s'" % connection.quoted_date(Date.today - v.first.to_i)
      when "<t-"
        sql = sql + "issues.#{field} <= '" + (Date.today - v.first.to_i).strftime("%Y-%m-%d") + "'"
      when "t-"
        sql = sql + "issues.#{field} = '" + (Date.today - v.first.to_i).strftime("%Y-%m-%d") + "'"
      when ">t+"
        sql = sql + "issues.#{field} >= '" + (Date.today + v.first.to_i).strftime("%Y-%m-%d") + "'"
      when "<t+"
        sql = sql + "issues.#{field} <= '" + (Date.today + v.first.to_i).strftime("%Y-%m-%d") + "'"
      when "t+"
        sql = sql + "issues.#{field} = '" + (Date.today + v.first.to_i).strftime("%Y-%m-%d") + "'"
      when "t"
        sql = sql + "issues.#{field} = '%s'" % connection.quoted_date(Date.today)
      when "~"
        sql = sql + "issues.#{field} LIKE '%#{connection.quote_string(v.first)}%'"
      when "!~"
        sql = sql + "issues.#{field} NOT LIKE '%#{connection.quote_string(v.first)}%'"
      end
    end if filters and valid?
    sql
  end
end
