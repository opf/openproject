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

class QueryTest < ActiveSupport::TestCase
  fixtures :projects, :enabled_modules, :users, :members, :member_roles, :roles, :trackers, :issue_statuses, :issue_categories, :enumerations, :issues, :watchers, :custom_fields, :custom_values, :versions, :queries

  def test_custom_fields_for_all_projects_should_be_available_in_global_queries
    query = Query.new(:project => nil, :name => '_')
    assert query.available_filters.has_key?('cf_1')
    assert !query.available_filters.has_key?('cf_3')
  end
  
  def test_system_shared_versions_should_be_available_in_global_queries
    Version.find(2).update_attribute :sharing, 'system'
    query = Query.new(:project => nil, :name => '_')
    assert query.available_filters.has_key?('fixed_version_id')
    assert query.available_filters['fixed_version_id'][:values].detect {|v| v.last == '2'}
  end
  
  def test_project_filter_in_global_queries
    query = Query.new(:project => nil, :name => '_')
    project_filter = query.available_filters["project_id"]
    assert_not_nil project_filter
    project_ids = project_filter[:values].map{|p| p[1]}
    assert project_ids.include?("1")  #public project
    assert !project_ids.include?("2") #private project user cannot see
  end
  
  def find_issues_with_query(query)
    Issue.find :all,
      :include => [ :assigned_to, :status, :tracker, :project, :priority ], 
      :conditions => query.statement
  end

  def assert_find_issues_with_query_is_successful(query)
    assert_nothing_raised do
      find_issues_with_query(query)
    end
  end

  def assert_query_statement_includes(query, condition)
    assert query.statement.include?(condition), "Query statement condition not found in: #{query.statement}"
  end

  def test_query_should_allow_shared_versions_for_a_project_query
    subproject_version = Version.find(4)
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('fixed_version_id', '=', [subproject_version.id.to_s])

    assert query.statement.include?("#{Issue.table_name}.fixed_version_id IN ('4')")
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
    query.add_filter('subject', '~', ['uNable'])
    assert query.statement.include?("LOWER(#{Issue.table_name}.subject) LIKE '%unable%'")
    result = find_issues_with_query(query)
    assert result.empty?
    result.each {|issue| assert issue.subject.downcase.include?('unable') }
  end
  
  def test_operator_does_not_contains
    query = Query.new(:project => Project.find(1), :name => '_')
    query.add_filter('subject', '!~', ['uNable'])
    assert query.statement.include?("LOWER(#{Issue.table_name}.subject) NOT LIKE '%unable%'")
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
  
  def test_groupable_columns_should_include_custom_fields
    q = Query.new
    assert q.groupable_columns.detect {|c| c.is_a? QueryCustomFieldColumn}
  end
  
  def test_default_sort
    q = Query.new
    assert_equal [], q.sort_criteria
  end
  
  def test_set_sort_criteria_with_hash
    q = Query.new
    q.sort_criteria = {'0' => ['priority', 'desc'], '2' => ['tracker']}
    assert_equal [['priority', 'desc'], ['tracker', 'asc']], q.sort_criteria
  end
  
  def test_set_sort_criteria_with_array
    q = Query.new
    q.sort_criteria = [['priority', 'desc'], 'tracker']
    assert_equal [['priority', 'desc'], ['tracker', 'asc']], q.sort_criteria
  end
  
  def test_create_query_with_sort
    q = Query.new(:name => 'Sorted')
    q.sort_criteria = [['priority', 'desc'], 'tracker']
    assert q.save
    q.reload
    assert_equal [['priority', 'desc'], ['tracker', 'asc']], q.sort_criteria
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
  
  def test_invalid_query_should_raise_query_statement_invalid_error
    q = Query.new
    assert_raise Query::StatementInvalid do
      q.issues(:conditions => "foo = 1")
    end
  end
  
  def test_issue_count_by_association_group
    q = Query.new(:name => '_', :group_by => 'assigned_to')
    count_by_group = q.issue_count_by_group
    assert_kind_of Hash, count_by_group
    assert_equal %w(NilClass User), count_by_group.keys.collect {|k| k.class.name}.uniq.sort
    assert_equal %w(Fixnum), count_by_group.values.collect {|k| k.class.name}.uniq
    assert count_by_group.has_key?(User.find(3))
  end

  def test_issue_count_by_list_custom_field_group
    q = Query.new(:name => '_', :group_by => 'cf_1')
    count_by_group = q.issue_count_by_group
    assert_kind_of Hash, count_by_group
    assert_equal %w(NilClass String), count_by_group.keys.collect {|k| k.class.name}.uniq.sort
    assert_equal %w(Fixnum), count_by_group.values.collect {|k| k.class.name}.uniq
    assert count_by_group.has_key?('MySQL')
  end
  
  def test_issue_count_by_date_custom_field_group
    q = Query.new(:name => '_', :group_by => 'cf_8')
    count_by_group = q.issue_count_by_group
    assert_kind_of Hash, count_by_group
    assert_equal %w(Date NilClass), count_by_group.keys.collect {|k| k.class.name}.uniq.sort
    assert_equal %w(Fixnum), count_by_group.values.collect {|k| k.class.name}.uniq
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

  context "#available_filters" do
    setup do
      @query = Query.new(:name => "_")
    end
    
    should "include users of visible projects in cross-project view" do
      users = @query.available_filters["assigned_to_id"]
      assert_not_nil users
      assert users[:values].map{|u|u[1]}.include?("3")
    end

    context "'member_of_group' filter" do
      should "be present" do
        assert @query.available_filters.keys.include?("member_of_group")
      end
      
      should "be an optional list" do
        assert_equal :list_optional, @query.available_filters["member_of_group"][:type]
      end
      
      should "have a list of the groups as values" do
        Group.destroy_all # No fixtures
        group1 = Group.generate!.reload
        group2 = Group.generate!.reload

        expected_group_list = [
                               [group1.name, group1.id],
                               [group2.name, group2.id]
                              ]
        assert_equal expected_group_list, @query.available_filters["member_of_group"][:values]
      end

    end

    context "'assigned_to_role' filter" do
      should "be present" do
        assert @query.available_filters.keys.include?("assigned_to_role")
      end
      
      should "be an optional list" do
        assert_equal :list_optional, @query.available_filters["assigned_to_role"][:type]
      end
      
      should "have a list of the Roles as values" do
        assert @query.available_filters["assigned_to_role"][:values].include?(['Manager',1])
        assert @query.available_filters["assigned_to_role"][:values].include?(['Developer',2])
        assert @query.available_filters["assigned_to_role"][:values].include?(['Reporter',3])
      end

      should "not include the built in Roles as values" do
        assert ! @query.available_filters["assigned_to_role"][:values].include?(['Non member',4])
        assert ! @query.available_filters["assigned_to_role"][:values].include?(['Anonymous',5])
      end

    end

  end

  context "#statement" do
    context "with 'member_of_group' filter" do
      setup do
        Group.destroy_all # No fixtures
        @user_in_group = User.generate!
        @second_user_in_group = User.generate!
        @user_in_group2 = User.generate!
        @user_not_in_group = User.generate!
        
        @group = Group.generate!.reload
        @group.users << @user_in_group
        @group.users << @second_user_in_group
        
        @group2 = Group.generate!.reload
        @group2.users << @user_in_group2
        
      end
      
      should "search assigned to for users in the group" do
        @query = Query.new(:name => '_')
        @query.add_filter('member_of_group', '=', [@group.id.to_s])

        assert_query_statement_includes @query, "#{Issue.table_name}.assigned_to_id IN ('#{@user_in_group.id}','#{@second_user_in_group.id}')"
        assert_find_issues_with_query_is_successful @query
      end

      should "search not assigned to any group member (none)" do
        @query = Query.new(:name => '_')
        @query.add_filter('member_of_group', '!*', [''])

        # Users not in a group
        assert_query_statement_includes @query, "#{Issue.table_name}.assigned_to_id IS NULL OR #{Issue.table_name}.assigned_to_id NOT IN ('#{@user_in_group.id}','#{@second_user_in_group.id}','#{@user_in_group2.id}')"
        assert_find_issues_with_query_is_successful @query

      end

      should "search assigned to any group member (all)" do
        @query = Query.new(:name => '_')
        @query.add_filter('member_of_group', '*', [''])

        # Only users in a group
        assert_query_statement_includes @query, "#{Issue.table_name}.assigned_to_id IN ('#{@user_in_group.id}','#{@second_user_in_group.id}','#{@user_in_group2.id}')"
        assert_find_issues_with_query_is_successful @query

      end
    end

    context "with 'assigned_to_role' filter" do
      setup do
        # No fixtures
        MemberRole.delete_all
        Member.delete_all
        Role.delete_all
        
        @manager_role = Role.generate!(:name => 'Manager')
        @developer_role = Role.generate!(:name => 'Developer')

        @project = Project.generate!
        @manager = User.generate!
        @developer = User.generate!
        @boss = User.generate!
        User.add_to_project(@manager, @project, @manager_role)
        User.add_to_project(@developer, @project, @developer_role)
        User.add_to_project(@boss, @project, [@manager_role, @developer_role])
      end
      
      should "search assigned to for users with the Role" do
        @query = Query.new(:name => '_')
        @query.add_filter('assigned_to_role', '=', [@manager_role.id.to_s])

        assert_query_statement_includes @query, "#{Issue.table_name}.assigned_to_id IN ('#{@manager.id}','#{@boss.id}')"
        assert_find_issues_with_query_is_successful @query
      end

      should "search assigned to for users not assigned to any Role (none)" do
        @query = Query.new(:name => '_')
        @query.add_filter('assigned_to_role', '!*', [''])

        assert_query_statement_includes @query, "#{Issue.table_name}.assigned_to_id IS NULL OR #{Issue.table_name}.assigned_to_id NOT IN ('#{@manager.id}','#{@developer.id}','#{@boss.id}')"
        assert_find_issues_with_query_is_successful @query
      end

      should "search assigned to for users assigned to any Role (all)" do
        @query = Query.new(:name => '_')
        @query.add_filter('assigned_to_role', '*', [''])

        assert_query_statement_includes @query, "#{Issue.table_name}.assigned_to_id IN ('#{@manager.id}','#{@developer.id}','#{@boss.id}')"
        assert_find_issues_with_query_is_successful @query
      end
    end
  end
  
end
