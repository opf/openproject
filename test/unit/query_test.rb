# redMine - project management software
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

require File.dirname(__FILE__) + '/../test_helper'

class QueryTest < Test::Unit::TestCase
  fixtures :projects, :enabled_modules, :users, :members, :roles, :trackers, :issue_statuses, :issue_categories, :enumerations, :issues, :watchers, :custom_fields, :custom_values, :versions, :queries

  def test_custom_fields_for_all_projects_should_be_available_in_global_queries
    query = Query.new(:project => nil, :name => '_')
    assert query.available_filters.has_key?('cf_1')
    assert !query.available_filters.has_key?('cf_3')
  end
  
  def find_issues_with_query(query)
    Issue.find :all,
      :include => [ :assigned_to, :status, :tracker, :project, :priority ], 
      :conditions => query.statement
  end
  
  def test_query_with_multiple_custom_fields
    query = Query.find(1)
    assert query.valid?
    assert query.statement.include?("#{CustomValue.table_name}.value IN ('MySQL')")
    issues = find_issues_with_query(query)
    assert_equal 1, issues.length
    assert_equal Issue.find(3), issues.first
  end
  
  def test_operator_none
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('fixed_version_id', '!*', [''])
    query.add_filter('cf_1', '!*', [''])
    assert query.statement.include?("#{Issue.table_name}.fixed_version_id IS NULL")
    assert query.statement.include?("#{CustomValue.table_name}.value IS NULL OR #{CustomValue.table_name}.value = ''")
    find_issues_with_query(query)
  end
  
  def test_operator_none_for_integer
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('estimated_hours', '!*', [''])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    assert issues.all? {|i| !i.estimated_hours}
  end

  def test_operator_all
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('fixed_version_id', '*', [''])
    query.add_filter('cf_1', '*', [''])
    assert query.statement.include?("#{Issue.table_name}.fixed_version_id IS NOT NULL")
    assert query.statement.include?("#{CustomValue.table_name}.value IS NOT NULL AND #{CustomValue.table_name}.value <> ''")
    find_issues_with_query(query)
  end
  
  def test_operator_greater_than
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('done_ratio', '>=', ['40'])
    assert query.statement.include?("#{Issue.table_name}.done_ratio >= 40")
    find_issues_with_query(query)
  end

  def test_operator_in_more_than
    Issue.find(7).update_attribute(:due_date, (Date.today + 15))
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', '>t+', ['15'])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert(issue.due_date >= (Date.today + 15))}
  end

  def test_operator_in_less_than
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', '<t+', ['15'])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert(issue.due_date >= Date.today && issue.due_date <= (Date.today + 15))}
  end
  
  def test_operator_less_than_ago
    Issue.find(7).update_attribute(:due_date, (Date.today - 3))
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', '>t-', ['3'])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert(issue.due_date >= (Date.today - 3) && issue.due_date <= Date.today)}
  end
  
  def test_operator_more_than_ago
    Issue.find(7).update_attribute(:due_date, (Date.today - 10))
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', '<t-', ['10'])
    assert query.statement.include?("#{Issue.table_name}.due_date <=")
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert(issue.due_date <= (Date.today - 10))}
  end

  def test_operator_in
    Issue.find(7).update_attribute(:due_date, (Date.today + 2))
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', 't+', ['2'])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert_equal((Date.today + 2), issue.due_date)}
  end

  def test_operator_ago
    Issue.find(7).update_attribute(:due_date, (Date.today - 3))
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', 't-', ['3'])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert_equal((Date.today - 3), issue.due_date)}
  end

  def test_operator_today
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', 't', [''])
    issues = find_issues_with_query(query)
    assert !issues.empty?
    issues.each {|issue| assert_equal Date.today, issue.due_date}
  end

  def test_operator_this_week_on_date
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('due_date', 'w', [''])
    find_issues_with_query(query)
  end

  def test_operator_this_week_on_datetime
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('created_on', 'w', [''])
    find_issues_with_query(query)
  end

  def test_operator_contains
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('subject', '~', ['string'])
    assert query.statement.include?("#{Issue.table_name}.subject LIKE '%string%'")
    find_issues_with_query(query)
  end
  
  def test_operator_does_not_contains
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('subject', '!~', ['string'])
    assert query.statement.include?("#{Issue.table_name}.subject NOT LIKE '%string%'")
    find_issues_with_query(query)
  end
  
  def test_filter_watched_issues
    User.current = User.find(1)
    query = Query.new(:name => '_', :filters => { 'watcher_id' => {:operator => '=', :values => ['me']}})
    result = find_issues_with_query(query)
    assert_not_nil result
    assert !result.empty?
    assert_equal Issue.visible.watched_by(User.current).sort_by(&:id), result.sort_by(&:id)
    User.current = nil
  end
  
  def test_filter_unwatched_issues
    User.current = User.find(1)
    query = Query.new(:name => '_', :filters => { 'watcher_id' => {:operator => '!', :values => ['me']}})
    result = find_issues_with_query(query)
    assert_not_nil result
    assert !result.empty?
    assert_equal((Issue.visible - Issue.watched_by(User.current)).sort_by(&:id).size, result.sort_by(&:id).size)
    User.current = nil
  end
  
  def test_default_columns
    q = Query.new
    assert !q.columns.empty? 
  end
  
  def test_set_column_names
    q = Query.new
    q.column_names = ['tracker', :subject, '', 'unknonw_column']
    assert_equal [:tracker, :subject], q.columns.collect {|c| c.name}
    c = q.columns.first
    assert q.has_column?(c)
  end
  
  def test_sort_by_string_custom_field_asc
    q = Query.new
    c = q.available_columns.find {|col| col.is_a?(QueryCustomFieldColumn) && col.custom_field.field_format == 'string' }
    assert c
    assert c.sortable
    issues = Issue.find :all,
                        :include => [ :assigned_to, :status, :tracker, :project, :priority ], 
                        :conditions => q.statement,
                        :order => "#{c.sortable} ASC"
    values = issues.collect {|i| i.custom_value_for(c.custom_field).to_s}
    assert !values.empty?
    assert_equal values.sort, values
  end
  
  def test_sort_by_string_custom_field_desc
    q = Query.new
    c = q.available_columns.find {|col| col.is_a?(QueryCustomFieldColumn) && col.custom_field.field_format == 'string' }
    assert c
    assert c.sortable
    issues = Issue.find :all,
                        :include => [ :assigned_to, :status, :tracker, :project, :priority ], 
                        :conditions => q.statement,
                        :order => "#{c.sortable} DESC"
    values = issues.collect {|i| i.custom_value_for(c.custom_field).to_s}
    assert !values.empty?
    assert_equal values.sort.reverse, values
  end
  
  def test_sort_by_float_custom_field_asc
    q = Query.new
    c = q.available_columns.find {|col| col.is_a?(QueryCustomFieldColumn) && col.custom_field.field_format == 'float' }
    assert c
    assert c.sortable
    issues = Issue.find :all,
                        :include => [ :assigned_to, :status, :tracker, :project, :priority ], 
                        :conditions => q.statement,
                        :order => "#{c.sortable} ASC"
    values = issues.collect {|i| begin; Kernel.Float(i.custom_value_for(c.custom_field).to_s); rescue; nil; end}.compact
    assert !values.empty?
    assert_equal values.sort, values
  end
  
  def test_label_for
    q = Query.new
    assert_equal 'assigned_to', q.label_for('assigned_to_id')
  end
  
  def test_editable_by
    admin = User.find(1)
    manager = User.find(2)
    developer = User.find(3)
    
    # Public query on project 1
    q = Query.find(1)
    assert q.editable_by?(admin)
    assert q.editable_by?(manager)
    assert !q.editable_by?(developer)

    # Private query on project 1
    q = Query.find(2)
    assert q.editable_by?(admin)
    assert !q.editable_by?(manager)
    assert q.editable_by?(developer)

    # Private query for all projects
    q = Query.find(3)
    assert q.editable_by?(admin)
    assert !q.editable_by?(manager)
    assert q.editable_by?(developer)

    # Public query for all projects
    q = Query.find(4)
    assert q.editable_by?(admin)
    assert !q.editable_by?(manager)
    assert !q.editable_by?(developer)
  end
end
