# Redmine - project management software
# Copyright (C) 2006-2014  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries,
           :repositories,
           :changesets

  include Redmine::I18n

  def setup
    User.current = nil
  end

  def test_index
    with_settings :default_language => "en" do
      get :index
      assert_response :success
      assert_template 'index'
      assert_not_nil assigns(:issues)
      assert_nil assigns(:project)

      # links to visible issues
      assert_select 'a[href=/issues/1]', :text => /#{ESCAPED_UCANT} print recipes/
      assert_select 'a[href=/issues/5]', :text => /Subproject issue/
      # private projects hidden
      assert_select 'a[href=/issues/6]', 0
      assert_select 'a[href=/issues/4]', 0
      # project column
      assert_select 'th', :text => /Project/
    end
  end

  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)

    assert_select 'a[href=/issues/1]', 0
    assert_select 'a[href=/issues/5]', :text => /Subproject issue/
  end

  def test_index_should_list_visible_issues_only
    get :index, :per_page => 100
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_nil assigns(:issues).detect {|issue| !issue.visible?}
  end

  def test_index_with_project
    Setting.display_subprojects_issues = 0
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    assert_select 'a[href=/issues/1]', :text => /#{ESCAPED_UCANT} print recipes/
    assert_select 'a[href=/issues/5]', 0
  end

  def test_index_with_project_and_subprojects
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    assert_select 'a[href=/issues/1]', :text => /#{ESCAPED_UCANT} print recipes/
    assert_select 'a[href=/issues/5]', :text => /Subproject issue/
    assert_select 'a[href=/issues/6]', 0
  end

  def test_index_with_project_and_subprojects_should_show_private_subprojects_with_permission
    @request.session[:user_id] = 2
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    assert_select 'a[href=/issues/1]', :text => /#{ESCAPED_UCANT} print recipes/
    assert_select 'a[href=/issues/5]', :text => /Subproject issue/
    assert_select 'a[href=/issues/6]', :text => /Issue of a private subproject/
  end

  def test_index_with_project_and_default_filter
    get :index, :project_id => 1, :set_filter => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    query = assigns(:query)
    assert_not_nil query
    # default filter
    assert_equal({'status_id' => {:operator => 'o', :values => ['']}}, query.filters)
  end

  def test_index_with_project_and_filter
    get :index, :project_id => 1, :set_filter => 1,
      :f => ['tracker_id'],
      :op => {'tracker_id' => '='},
      :v => {'tracker_id' => ['1']}
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    query = assigns(:query)
    assert_not_nil query
    assert_equal({'tracker_id' => {:operator => '=', :values => ['1']}}, query.filters)
  end

  def test_index_with_short_filters
    to_test = {
      'status_id' => {
        'o' => { :op => 'o', :values => [''] },
        'c' => { :op => 'c', :values => [''] },
        '7' => { :op => '=', :values => ['7'] },
        '7|3|4' => { :op => '=', :values => ['7', '3', '4'] },
        '=7' => { :op => '=', :values => ['7'] },
        '!3' => { :op => '!', :values => ['3'] },
        '!7|3|4' => { :op => '!', :values => ['7', '3', '4'] }},
      'subject' => {
        'This is a subject' => { :op => '=', :values => ['This is a subject'] },
        'o' => { :op => '=', :values => ['o'] },
        '~This is part of a subject' => { :op => '~', :values => ['This is part of a subject'] },
        '!~This is part of a subject' => { :op => '!~', :values => ['This is part of a subject'] }},
      'tracker_id' => {
        '3' => { :op => '=', :values => ['3'] },
        '=3' => { :op => '=', :values => ['3'] }},
      'start_date' => {
        '2011-10-12' => { :op => '=', :values => ['2011-10-12'] },
        '=2011-10-12' => { :op => '=', :values => ['2011-10-12'] },
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<=2011-10-12' => { :op => '<=', :values => ['2011-10-12'] },
        '><2011-10-01|2011-10-30' => { :op => '><', :values => ['2011-10-01', '2011-10-30'] },
        '<t+2' => { :op => '<t+', :values => ['2'] },
        '>t+2' => { :op => '>t+', :values => ['2'] },
        't+2' => { :op => 't+', :values => ['2'] },
        't' => { :op => 't', :values => [''] },
        'w' => { :op => 'w', :values => [''] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] }},
      'created_on' => {
        '>=2011-10-12' => { :op => '>=', :values => ['2011-10-12'] },
        '<t-2' => { :op => '<t-', :values => ['2'] },
        '>t-2' => { :op => '>t-', :values => ['2'] },
        't-2' => { :op => 't-', :values => ['2'] }},
      'cf_1' => {
        'c' => { :op => '=', :values => ['c'] },
        '!c' => { :op => '!', :values => ['c'] },
        '!*' => { :op => '!*', :values => [''] },
        '*' => { :op => '*', :values => [''] }},
      'estimated_hours' => {
        '=13.4' => { :op => '=', :values => ['13.4'] },
        '>=45' => { :op => '>=', :values => ['45'] },
        '<=125' => { :op => '<=', :values => ['125'] },
        '><10.5|20.5' => { :op => '><', :values => ['10.5', '20.5'] },
        '!*' => { :op => '!*', :values => [''] },
        '*' => { :op => '*', :values => [''] }}
    }

    default_filter = { 'status_id' => {:operator => 'o', :values => [''] }}

    to_test.each do |field, expression_and_expected|
      expression_and_expected.each do |filter_expression, expected|

        get :index, :set_filter => 1, field => filter_expression

        assert_response :success
        assert_template 'index'
        assert_not_nil assigns(:issues)

        query = assigns(:query)
        assert_not_nil query
        assert query.has_filter?(field)
        assert_equal(default_filter.merge({field => {:operator => expected[:op], :values => expected[:values]}}), query.filters)
      end
    end
  end

  def test_index_with_project_and_empty_filters
    get :index, :project_id => 1, :set_filter => 1, :fields => ['']
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    query = assigns(:query)
    assert_not_nil query
    # no filter
    assert_equal({}, query.filters)
  end

  def test_index_with_project_custom_field_filter
    field = ProjectCustomField.create!(:name => 'Client', :is_filter => true, :field_format => 'string')
    CustomValue.create!(:custom_field => field, :customized => Project.find(3), :value => 'Foo')
    CustomValue.create!(:custom_field => field, :customized => Project.find(5), :value => 'Foo')
    filter_name = "project.cf_#{field.id}"
    @request.session[:user_id] = 1

    get :index, :set_filter => 1,
      :f => [filter_name],
      :op => {filter_name => '='},
      :v => {filter_name => ['Foo']}
    assert_response :success
    assert_template 'index'
    assert_equal [3, 5], assigns(:issues).map(&:project_id).uniq.sort
  end

  def test_index_with_query
    get :index, :project_id => 1, :query_id => 5
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:issue_count_by_group)
  end

  def test_index_with_query_grouped_by_tracker
    get :index, :project_id => 1, :query_id => 6
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
  end

  def test_index_with_query_grouped_by_list_custom_field
    get :index, :project_id => 1, :query_id => 9
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
  end

  def test_index_with_query_grouped_by_user_custom_field
    cf = IssueCustomField.create!(:name => 'User', :is_for_all => true, :tracker_ids => [1,2,3], :field_format => 'user')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(1), :value => '2')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(2), :value => '3')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(3), :value => '3')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(5), :value => '')

    get :index, :project_id => 1, :set_filter => 1, :group_by => "cf_#{cf.id}"
    assert_response :success

    assert_select 'tr.group', 3
    assert_select 'tr.group' do
      assert_select 'a', :text => 'John Smith'
      assert_select 'span.count', :text => '1'
    end
    assert_select 'tr.group' do
      assert_select 'a', :text => 'Dave Lopper'
      assert_select 'span.count', :text => '2'
    end
  end

  def test_index_with_query_grouped_by_tracker_in_normal_order
    3.times {|i| Issue.generate!(:tracker_id => (i + 1))}

    get :index, :set_filter => 1, :group_by => 'tracker', :sort => 'id:desc'
    assert_response :success

    trackers = assigns(:issues).map(&:tracker).uniq
    assert_equal [1, 2, 3], trackers.map(&:id)
  end

  def test_index_with_query_grouped_by_tracker_in_reverse_order
    3.times {|i| Issue.generate!(:tracker_id => (i + 1))}

    get :index, :set_filter => 1, :group_by => 'tracker', :sort => 'id:desc,tracker:desc'
    assert_response :success

    trackers = assigns(:issues).map(&:tracker).uniq
    assert_equal [3, 2, 1], trackers.map(&:id)
  end

  def test_index_with_query_id_and_project_id_should_set_session_query
    get :index, :project_id => 1, :query_id => 4
    assert_response :success
    assert_kind_of Hash, session[:query]
    assert_equal 4, session[:query][:id]
    assert_equal 1, session[:query][:project_id]
  end

  def test_index_with_invalid_query_id_should_respond_404
    get :index, :project_id => 1, :query_id => 999
    assert_response 404
  end

  def test_index_with_cross_project_query_in_session_should_show_project_issues
    q = IssueQuery.create!(:name => "test", :user_id => 2, :visibility => IssueQuery::VISIBILITY_PRIVATE, :project => nil)
    @request.session[:query] = {:id => q.id, :project_id => 1}

    with_settings :display_subprojects_issues => '0' do
      get :index, :project_id => 1
    end
    assert_response :success
    assert_not_nil assigns(:query)
    assert_equal q.id, assigns(:query).id
    assert_equal 1, assigns(:query).project_id
    assert_equal [1], assigns(:issues).map(&:project_id).uniq
  end

  def test_private_query_should_not_be_available_to_other_users
    q = IssueQuery.create!(:name => "private", :user => User.find(2), :visibility => IssueQuery::VISIBILITY_PRIVATE, :project => nil)
    @request.session[:user_id] = 3

    get :index, :query_id => q.id
    assert_response 403
  end

  def test_private_query_should_be_available_to_its_user
    q = IssueQuery.create!(:name => "private", :user => User.find(2), :visibility => IssueQuery::VISIBILITY_PRIVATE, :project => nil)
    @request.session[:user_id] = 2

    get :index, :query_id => q.id
    assert_response :success
  end

  def test_public_query_should_be_available_to_other_users
    q = IssueQuery.create!(:name => "private", :user => User.find(2), :visibility => IssueQuery::VISIBILITY_PUBLIC, :project => nil)
    @request.session[:user_id] = 3

    get :index, :query_id => q.id
    assert_response :success
  end

  def test_index_should_omit_page_param_in_export_links
    get :index, :page => 2
    assert_response :success
    assert_select 'a.atom[href=/issues.atom]'
    assert_select 'a.csv[href=/issues.csv]'
    assert_select 'a.pdf[href=/issues.pdf]'
    assert_select 'form#csv-export-form[action=/issues.csv]'
  end

  def test_index_should_not_warn_when_not_exceeding_export_limit
    with_settings :issues_export_limit => 200 do
      get :index
      assert_select '#csv-export-options p.icon-warning', 0
    end
  end

  def test_index_should_warn_when_exceeding_export_limit
    with_settings :issues_export_limit => 2 do
      get :index
      assert_select '#csv-export-options p.icon-warning', :text => %r{limit: 2}
    end
  end

  def test_index_csv
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv; header=present', @response.content_type
    assert @response.body.starts_with?("#,")
    lines = @response.body.chomp.split("\n")
    assert_equal assigns(:query).columns.size, lines[0].split(',').size
  end

  def test_index_csv_with_project
    get :index, :project_id => 1, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv; header=present', @response.content_type
  end

  def test_index_csv_with_description
    Issue.generate!(:description => 'test_index_csv_with_description')

    with_settings :default_language => 'en' do
      get :index, :format => 'csv', :description => '1'
      assert_response :success
      assert_not_nil assigns(:issues)
    end

    assert_equal 'text/csv; header=present', response.content_type
    headers = response.body.chomp.split("\n").first.split(',')
    assert_include 'Description', headers
    assert_include 'test_index_csv_with_description', response.body
  end

  def test_index_csv_with_spent_time_column
    issue = Issue.create!(:project_id => 1, :tracker_id => 1, :subject => 'test_index_csv_with_spent_time_column', :author_id => 2)
    TimeEntry.create!(:project => issue.project, :issue => issue, :hours => 7.33, :user => User.find(2), :spent_on => Date.today)

    get :index, :format => 'csv', :set_filter => '1', :c => %w(subject spent_hours)
    assert_response :success
    assert_equal 'text/csv; header=present', @response.content_type
    lines = @response.body.chomp.split("\n")
    assert_include "#{issue.id},#{issue.subject},7.33", lines
  end

  def test_index_csv_with_all_columns
    get :index, :format => 'csv', :columns => 'all'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv; header=present', @response.content_type
    assert_match /\A#,/, response.body
    lines = response.body.chomp.split("\n")
    assert_equal assigns(:query).available_inline_columns.size, lines[0].split(',').size
  end

  def test_index_csv_with_multi_column_field
    CustomField.find(1).update_attribute :multiple, true
    issue = Issue.find(1)
    issue.custom_field_values = {1 => ['MySQL', 'Oracle']}
    issue.save!

    get :index, :format => 'csv', :columns => 'all'
    assert_response :success
    lines = @response.body.chomp.split("\n")
    assert lines.detect {|line| line.include?('"MySQL, Oracle"')}
  end

  def test_index_csv_should_format_float_custom_fields_with_csv_decimal_separator
    field = IssueCustomField.create!(:name => 'Float', :is_for_all => true, :tracker_ids => [1], :field_format => 'float')
    issue = Issue.generate!(:project_id => 1, :tracker_id => 1, :custom_field_values => {field.id => '185.6'})

    with_settings :default_language => 'fr' do
      get :index, :format => 'csv', :columns => 'all'
      assert_response :success
      issue_line = response.body.chomp.split("\n").map {|line| line.split(';')}.detect {|line| line[0]==issue.id.to_s}
      assert_include '185,60', issue_line
    end

    with_settings :default_language => 'en' do
      get :index, :format => 'csv', :columns => 'all'
      assert_response :success
      issue_line = response.body.chomp.split("\n").map {|line| line.split(',')}.detect {|line| line[0]==issue.id.to_s}
      assert_include '185.60', issue_line
    end
  end

  def test_index_csv_big_5
    with_settings :default_language => "zh-TW" do
      str_utf8  = "\xe4\xb8\x80\xe6\x9c\x88"
      str_big5  = "\xa4@\xa4\xeb"
      if str_utf8.respond_to?(:force_encoding)
        str_utf8.force_encoding('UTF-8')
        str_big5.force_encoding('Big5')
      end
      issue = Issue.generate!(:subject => str_utf8)

      get :index, :project_id => 1, 
                  :f => ['subject'], 
                  :op => '=', :values => [str_utf8],
                  :format => 'csv'
      assert_equal 'text/csv; header=present', @response.content_type
      lines = @response.body.chomp.split("\n")
      s1 = "\xaa\xac\xbaA"
      if str_utf8.respond_to?(:force_encoding)
        s1.force_encoding('Big5')
      end
      assert_include s1, lines[0]
      assert_include str_big5, lines[1]
    end
  end

  def test_index_csv_cannot_convert_should_be_replaced_big_5
    with_settings :default_language => "zh-TW" do
      str_utf8  = "\xe4\xbb\xa5\xe5\x86\x85"
      if str_utf8.respond_to?(:force_encoding)
        str_utf8.force_encoding('UTF-8')
      end
      issue = Issue.generate!(:subject => str_utf8)

      get :index, :project_id => 1, 
                  :f => ['subject'], 
                  :op => '=', :values => [str_utf8],
                  :c => ['status', 'subject'],
                  :format => 'csv',
                  :set_filter => 1
      assert_equal 'text/csv; header=present', @response.content_type
      lines = @response.body.chomp.split("\n")
      s1 = "\xaa\xac\xbaA" # status
      if str_utf8.respond_to?(:force_encoding)
        s1.force_encoding('Big5')
      end
      assert lines[0].include?(s1)
      s2 = lines[1].split(",")[2]
      if s1.respond_to?(:force_encoding)
        s3 = "\xa5H?" # subject
        s3.force_encoding('Big5')
        assert_equal s3, s2
      elsif RUBY_PLATFORM == 'java'
        assert_equal "??", s2
      else
        assert_equal "\xa5H???", s2
      end
    end
  end

  def test_index_csv_tw
    with_settings :default_language => "zh-TW" do
      str1  = "test_index_csv_tw"
      issue = Issue.generate!(:subject => str1, :estimated_hours => '1234.5')

      get :index, :project_id => 1, 
                  :f => ['subject'], 
                  :op => '=', :values => [str1],
                  :c => ['estimated_hours', 'subject'],
                  :format => 'csv',
                  :set_filter => 1
      assert_equal 'text/csv; header=present', @response.content_type
      lines = @response.body.chomp.split("\n")
      assert_equal "#{issue.id},1234.50,#{str1}", lines[1]
    end
  end

  def test_index_csv_fr
    with_settings :default_language => "fr" do
      str1  = "test_index_csv_fr"
      issue = Issue.generate!(:subject => str1, :estimated_hours => '1234.5')

      get :index, :project_id => 1, 
                  :f => ['subject'], 
                  :op => '=', :values => [str1],
                  :c => ['estimated_hours', 'subject'],
                  :format => 'csv',
                  :set_filter => 1
      assert_equal 'text/csv; header=present', @response.content_type
      lines = @response.body.chomp.split("\n")
      assert_equal "#{issue.id};1234,50;#{str1}", lines[1]
    end
  end

  def test_index_pdf
    ["en", "zh", "zh-TW", "ja", "ko"].each do |lang|
      with_settings :default_language => lang do

        get :index
        assert_response :success
        assert_template 'index'

        if lang == "ja"
          if RUBY_PLATFORM != 'java'
            assert_equal "CP932", l(:general_pdf_encoding)
          end
          if RUBY_PLATFORM == 'java' && l(:general_pdf_encoding) == "CP932"
            next
          end
        end

        get :index, :format => 'pdf'
        assert_response :success
        assert_not_nil assigns(:issues)
        assert_equal 'application/pdf', @response.content_type

        get :index, :project_id => 1, :format => 'pdf'
        assert_response :success
        assert_not_nil assigns(:issues)
        assert_equal 'application/pdf', @response.content_type

        get :index, :project_id => 1, :query_id => 6, :format => 'pdf'
        assert_response :success
        assert_not_nil assigns(:issues)
        assert_equal 'application/pdf', @response.content_type
      end
    end
  end

  def test_index_pdf_with_query_grouped_by_list_custom_field
    get :index, :project_id => 1, :query_id => 9, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
    assert_equal 'application/pdf', @response.content_type
  end

  def test_index_atom
    get :index, :project_id => 'ecookbook', :format => 'atom'
    assert_response :success
    assert_template 'common/feed'
    assert_equal 'application/atom+xml', response.content_type

    assert_select 'feed' do
      assert_select 'link[rel=self][href=?]', 'http://test.host/projects/ecookbook/issues.atom'
      assert_select 'link[rel=alternate][href=?]', 'http://test.host/projects/ecookbook/issues'
      assert_select 'entry link[href=?]', 'http://test.host/issues/1'
    end
  end

  def test_index_sort
    get :index, :sort => 'tracker,id:desc'
    assert_response :success

    sort_params = @request.session['issues_index_sort']
    assert sort_params.is_a?(String)
    assert_equal 'tracker,id:desc', sort_params

    issues = assigns(:issues)
    assert_not_nil issues
    assert !issues.empty?
    assert_equal issues.sort {|a,b| a.tracker == b.tracker ? b.id <=> a.id : a.tracker <=> b.tracker }.collect(&:id), issues.collect(&:id)
  end

  def test_index_sort_by_field_not_included_in_columns
    Setting.issue_list_default_columns = %w(subject author)
    get :index, :sort => 'tracker'
  end
  
  def test_index_sort_by_assigned_to
    get :index, :sort => 'assigned_to'
    assert_response :success
    assignees = assigns(:issues).collect(&:assigned_to).compact
    assert_equal assignees.sort, assignees
  end
  
  def test_index_sort_by_assigned_to_desc
    get :index, :sort => 'assigned_to:desc'
    assert_response :success
    assignees = assigns(:issues).collect(&:assigned_to).compact
    assert_equal assignees.sort.reverse, assignees
  end
  
  def test_index_group_by_assigned_to
    get :index, :group_by => 'assigned_to', :sort => 'priority'
    assert_response :success
  end
  
  def test_index_sort_by_author
    get :index, :sort => 'author'
    assert_response :success
    authors = assigns(:issues).collect(&:author)
    assert_equal authors.sort, authors
  end
  
  def test_index_sort_by_author_desc
    get :index, :sort => 'author:desc'
    assert_response :success
    authors = assigns(:issues).collect(&:author)
    assert_equal authors.sort.reverse, authors
  end
  
  def test_index_group_by_author
    get :index, :group_by => 'author', :sort => 'priority'
    assert_response :success
  end
  
  def test_index_sort_by_spent_hours
    get :index, :sort => 'spent_hours:desc'
    assert_response :success
    hours = assigns(:issues).collect(&:spent_hours)
    assert_equal hours.sort.reverse, hours
  end

  def test_index_sort_by_user_custom_field
    cf = IssueCustomField.create!(:name => 'User', :is_for_all => true, :tracker_ids => [1,2,3], :field_format => 'user')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(1), :value => '2')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(2), :value => '3')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(3), :value => '3')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(5), :value => '')

    get :index, :project_id => 1, :set_filter => 1, :sort => "cf_#{cf.id},id"
    assert_response :success

    assert_equal [2, 3, 1], assigns(:issues).select {|issue| issue.custom_field_value(cf).present?}.map(&:id)
  end

  def test_index_with_columns
    columns = ['tracker', 'subject', 'assigned_to']
    get :index, :set_filter => 1, :c => columns
    assert_response :success

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of IssueQuery, query
    assert_equal columns, query.column_names.map(&:to_s)

    # columns should be stored in session
    assert_kind_of Hash, session[:query]
    assert_kind_of Array, session[:query][:column_names]
    assert_equal columns, session[:query][:column_names].map(&:to_s)

    # ensure only these columns are kept in the selected columns list
    assert_select 'select#selected_columns option' do
      assert_select 'option', 3
      assert_select 'option[value=tracker]'
      assert_select 'option[value=project]', 0
    end
  end

  def test_index_without_project_should_implicitly_add_project_column_to_default_columns
    Setting.issue_list_default_columns = ['tracker', 'subject', 'assigned_to']
    get :index, :set_filter => 1

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of IssueQuery, query
    assert_equal [:id, :project, :tracker, :subject, :assigned_to], query.columns.map(&:name)
  end

  def test_index_without_project_and_explicit_default_columns_should_not_add_project_column
    Setting.issue_list_default_columns = ['tracker', 'subject', 'assigned_to']
    columns = ['id', 'tracker', 'subject', 'assigned_to']
    get :index, :set_filter => 1, :c => columns

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of IssueQuery, query
    assert_equal columns.map(&:to_sym), query.columns.map(&:name)
  end

  def test_index_with_custom_field_column
    columns = %w(tracker subject cf_2)
    get :index, :set_filter => 1, :c => columns
    assert_response :success

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of IssueQuery, query
    assert_equal columns, query.column_names.map(&:to_s)

    assert_select 'table.issues td.cf_2.string'
  end

  def test_index_with_multi_custom_field_column
    field = CustomField.find(1)
    field.update_attribute :multiple, true
    issue = Issue.find(1)
    issue.custom_field_values = {1 => ['MySQL', 'Oracle']}
    issue.save!

    get :index, :set_filter => 1, :c => %w(tracker subject cf_1)
    assert_response :success

    assert_select 'table.issues td.cf_1', :text => 'MySQL, Oracle'
  end

  def test_index_with_multi_user_custom_field_column
    field = IssueCustomField.create!(:name => 'Multi user', :field_format => 'user', :multiple => true,
      :tracker_ids => [1], :is_for_all => true)
    issue = Issue.find(1)
    issue.custom_field_values = {field.id => ['2', '3']}
    issue.save!

    get :index, :set_filter => 1, :c => ['tracker', 'subject', "cf_#{field.id}"]
    assert_response :success

    assert_select "table.issues td.cf_#{field.id}" do
      assert_select 'a', 2
      assert_select 'a[href=?]', '/users/2', :text => 'John Smith'
      assert_select 'a[href=?]', '/users/3', :text => 'Dave Lopper'
    end
  end

  def test_index_with_date_column
    with_settings :date_format => '%d/%m/%Y' do
      Issue.find(1).update_attribute :start_date, '1987-08-24'
      get :index, :set_filter => 1, :c => %w(start_date)
      assert_select "table.issues td.start_date", :text => '24/08/1987'
    end
  end

  def test_index_with_done_ratio_column
    Issue.find(1).update_attribute :done_ratio, 40
    get :index, :set_filter => 1, :c => %w(done_ratio)
    assert_select 'table.issues td.done_ratio' do
      assert_select 'table.progress' do
        assert_select 'td.closed[style=?]', 'width: 40%;'
      end
    end
  end

  def test_index_with_spent_hours_column
    get :index, :set_filter => 1, :c => %w(subject spent_hours)
    assert_select 'table.issues tr#issue-3 td.spent_hours', :text => '1.00'
  end

  def test_index_should_not_show_spent_hours_column_without_permission
    Role.anonymous.remove_permission! :view_time_entries
    get :index, :set_filter => 1, :c => %w(subject spent_hours)
    assert_select 'td.spent_hours', 0
  end

  def test_index_with_fixed_version_column
    get :index, :set_filter => 1, :c => %w(fixed_version)
    assert_select 'table.issues td.fixed_version' do
      assert_select 'a[href=?]', '/versions/2', :text => '1.0'
    end
  end

  def test_index_with_relations_column
    IssueRelation.delete_all
    IssueRelation.create!(:relation_type => "relates", :issue_from => Issue.find(1), :issue_to => Issue.find(7))
    IssueRelation.create!(:relation_type => "relates", :issue_from => Issue.find(8), :issue_to => Issue.find(1))
    IssueRelation.create!(:relation_type => "blocks", :issue_from => Issue.find(1), :issue_to => Issue.find(11))
    IssueRelation.create!(:relation_type => "blocks", :issue_from => Issue.find(12), :issue_to => Issue.find(2))

    get :index, :set_filter => 1, :c => %w(subject relations)
    assert_response :success
    assert_select "tr#issue-1 td.relations" do
      assert_select "span", 3
      assert_select "span", :text => "Related to #7"
      assert_select "span", :text => "Related to #8"
      assert_select "span", :text => "Blocks #11"
    end
    assert_select "tr#issue-2 td.relations" do
      assert_select "span", 1
      assert_select "span", :text => "Blocked by #12"
    end
    assert_select "tr#issue-3 td.relations" do
      assert_select "span", 0
    end

    get :index, :set_filter => 1, :c => %w(relations), :format => 'csv'
    assert_response :success
    assert_equal 'text/csv; header=present', response.content_type
    lines = response.body.chomp.split("\n")
    assert_include '1,"Related to #7, Related to #8, Blocks #11"', lines
    assert_include '2,Blocked by #12', lines
    assert_include '3,""', lines

    get :index, :set_filter => 1, :c => %w(subject relations), :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', response.content_type
  end

  def test_index_with_description_column
    get :index, :set_filter => 1, :c => %w(subject description)

    assert_select 'table.issues thead th', 3 # columns: chekbox + id + subject
    assert_select 'td.description[colspan=3]', :text => 'Unable to print recipes'

    get :index, :set_filter => 1, :c => %w(subject description), :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', response.content_type
  end

  def test_index_send_html_if_query_is_invalid
    get :index, :f => ['start_date'], :op => {:start_date => '='}
    assert_equal 'text/html', @response.content_type
    assert_template 'index'
  end

  def test_index_send_nothing_if_query_is_invalid
    get :index, :f => ['start_date'], :op => {:start_date => '='}, :format => 'csv'
    assert_equal 'text/csv', @response.content_type
    assert @response.body.blank?
  end

  def test_show_by_anonymous
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_equal Issue.find(1), assigns(:issue)
    assert_select 'div.issue div.description', :text => /Unable to print recipes/
    # anonymous role is allowed to add a note
    assert_select 'form#issue-form' do
      assert_select 'fieldset' do
        assert_select 'legend', :text => 'Notes'
        assert_select 'textarea[name=?]', 'issue[notes]'
      end
    end
    assert_select 'title', :text => "Bug #1: #{ESCAPED_UCANT} print recipes - eCookbook - Redmine"
  end

  def test_show_by_manager
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success
    assert_select 'a', :text => /Quote/
    assert_select 'form#issue-form' do
      assert_select 'fieldset' do
        assert_select 'legend', :text => 'Change properties'
        assert_select 'input[name=?]', 'issue[subject]'
      end
      assert_select 'fieldset' do
        assert_select 'legend', :text => 'Log time'
        assert_select 'input[name=?]', 'time_entry[hours]'
      end
      assert_select 'fieldset' do
        assert_select 'legend', :text => 'Notes'
        assert_select 'textarea[name=?]', 'issue[notes]'
      end
    end
  end

  def test_show_should_display_update_form
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success

    assert_select 'form#issue-form' do
      assert_select 'input[name=?]', 'issue[is_private]'
      assert_select 'select[name=?]', 'issue[project_id]'
      assert_select 'select[name=?]', 'issue[tracker_id]'
      assert_select 'input[name=?]', 'issue[subject]'
      assert_select 'textarea[name=?]', 'issue[description]'
      assert_select 'select[name=?]', 'issue[status_id]'
      assert_select 'select[name=?]', 'issue[priority_id]'
      assert_select 'select[name=?]', 'issue[assigned_to_id]'
      assert_select 'select[name=?]', 'issue[category_id]'
      assert_select 'select[name=?]', 'issue[fixed_version_id]'
      assert_select 'input[name=?]', 'issue[parent_issue_id]'
      assert_select 'input[name=?]', 'issue[start_date]'
      assert_select 'input[name=?]', 'issue[due_date]'
      assert_select 'select[name=?]', 'issue[done_ratio]'
      assert_select 'input[name=?]', 'issue[custom_field_values][2]'
      assert_select 'input[name=?]', 'issue[watcher_user_ids][]', 0
      assert_select 'textarea[name=?]', 'issue[notes]'
    end
  end

  def test_show_should_display_update_form_with_minimal_permissions
    Role.find(1).update_attribute :permissions, [:view_issues, :add_issue_notes]
    WorkflowTransition.delete_all :role_id => 1

    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success

    assert_select 'form#issue-form' do
      assert_select 'input[name=?]', 'issue[is_private]', 0
      assert_select 'select[name=?]', 'issue[project_id]', 0
      assert_select 'select[name=?]', 'issue[tracker_id]', 0
      assert_select 'input[name=?]', 'issue[subject]', 0
      assert_select 'textarea[name=?]', 'issue[description]', 0
      assert_select 'select[name=?]', 'issue[status_id]', 0
      assert_select 'select[name=?]', 'issue[priority_id]', 0
      assert_select 'select[name=?]', 'issue[assigned_to_id]', 0
      assert_select 'select[name=?]', 'issue[category_id]', 0
      assert_select 'select[name=?]', 'issue[fixed_version_id]', 0
      assert_select 'input[name=?]', 'issue[parent_issue_id]', 0
      assert_select 'input[name=?]', 'issue[start_date]', 0
      assert_select 'input[name=?]', 'issue[due_date]', 0
      assert_select 'select[name=?]', 'issue[done_ratio]', 0
      assert_select 'input[name=?]', 'issue[custom_field_values][2]', 0
      assert_select 'input[name=?]', 'issue[watcher_user_ids][]', 0
      assert_select 'textarea[name=?]', 'issue[notes]'
    end
  end

  def test_show_should_display_update_form_with_workflow_permissions
    Role.find(1).update_attribute :permissions, [:view_issues, :add_issue_notes]

    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success

    assert_select 'form#issue-form' do
      assert_select 'input[name=?]', 'issue[is_private]', 0
      assert_select 'select[name=?]', 'issue[project_id]', 0
      assert_select 'select[name=?]', 'issue[tracker_id]', 0
      assert_select 'input[name=?]', 'issue[subject]', 0
      assert_select 'textarea[name=?]', 'issue[description]', 0
      assert_select 'select[name=?]', 'issue[status_id]'
      assert_select 'select[name=?]', 'issue[priority_id]', 0
      assert_select 'select[name=?]', 'issue[assigned_to_id]'
      assert_select 'select[name=?]', 'issue[category_id]', 0
      assert_select 'select[name=?]', 'issue[fixed_version_id]'
      assert_select 'input[name=?]', 'issue[parent_issue_id]', 0
      assert_select 'input[name=?]', 'issue[start_date]', 0
      assert_select 'input[name=?]', 'issue[due_date]', 0
      assert_select 'select[name=?]', 'issue[done_ratio]'
      assert_select 'input[name=?]', 'issue[custom_field_values][2]', 0
      assert_select 'input[name=?]', 'issue[watcher_user_ids][]', 0
      assert_select 'textarea[name=?]', 'issue[notes]'
    end
  end

  def test_show_should_not_display_update_form_without_permissions
    Role.find(1).update_attribute :permissions, [:view_issues]

    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success

    assert_select 'form#issue-form', 0
  end

  def test_update_form_should_not_display_inactive_enumerations
    assert !IssuePriority.find(15).active?

    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success

    assert_select 'form#issue-form' do
      assert_select 'select[name=?]', 'issue[priority_id]' do
        assert_select 'option[value=4]'
        assert_select 'option[value=15]', 0
      end
    end
  end

  def test_update_form_should_allow_attachment_upload
    @request.session[:user_id] = 2
    get :show, :id => 1

    assert_select 'form#issue-form[method=post][enctype=multipart/form-data]' do
      assert_select 'input[type=file][name=?]', 'attachments[dummy][file]'
    end
  end

  def test_show_should_deny_anonymous_access_without_permission
    Role.anonymous.remove_permission!(:view_issues)
    get :show, :id => 1
    assert_response :redirect
  end

  def test_show_should_deny_anonymous_access_to_private_issue
    Issue.where(:id => 1).update_all(["is_private = ?", true])
    get :show, :id => 1
    assert_response :redirect
  end

  def test_show_should_deny_non_member_access_without_permission
    Role.non_member.remove_permission!(:view_issues)
    @request.session[:user_id] = 9
    get :show, :id => 1
    assert_response 403
  end

  def test_show_should_deny_non_member_access_to_private_issue
    Issue.where(:id => 1).update_all(["is_private = ?", true])
    @request.session[:user_id] = 9
    get :show, :id => 1
    assert_response 403
  end

  def test_show_should_deny_member_access_without_permission
    Role.find(1).remove_permission!(:view_issues)
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response 403
  end

  def test_show_should_deny_member_access_to_private_issue_without_permission
    Issue.where(:id => 1).update_all(["is_private = ?", true])
    @request.session[:user_id] = 3
    get :show, :id => 1
    assert_response 403
  end

  def test_show_should_allow_author_access_to_private_issue
    Issue.where(:id => 1).update_all(["is_private = ?, author_id = 3", true])
    @request.session[:user_id] = 3
    get :show, :id => 1
    assert_response :success
  end

  def test_show_should_allow_assignee_access_to_private_issue
    Issue.where(:id => 1).update_all(["is_private = ?, assigned_to_id = 3", true])
    @request.session[:user_id] = 3
    get :show, :id => 1
    assert_response :success
  end

  def test_show_should_allow_member_access_to_private_issue_with_permission
    Issue.where(:id => 1).update_all(["is_private = ?", true])
    User.find(3).roles_for_project(Project.find(1)).first.update_attribute :issues_visibility, 'all'
    @request.session[:user_id] = 3
    get :show, :id => 1
    assert_response :success
  end

  def test_show_should_not_disclose_relations_to_invisible_issues
    Setting.cross_project_issue_relations = '1'
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(2), :relation_type => 'relates')
    # Relation to a private project issue
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(4), :relation_type => 'relates')

    get :show, :id => 1
    assert_response :success

    assert_select 'div#relations' do
      assert_select 'a', :text => /#2$/
      assert_select 'a', :text => /#4$/, :count => 0
    end
  end

  def test_show_should_list_subtasks
    Issue.create!(:project_id => 1, :author_id => 1, :tracker_id => 1, :parent_issue_id => 1, :subject => 'Child Issue')

    get :show, :id => 1
    assert_response :success

    assert_select 'div#issue_tree' do
      assert_select 'td.subject', :text => /Child Issue/
    end
  end

  def test_show_should_list_parents
    issue = Issue.create!(:project_id => 1, :author_id => 1, :tracker_id => 1, :parent_issue_id => 1, :subject => 'Child Issue')

    get :show, :id => issue.id
    assert_response :success

    assert_select 'div.subject' do
      assert_select 'h3', 'Child Issue'
      assert_select 'a[href=/issues/1]'
    end
  end

  def test_show_should_not_display_prev_next_links_without_query_in_session
    get :show, :id => 1
    assert_response :success
    assert_nil assigns(:prev_issue_id)
    assert_nil assigns(:next_issue_id)

    assert_select 'div.next-prev-links', 0
  end

  def test_show_should_display_prev_next_links_with_query_in_session
    @request.session[:query] = {:filters => {'status_id' => {:values => [''], :operator => 'o'}}, :project_id => nil}
    @request.session['issues_index_sort'] = 'id'

    with_settings :display_subprojects_issues => '0' do
      get :show, :id => 3
    end

    assert_response :success
    # Previous and next issues for all projects
    assert_equal 2, assigns(:prev_issue_id)
    assert_equal 5, assigns(:next_issue_id)

    count = Issue.open.visible.count

    assert_select 'div.next-prev-links' do
      assert_select 'a[href=/issues/2]', :text => /Previous/
      assert_select 'a[href=/issues/5]', :text => /Next/
      assert_select 'span.position', :text => "3 of #{count}"
    end
  end

  def test_show_should_display_prev_next_links_with_saved_query_in_session
    query = IssueQuery.create!(:name => 'test', :visibility => IssueQuery::VISIBILITY_PUBLIC,  :user_id => 1,
      :filters => {'status_id' => {:values => ['5'], :operator => '='}},
      :sort_criteria => [['id', 'asc']])
    @request.session[:query] = {:id => query.id, :project_id => nil}

    get :show, :id => 11

    assert_response :success
    assert_equal query, assigns(:query)
    # Previous and next issues for all projects
    assert_equal 8, assigns(:prev_issue_id)
    assert_equal 12, assigns(:next_issue_id)

    assert_select 'div.next-prev-links' do
      assert_select 'a[href=/issues/8]', :text => /Previous/
      assert_select 'a[href=/issues/12]', :text => /Next/
    end
  end

  def test_show_should_display_prev_next_links_with_query_and_sort_on_association
    @request.session[:query] = {:filters => {'status_id' => {:values => [''], :operator => 'o'}}, :project_id => nil}
    
    %w(project tracker status priority author assigned_to category fixed_version).each do |assoc_sort|
      @request.session['issues_index_sort'] = assoc_sort

      get :show, :id => 3
      assert_response :success, "Wrong response status for #{assoc_sort} sort"

      assert_select 'div.next-prev-links' do
        assert_select 'a', :text => /(Previous|Next)/
      end
    end
  end

  def test_show_should_display_prev_next_links_with_project_query_in_session
    @request.session[:query] = {:filters => {'status_id' => {:values => [''], :operator => 'o'}}, :project_id => 1}
    @request.session['issues_index_sort'] = 'id'

    with_settings :display_subprojects_issues => '0' do
      get :show, :id => 3
    end

    assert_response :success
    # Previous and next issues inside project
    assert_equal 2, assigns(:prev_issue_id)
    assert_equal 7, assigns(:next_issue_id)

    assert_select 'div.next-prev-links' do
      assert_select 'a[href=/issues/2]', :text => /Previous/
      assert_select 'a[href=/issues/7]', :text => /Next/
    end
  end

  def test_show_should_not_display_prev_link_for_first_issue
    @request.session[:query] = {:filters => {'status_id' => {:values => [''], :operator => 'o'}}, :project_id => 1}
    @request.session['issues_index_sort'] = 'id'

    with_settings :display_subprojects_issues => '0' do
      get :show, :id => 1
    end

    assert_response :success
    assert_nil assigns(:prev_issue_id)
    assert_equal 2, assigns(:next_issue_id)

    assert_select 'div.next-prev-links' do
      assert_select 'a', :text => /Previous/, :count => 0
      assert_select 'a[href=/issues/2]', :text => /Next/
    end
  end

  def test_show_should_not_display_prev_next_links_for_issue_not_in_query_results
    @request.session[:query] = {:filters => {'status_id' => {:values => [''], :operator => 'c'}}, :project_id => 1}
    @request.session['issues_index_sort'] = 'id'

    get :show, :id => 1

    assert_response :success
    assert_nil assigns(:prev_issue_id)
    assert_nil assigns(:next_issue_id)

    assert_select 'a', :text => /Previous/, :count => 0
    assert_select 'a', :text => /Next/, :count => 0
  end

  def test_show_show_should_display_prev_next_links_with_query_sort_by_user_custom_field
    cf = IssueCustomField.create!(:name => 'User', :is_for_all => true, :tracker_ids => [1,2,3], :field_format => 'user')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(1), :value => '2')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(2), :value => '3')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(3), :value => '3')
    CustomValue.create!(:custom_field => cf, :customized => Issue.find(5), :value => '')

    query = IssueQuery.create!(:name => 'test', :visibility => IssueQuery::VISIBILITY_PUBLIC,  :user_id => 1, :filters => {},
      :sort_criteria => [["cf_#{cf.id}", 'asc'], ['id', 'asc']])
    @request.session[:query] = {:id => query.id, :project_id => nil}

    get :show, :id => 3
    assert_response :success

    assert_equal 2, assigns(:prev_issue_id)
    assert_equal 1, assigns(:next_issue_id)

    assert_select 'div.next-prev-links' do
      assert_select 'a[href=/issues/2]', :text => /Previous/
      assert_select 'a[href=/issues/1]', :text => /Next/
    end
  end

  def test_show_should_display_link_to_the_assignee
    get :show, :id => 2
    assert_response :success
    assert_select '.assigned-to' do
      assert_select 'a[href=/users/3]'
    end
  end

  def test_show_should_display_visible_changesets_from_other_projects
    project = Project.find(2)
    issue = project.issues.first
    issue.changeset_ids = [102]
    issue.save!
    # changesets from other projects should be displayed even if repository
    # is disabled on issue's project
    project.disable_module! :repository

    @request.session[:user_id] = 2
    get :show, :id => issue.id

    assert_select 'a[href=?]', '/projects/ecookbook/repository/revisions/3'
  end

  def test_show_should_display_watchers
    @request.session[:user_id] = 2
    Issue.find(1).add_watcher User.find(2)

    get :show, :id => 1
    assert_select 'div#watchers ul' do
      assert_select 'li' do
        assert_select 'a[href=/users/2]'
        assert_select 'a img[alt=Delete]'
      end
    end
  end

  def test_show_should_display_watchers_with_gravatars
    @request.session[:user_id] = 2
    Issue.find(1).add_watcher User.find(2)

    with_settings :gravatar_enabled => '1' do
      get :show, :id => 1
    end

    assert_select 'div#watchers ul' do
      assert_select 'li' do
        assert_select 'img.gravatar'
        assert_select 'a[href=/users/2]'
        assert_select 'a img[alt=Delete]'
      end
    end
  end

  def test_show_with_thumbnails_enabled_should_display_thumbnails
    @request.session[:user_id] = 2

    with_settings :thumbnails_enabled => '1' do
      get :show, :id => 14
      assert_response :success
    end

    assert_select 'div.thumbnails' do
      assert_select 'a[href=/attachments/16/testfile.png]' do
        assert_select 'img[src=/attachments/thumbnail/16]'
      end
    end
  end

  def test_show_with_thumbnails_disabled_should_not_display_thumbnails
    @request.session[:user_id] = 2

    with_settings :thumbnails_enabled => '0' do
      get :show, :id => 14
      assert_response :success
    end

    assert_select 'div.thumbnails', 0
  end

  def test_show_with_multi_custom_field
    field = CustomField.find(1)
    field.update_attribute :multiple, true
    issue = Issue.find(1)
    issue.custom_field_values = {1 => ['MySQL', 'Oracle']}
    issue.save!

    get :show, :id => 1
    assert_response :success

    assert_select 'td', :text => 'MySQL, Oracle'
  end

  def test_show_with_multi_user_custom_field
    field = IssueCustomField.create!(:name => 'Multi user', :field_format => 'user', :multiple => true,
      :tracker_ids => [1], :is_for_all => true)
    issue = Issue.find(1)
    issue.custom_field_values = {field.id => ['2', '3']}
    issue.save!

    get :show, :id => 1
    assert_response :success

    assert_select "td.cf_#{field.id}", :text => 'Dave Lopper, John Smith' do
      assert_select 'a', :text => 'Dave Lopper'
      assert_select 'a', :text => 'John Smith'
    end
  end

  def test_show_should_display_private_notes_with_permission_only
    journal = Journal.create!(:journalized => Issue.find(2), :notes => 'Privates notes', :private_notes => true, :user_id => 1)
    @request.session[:user_id] = 2

    get :show, :id => 2
    assert_response :success
    assert_include journal, assigns(:journals)

    Role.find(1).remove_permission! :view_private_notes
    get :show, :id => 2
    assert_response :success
    assert_not_include journal, assigns(:journals)
  end

  def test_show_atom
    get :show, :id => 2, :format => 'atom'
    assert_response :success
    assert_template 'journals/index'
    # Inline image
    assert_select 'content', :text => Regexp.new(Regexp.quote('http://test.host/attachments/download/10'))
  end

  def test_show_export_to_pdf
    get :show, :id => 3, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:issue)
  end

  def test_export_to_pdf_with_utf8_u_fffd
    # U+FFFD
    s = "\xef\xbf\xbd"
    s.force_encoding('UTF-8') if s.respond_to?(:force_encoding)
    issue = Issue.generate!(:subject => s)
    ["en", "zh", "zh-TW", "ja", "ko"].each do |lang|
      with_settings :default_language => lang do
        get :show, :id => issue.id, :format => 'pdf'
        assert_response :success
        assert_equal 'application/pdf', @response.content_type
        assert @response.body.starts_with?('%PDF')
        assert_not_nil assigns(:issue)
      end
    end
  end

  def test_show_export_to_pdf_with_ancestors
    issue = Issue.generate!(:project_id => 1, :author_id => 2, :tracker_id => 1, :subject => 'child', :parent_issue_id => 1)

    get :show, :id => issue.id, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
  end

  def test_show_export_to_pdf_with_descendants
    c1 = Issue.generate!(:project_id => 1, :author_id => 2, :tracker_id => 1, :subject => 'child', :parent_issue_id => 1)
    c2 = Issue.generate!(:project_id => 1, :author_id => 2, :tracker_id => 1, :subject => 'child', :parent_issue_id => 1)
    c3 = Issue.generate!(:project_id => 1, :author_id => 2, :tracker_id => 1, :subject => 'child', :parent_issue_id => c1.id)

    get :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
  end

  def test_show_export_to_pdf_with_journals
    get :show, :id => 1, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
  end

  def test_show_export_to_pdf_with_changesets
    [[100], [100, 101], [100, 101, 102]].each do |cs|
      issue1 = Issue.find(3)
      issue1.changesets = Changeset.find(cs)
      issue1.save!
      issue = Issue.find(3)
      assert_equal issue.changesets.count, cs.size
      get :show, :id => 3, :format => 'pdf'
      assert_response :success
      assert_equal 'application/pdf', @response.content_type
      assert @response.body.starts_with?('%PDF')
    end
  end

  def test_show_invalid_should_respond_with_404
    get :show, :id => 999
    assert_response 404
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'form#issue-form' do
      assert_select 'input[name=?]', 'issue[is_private]'
      assert_select 'select[name=?]', 'issue[project_id]', 0
      assert_select 'select[name=?]', 'issue[tracker_id]'
      assert_select 'input[name=?]', 'issue[subject]'
      assert_select 'textarea[name=?]', 'issue[description]'
      assert_select 'select[name=?]', 'issue[status_id]'
      assert_select 'select[name=?]', 'issue[priority_id]'
      assert_select 'select[name=?]', 'issue[assigned_to_id]'
      assert_select 'select[name=?]', 'issue[category_id]'
      assert_select 'select[name=?]', 'issue[fixed_version_id]'
      assert_select 'input[name=?]', 'issue[parent_issue_id]'
      assert_select 'input[name=?]', 'issue[start_date]'
      assert_select 'input[name=?]', 'issue[due_date]'
      assert_select 'select[name=?]', 'issue[done_ratio]'
      assert_select 'input[name=?][value=?]', 'issue[custom_field_values][2]', 'Default string'
      assert_select 'input[name=?]', 'issue[watcher_user_ids][]'
    end

    # Be sure we don't display inactive IssuePriorities
    assert ! IssuePriority.find(15).active?
    assert_select 'select[name=?]', 'issue[priority_id]' do
      assert_select 'option[value=15]', 0
    end
  end

  def test_get_new_with_minimal_permissions
    Role.find(1).update_attribute :permissions, [:add_issues]
    WorkflowTransition.delete_all :role_id => 1

    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'form#issue-form' do
      assert_select 'input[name=?]', 'issue[is_private]', 0
      assert_select 'select[name=?]', 'issue[project_id]', 0
      assert_select 'select[name=?]', 'issue[tracker_id]'
      assert_select 'input[name=?]', 'issue[subject]'
      assert_select 'textarea[name=?]', 'issue[description]'
      assert_select 'select[name=?]', 'issue[status_id]'
      assert_select 'select[name=?]', 'issue[priority_id]'
      assert_select 'select[name=?]', 'issue[assigned_to_id]'
      assert_select 'select[name=?]', 'issue[category_id]'
      assert_select 'select[name=?]', 'issue[fixed_version_id]'
      assert_select 'input[name=?]', 'issue[parent_issue_id]', 0
      assert_select 'input[name=?]', 'issue[start_date]'
      assert_select 'input[name=?]', 'issue[due_date]'
      assert_select 'select[name=?]', 'issue[done_ratio]'
      assert_select 'input[name=?][value=?]', 'issue[custom_field_values][2]', 'Default string'
      assert_select 'input[name=?]', 'issue[watcher_user_ids][]', 0
    end
  end

  def test_get_new_with_list_custom_field
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'select.list_cf[name=?]', 'issue[custom_field_values][1]' do
      assert_select 'option', 4
      assert_select 'option[value=MySQL]', :text => 'MySQL'
    end
  end

  def test_get_new_with_multi_custom_field
    field = IssueCustomField.find(1)
    field.update_attribute :multiple, true

    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'select[name=?][multiple=multiple]', 'issue[custom_field_values][1][]' do
      assert_select 'option', 3
      assert_select 'option[value=MySQL]', :text => 'MySQL'
    end
    assert_select 'input[name=?][type=hidden][value=?]', 'issue[custom_field_values][1][]', ''
  end

  def test_get_new_with_multi_user_custom_field
    field = IssueCustomField.create!(:name => 'Multi user', :field_format => 'user', :multiple => true,
      :tracker_ids => [1], :is_for_all => true)

    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'select[name=?][multiple=multiple]', "issue[custom_field_values][#{field.id}][]" do
      assert_select 'option', Project.find(1).users.count
      assert_select 'option[value=2]', :text => 'John Smith'
    end
    assert_select 'input[name=?][type=hidden][value=?]', "issue[custom_field_values][#{field.id}][]", ''
  end

  def test_get_new_with_date_custom_field
    field = IssueCustomField.create!(:name => 'Date', :field_format => 'date', :tracker_ids => [1], :is_for_all => true)

    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success

    assert_select 'input[name=?]', "issue[custom_field_values][#{field.id}]"
  end

  def test_get_new_with_text_custom_field
    field = IssueCustomField.create!(:name => 'Text', :field_format => 'text', :tracker_ids => [1], :is_for_all => true)

    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1
    assert_response :success

    assert_select 'textarea[name=?]', "issue[custom_field_values][#{field.id}]"
  end

  def test_get_new_without_default_start_date_is_creation_date
    with_settings :default_issue_start_date_to_creation_date  => 0 do
      @request.session[:user_id] = 2
      get :new, :project_id => 1, :tracker_id => 1
      assert_response :success
      assert_template 'new'
      assert_select 'input[name=?]', 'issue[start_date]'
      assert_select 'input[name=?][value]', 'issue[start_date]', 0
    end
  end

  def test_get_new_with_default_start_date_is_creation_date
    with_settings :default_issue_start_date_to_creation_date  => 1 do
      @request.session[:user_id] = 2
      get :new, :project_id => 1, :tracker_id => 1
      assert_response :success
      assert_template 'new'
      assert_select 'input[name=?][value=?]', 'issue[start_date]',
                    Date.today.to_s
    end
  end

  def test_get_new_form_should_allow_attachment_upload
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :tracker_id => 1

    assert_select 'form[id=issue-form][method=post][enctype=multipart/form-data]' do
      assert_select 'input[name=?][type=file]', 'attachments[dummy][file]'
    end
  end

  def test_get_new_should_prefill_the_form_from_params
    @request.session[:user_id] = 2
    get :new, :project_id => 1,
      :issue => {:tracker_id => 3, :description => 'Prefilled', :custom_field_values => {'2' => 'Custom field value'}}

    issue = assigns(:issue)
    assert_equal 3, issue.tracker_id
    assert_equal 'Prefilled', issue.description
    assert_equal 'Custom field value', issue.custom_field_value(2)

    assert_select 'select[name=?]', 'issue[tracker_id]' do
      assert_select 'option[value=3][selected=selected]'
    end
    assert_select 'textarea[name=?]', 'issue[description]', :text => /Prefilled/
    assert_select 'input[name=?][value=?]', 'issue[custom_field_values][2]', 'Custom field value'
  end

  def test_get_new_should_mark_required_fields
    cf1 = IssueCustomField.create!(:name => 'Foo', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    cf2 = IssueCustomField.create!(:name => 'Bar', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    WorkflowPermission.delete_all
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 1, :role_id => 1, :field_name => 'due_date', :rule => 'required')
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 1, :role_id => 1, :field_name => cf2.id.to_s, :rule => 'required')
    @request.session[:user_id] = 2

    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'label[for=issue_start_date]' do
      assert_select 'span[class=required]', 0
    end
    assert_select 'label[for=issue_due_date]' do
      assert_select 'span[class=required]'
    end
    assert_select 'label[for=?]', "issue_custom_field_values_#{cf1.id}" do
      assert_select 'span[class=required]', 0
    end
    assert_select 'label[for=?]', "issue_custom_field_values_#{cf2.id}" do
      assert_select 'span[class=required]'
    end
  end

  def test_get_new_should_not_display_readonly_fields
    cf1 = IssueCustomField.create!(:name => 'Foo', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    cf2 = IssueCustomField.create!(:name => 'Bar', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    WorkflowPermission.delete_all
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 1, :role_id => 1, :field_name => 'due_date', :rule => 'readonly')
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 1, :role_id => 1, :field_name => cf2.id.to_s, :rule => 'readonly')
    @request.session[:user_id] = 2

    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'

    assert_select 'input[name=?]', 'issue[start_date]'
    assert_select 'input[name=?]', 'issue[due_date]', 0
    assert_select 'input[name=?]', "issue[custom_field_values][#{cf1.id}]"
    assert_select 'input[name=?]', "issue[custom_field_values][#{cf2.id}]", 0
  end

  def test_get_new_without_tracker_id
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'

    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal Project.find(1).trackers.first, issue.tracker
  end

  def test_get_new_with_no_default_status_should_display_an_error
    @request.session[:user_id] = 2
    IssueStatus.delete_all

    get :new, :project_id => 1
    assert_response 500
    assert_error_tag :content => /No default issue/
  end

  def test_get_new_with_no_tracker_should_display_an_error
    @request.session[:user_id] = 2
    Tracker.delete_all

    get :new, :project_id => 1
    assert_response 500
    assert_error_tag :content => /No tracker/
  end

  def test_update_form_for_new_issue
    @request.session[:user_id] = 2
    xhr :post, :update_form, :project_id => 1,
                     :issue => {:tracker_id => 2,
                                :subject => 'This is the test_new issue',
                                :description => 'This is the description',
                                :priority_id => 5}
    assert_response :success
    assert_template 'update_form'
    assert_template :partial => '_form'
    assert_equal 'text/javascript', response.content_type

    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 'This is the test_new issue', issue.subject
  end

  def test_update_form_for_new_issue_should_propose_transitions_based_on_initial_status
    @request.session[:user_id] = 2
    WorkflowTransition.delete_all
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 1, :new_status_id => 2)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 1, :new_status_id => 5)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 5, :new_status_id => 4)

    xhr :post, :update_form, :project_id => 1,
                     :issue => {:tracker_id => 1,
                                :status_id => 5,
                                :subject => 'This is an issue'}

    assert_equal 5, assigns(:issue).status_id
    assert_equal [1,2,5], assigns(:allowed_statuses).map(&:id).sort
  end

  def test_post_create
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 3,
                            :status_id => 2,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :start_date => '2010-11-07',
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    issue = Issue.find_by_subject('This is the test_new issue')
    assert_not_nil issue
    assert_equal 2, issue.author_id
    assert_equal 3, issue.tracker_id
    assert_equal 2, issue.status_id
    assert_equal Date.parse('2010-11-07'), issue.start_date
    assert_nil issue.estimated_hours
    v = issue.custom_values.where(:custom_field_id => 2).first
    assert_not_nil v
    assert_equal 'Value for field 2', v.value
  end

  def test_post_new_with_group_assignment
    group = Group.find(11)
    project = Project.find(1)
    project.members << Member.new(:principal => group, :roles => [Role.givable.first])

    with_settings :issue_group_assignment => '1' do
      @request.session[:user_id] = 2
      assert_difference 'Issue.count' do
        post :create, :project_id => project.id,
                      :issue => {:tracker_id => 3,
                                 :status_id => 1,
                                 :subject => 'This is the test_new_with_group_assignment issue',
                                 :assigned_to_id => group.id}
      end
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    issue = Issue.find_by_subject('This is the test_new_with_group_assignment issue')
    assert_not_nil issue
    assert_equal group, issue.assigned_to
  end

  def test_post_create_without_start_date_and_default_start_date_is_not_creation_date
    with_settings :default_issue_start_date_to_creation_date  => 0 do
      @request.session[:user_id] = 2
      assert_difference 'Issue.count' do
        post :create, :project_id => 1,
                 :issue => {:tracker_id => 3,
                            :status_id => 2,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
      end
      assert_redirected_to :controller => 'issues', :action => 'show',
                           :id => Issue.last.id
      issue = Issue.find_by_subject('This is the test_new issue')
      assert_not_nil issue
      assert_nil issue.start_date
    end
  end

  def test_post_create_without_start_date_and_default_start_date_is_creation_date
    with_settings :default_issue_start_date_to_creation_date  => 1 do
      @request.session[:user_id] = 2
      assert_difference 'Issue.count' do
        post :create, :project_id => 1,
                 :issue => {:tracker_id => 3,
                            :status_id => 2,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
      end
      assert_redirected_to :controller => 'issues', :action => 'show',
                           :id => Issue.last.id
      issue = Issue.find_by_subject('This is the test_new issue')
      assert_not_nil issue
      assert_equal Date.today, issue.start_date
    end
  end

  def test_post_create_and_continue
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
        :issue => {:tracker_id => 3, :subject => 'This is first issue', :priority_id => 5},
        :continue => ''
    end

    issue = Issue.order('id DESC').first
    assert_redirected_to :controller => 'issues', :action => 'new', :project_id => 'ecookbook', :issue => {:tracker_id => 3}
    assert_not_nil flash[:notice], "flash was not set"
    assert_include %|<a href="/issues/#{issue.id}" title="This is first issue">##{issue.id}</a>|, flash[:notice], "issue link not found in the flash message"
  end

  def test_post_create_without_custom_fields_param
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
  end

  def test_post_create_with_multi_custom_field
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:multiple, true)

    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :custom_field_values => {'1' => ['', 'MySQL', 'Oracle']}}
    end
    assert_response 302
    issue = Issue.order('id DESC').first
    assert_equal ['MySQL', 'Oracle'], issue.custom_field_value(1).sort
  end

  def test_post_create_with_empty_multi_custom_field
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:multiple, true)

    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :custom_field_values => {'1' => ['']}}
    end
    assert_response 302
    issue = Issue.order('id DESC').first
    assert_equal [''], issue.custom_field_value(1).sort
  end

  def test_post_create_with_multi_user_custom_field
    field = IssueCustomField.create!(:name => 'Multi user', :field_format => 'user', :multiple => true,
      :tracker_ids => [1], :is_for_all => true)

    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :custom_field_values => {field.id.to_s => ['', '2', '3']}}
    end
    assert_response 302
    issue = Issue.order('id DESC').first
    assert_equal ['2', '3'], issue.custom_field_value(field).sort
  end

  def test_post_create_with_required_custom_field_and_without_custom_fields_param
    field = IssueCustomField.find_by_name('Database')
    field.update_attribute(:is_required, true)

    @request.session[:user_id] = 2
    assert_no_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5}
    end
    assert_response :success
    assert_template 'new'
    issue = assigns(:issue)
    assert_not_nil issue
    assert_error_tag :content => /Database #{ESCAPED_CANT} be blank/
  end

  def test_create_should_validate_required_fields
    cf1 = IssueCustomField.create!(:name => 'Foo', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    cf2 = IssueCustomField.create!(:name => 'Bar', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    WorkflowPermission.delete_all
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 2, :role_id => 1, :field_name => 'due_date', :rule => 'required')
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 2, :role_id => 1, :field_name => cf2.id.to_s, :rule => 'required')
    @request.session[:user_id] = 2

    assert_no_difference 'Issue.count' do
      post :create, :project_id => 1, :issue => {
        :tracker_id => 2,
        :status_id => 1,
        :subject => 'Test',
        :start_date => '',
        :due_date => '',
        :custom_field_values => {cf1.id.to_s => '', cf2.id.to_s => ''}
      }
      assert_response :success
      assert_template 'new'
    end

    assert_error_tag :content => /Due date #{ESCAPED_CANT} be blank/i
    assert_error_tag :content => /Bar #{ESCAPED_CANT} be blank/i
  end

  def test_create_should_ignore_readonly_fields
    cf1 = IssueCustomField.create!(:name => 'Foo', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    cf2 = IssueCustomField.create!(:name => 'Bar', :field_format => 'string', :is_for_all => true, :tracker_ids => [1, 2])
    WorkflowPermission.delete_all
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 2, :role_id => 1, :field_name => 'due_date', :rule => 'readonly')
    WorkflowPermission.create!(:old_status_id => 1, :tracker_id => 2, :role_id => 1, :field_name => cf2.id.to_s, :rule => 'readonly')
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1, :issue => {
        :tracker_id => 2,
        :status_id => 1,
        :subject => 'Test',
        :start_date => '2012-07-14',
        :due_date => '2012-07-16',
        :custom_field_values => {cf1.id.to_s => 'value1', cf2.id.to_s => 'value2'}
      }
      assert_response 302
    end

    issue = Issue.order('id DESC').first
    assert_equal Date.parse('2012-07-14'), issue.start_date
    assert_nil issue.due_date
    assert_equal 'value1', issue.custom_field_value(cf1)
    assert_nil issue.custom_field_value(cf2)
  end

  def test_post_create_with_watchers
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_difference 'Watcher.count', 2 do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a new issue with watchers',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :watcher_user_ids => ['2', '3']}
    end
    issue = Issue.find_by_subject('This is a new issue with watchers')
    assert_not_nil issue
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue

    # Watchers added
    assert_equal [2, 3], issue.watcher_user_ids.sort
    assert issue.watched_by?(User.find(3))
    # Watchers notified
    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert [mail.bcc, mail.cc].flatten.include?(User.find(3).mail)
  end

  def test_post_create_subissue
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a child issue',
                            :parent_issue_id => '2'}
      assert_response 302
    end
    issue = Issue.order('id DESC').first
    assert_equal Issue.find(2), issue.parent
  end

  def test_post_create_subissue_with_sharp_parent_id
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a child issue',
                            :parent_issue_id => '#2'}
      assert_response 302
    end
    issue = Issue.order('id DESC').first
    assert_equal Issue.find(2), issue.parent
  end

  def test_post_create_subissue_with_non_visible_parent_id_should_not_validate
    @request.session[:user_id] = 2

    assert_no_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a child issue',
                            :parent_issue_id => '4'}

      assert_response :success
      assert_select 'input[name=?][value=?]', 'issue[parent_issue_id]', '4'
      assert_error_tag :content => /Parent task is invalid/i
    end
  end

  def test_post_create_subissue_with_non_numeric_parent_id_should_not_validate
    @request.session[:user_id] = 2

    assert_no_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a child issue',
                            :parent_issue_id => '01ABC'}

      assert_response :success
      assert_select 'input[name=?][value=?]', 'issue[parent_issue_id]', '01ABC'
      assert_error_tag :content => /Parent task is invalid/i
    end
  end

  def test_post_create_private
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a private issue',
                            :is_private => '1'}
    end
    issue = Issue.order('id DESC').first
    assert issue.is_private?
  end

  def test_post_create_private_with_set_own_issues_private_permission
    role = Role.find(1)
    role.remove_permission! :set_issues_private
    role.add_permission! :set_own_issues_private

    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 1,
                            :subject => 'This is a private issue',
                            :is_private => '1'}
    end
    issue = Issue.order('id DESC').first
    assert issue.is_private?
  end

  def test_post_create_should_send_a_notification
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:tracker_id => 3,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_post_create_should_preserve_fields_values_on_validation_failure
    @request.session[:user_id] = 2
    post :create, :project_id => 1,
               :issue => {:tracker_id => 1,
                          # empty subject
                          :subject => '',
                          :description => 'This is a description',
                          :priority_id => 6,
                          :custom_field_values => {'1' => 'Oracle', '2' => 'Value for field 2'}}
    assert_response :success
    assert_template 'new'

    assert_select 'textarea[name=?]', 'issue[description]', :text => 'This is a description'
    assert_select 'select[name=?]', 'issue[priority_id]' do
      assert_select 'option[value=6][selected=selected]', :text => 'High'
    end
    # Custom fields
    assert_select 'select[name=?]', 'issue[custom_field_values][1]' do
      assert_select 'option[value=Oracle][selected=selected]', :text => 'Oracle'
    end
    assert_select 'input[name=?][value=?]', 'issue[custom_field_values][2]', 'Value for field 2'
  end

  def test_post_create_with_failure_should_preserve_watchers
    assert !User.find(8).member_of?(Project.find(1))

    @request.session[:user_id] = 2
    post :create, :project_id => 1,
         :issue => {:tracker_id => 1,
                    :watcher_user_ids => ['3', '8']}
    assert_response :success
    assert_template 'new'

    assert_select 'input[name=?][value=2]:not(checked)', 'issue[watcher_user_ids][]'
    assert_select 'input[name=?][value=3][checked=checked]', 'issue[watcher_user_ids][]'
    assert_select 'input[name=?][value=8][checked=checked]', 'issue[watcher_user_ids][]'
  end

  def test_post_create_should_ignore_non_safe_attributes
    @request.session[:user_id] = 2
    assert_nothing_raised do
      post :create, :project_id => 1, :issue => { :tracker => "A param can not be a Tracker" }
    end
  end

  def test_post_create_with_attachment
    set_tmp_attachments_directory
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      assert_difference 'Attachment.count' do
        post :create, :project_id => 1,
          :issue => { :tracker_id => '1', :subject => 'With attachment' },
          :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
      end
    end

    issue = Issue.order('id DESC').first
    attachment = Attachment.order('id DESC').first

    assert_equal issue, attachment.container
    assert_equal 2, attachment.author_id
    assert_equal 'testfile.txt', attachment.filename
    assert_equal 'text/plain', attachment.content_type
    assert_equal 'test file', attachment.description
    assert_equal 59, attachment.filesize
    assert File.exists?(attachment.diskfile)
    assert_equal 59, File.size(attachment.diskfile)
  end

  def test_post_create_with_attachment_should_notify_with_attachments
    ActionMailer::Base.deliveries.clear
    set_tmp_attachments_directory
    @request.session[:user_id] = 2

    with_settings :host_name => 'mydomain.foo', :protocol => 'http' do
      assert_difference 'Issue.count' do
        post :create, :project_id => 1,
          :issue => { :tracker_id => '1', :subject => 'With attachment' },
          :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
      end
    end

    assert_not_nil ActionMailer::Base.deliveries.last
    assert_select_email do
      assert_select 'a[href^=?]', 'http://mydomain.foo/attachments/download', 'testfile.txt'
    end
  end

  def test_post_create_with_failure_should_save_attachments
    set_tmp_attachments_directory
    @request.session[:user_id] = 2

    assert_no_difference 'Issue.count' do
      assert_difference 'Attachment.count' do
        post :create, :project_id => 1,
          :issue => { :tracker_id => '1', :subject => '' },
          :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
        assert_response :success
        assert_template 'new'
      end
    end

    attachment = Attachment.order('id DESC').first
    assert_equal 'testfile.txt', attachment.filename
    assert File.exists?(attachment.diskfile)
    assert_nil attachment.container

    assert_select 'input[name=?][value=?]', 'attachments[p0][token]', attachment.token
    assert_select 'input[name=?][value=?]', 'attachments[p0][filename]', 'testfile.txt'
  end

  def test_post_create_with_failure_should_keep_saved_attachments
    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => uploaded_test_file("testfile.txt", "text/plain"), :author_id => 2)
    @request.session[:user_id] = 2

    assert_no_difference 'Issue.count' do
      assert_no_difference 'Attachment.count' do
        post :create, :project_id => 1,
          :issue => { :tracker_id => '1', :subject => '' },
          :attachments => {'p0' => {'token' => attachment.token}}
        assert_response :success
        assert_template 'new'
      end
    end

    assert_select 'input[name=?][value=?]', 'attachments[p0][token]', attachment.token
    assert_select 'input[name=?][value=?]', 'attachments[p0][filename]', 'testfile.txt'
  end

  def test_post_create_should_attach_saved_attachments
    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => uploaded_test_file("testfile.txt", "text/plain"), :author_id => 2)
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      assert_no_difference 'Attachment.count' do
        post :create, :project_id => 1,
          :issue => { :tracker_id => '1', :subject => 'Saved attachments' },
          :attachments => {'p0' => {'token' => attachment.token}}
        assert_response 302
      end
    end

    issue = Issue.order('id DESC').first
    assert_equal 1, issue.attachments.count

    attachment.reload
    assert_equal issue, attachment.container
  end

  def setup_without_workflow_privilege
    WorkflowTransition.delete_all(["role_id = ?", Role.anonymous.id])
    Role.anonymous.add_permission! :add_issues, :add_issue_notes
  end
  private :setup_without_workflow_privilege

  test "without workflow privilege #new should propose default status only" do
    setup_without_workflow_privilege
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'
    assert_select 'select[name=?]', 'issue[status_id]' do
      assert_select 'option', 1
      assert_select 'option[value=?]', IssueStatus.default.id.to_s
    end
  end

  test "without workflow privilege #new should accept default status" do
    setup_without_workflow_privilege
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                    :issue => {:tracker_id => 1,
                                :subject => 'This is an issue',
                                :status_id => 1}
    end
    issue = Issue.order('id').last
    assert_equal IssueStatus.default, issue.status
  end

  test "without workflow privilege #new should ignore unauthorized status" do
    setup_without_workflow_privilege
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                     :issue => {:tracker_id => 1,
                                :subject => 'This is an issue',
                                :status_id => 3}
    end
    issue = Issue.order('id').last
    assert_equal IssueStatus.default, issue.status
  end

  test "without workflow privilege #update should ignore status change" do
    setup_without_workflow_privilege
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:status_id => 3, :notes => 'just trying'}
    end
    assert_equal 1, Issue.find(1).status_id
  end

  test "without workflow privilege #update ignore attributes changes" do
    setup_without_workflow_privilege
    assert_difference 'Journal.count' do
      put :update, :id => 1,
                   :issue => {:subject => 'changed', :assigned_to_id => 2,
                              :notes => 'just trying'}
    end
    issue = Issue.find(1)
    assert_equal "Can't print recipes", issue.subject
    assert_nil issue.assigned_to
  end

  def setup_with_workflow_privilege
    WorkflowTransition.delete_all(["role_id = ?", Role.anonymous.id])
    WorkflowTransition.create!(:role => Role.anonymous, :tracker_id => 1,
                               :old_status_id => 1, :new_status_id => 3)
    WorkflowTransition.create!(:role => Role.anonymous, :tracker_id => 1,
                               :old_status_id => 1, :new_status_id => 4)
    Role.anonymous.add_permission! :add_issues, :add_issue_notes
  end
  private :setup_with_workflow_privilege

  test "with workflow privilege #update should accept authorized status" do
    setup_with_workflow_privilege
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:status_id => 3, :notes => 'just trying'}
    end
    assert_equal 3, Issue.find(1).status_id
  end

  test "with workflow privilege #update should ignore unauthorized status" do
    setup_with_workflow_privilege
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:status_id => 2, :notes => 'just trying'}
    end
    assert_equal 1, Issue.find(1).status_id
  end

  test "with workflow privilege #update should accept authorized attributes changes" do
    setup_with_workflow_privilege
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:assigned_to_id => 2, :notes => 'just trying'}
    end
    issue = Issue.find(1)
    assert_equal 2, issue.assigned_to_id
  end

  test "with workflow privilege #update should ignore unauthorized attributes changes" do
    setup_with_workflow_privilege
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:subject => 'changed', :notes => 'just trying'}
    end
    issue = Issue.find(1)
    assert_equal "Can't print recipes", issue.subject
  end

  def setup_with_workflow_privilege_and_edit_issues_permission
    setup_with_workflow_privilege
    Role.anonymous.add_permission! :add_issues, :edit_issues
  end
  private :setup_with_workflow_privilege_and_edit_issues_permission

  test "with workflow privilege and :edit_issues permission should accept authorized status" do
    setup_with_workflow_privilege_and_edit_issues_permission
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:status_id => 3, :notes => 'just trying'}
    end
    assert_equal 3, Issue.find(1).status_id
  end

  test "with workflow privilege and :edit_issues permission should ignore unauthorized status" do
    setup_with_workflow_privilege_and_edit_issues_permission
    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:status_id => 2, :notes => 'just trying'}
    end
    assert_equal 1, Issue.find(1).status_id
  end

  test "with workflow privilege and :edit_issues permission should accept authorized attributes changes" do
    setup_with_workflow_privilege_and_edit_issues_permission
    assert_difference 'Journal.count' do
      put :update, :id => 1,
                   :issue => {:subject => 'changed', :assigned_to_id => 2,
                              :notes => 'just trying'}
    end
    issue = Issue.find(1)
    assert_equal "changed", issue.subject
    assert_equal 2, issue.assigned_to_id
  end

  def test_new_as_copy
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :copy_from => 1

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:issue)
    orig = Issue.find(1)
    assert_equal 1, assigns(:issue).project_id
    assert_equal orig.subject, assigns(:issue).subject
    assert assigns(:issue).copy?

    assert_select 'form[id=issue-form][action=/projects/ecookbook/issues]' do
      assert_select 'select[name=?]', 'issue[project_id]' do
        assert_select 'option[value=1][selected=selected]', :text => 'eCookbook'
        assert_select 'option[value=2]:not([selected])', :text => 'OnlineStore'
      end
      assert_select 'input[name=copy_from][value=1]'
    end

    # "New issue" menu item should not link to copy
    assert_select '#main-menu a.new-issue[href=/projects/ecookbook/issues/new]'
  end

  def test_new_as_copy_with_attachments_should_show_copy_attachments_checkbox
    @request.session[:user_id] = 2
    issue = Issue.find(3)
    assert issue.attachments.count > 0
    get :new, :project_id => 1, :copy_from => 3

    assert_select 'input[name=copy_attachments][type=checkbox][checked=checked][value=1]'
  end

  def test_new_as_copy_without_attachments_should_not_show_copy_attachments_checkbox
    @request.session[:user_id] = 2
    issue = Issue.find(3)
    issue.attachments.delete_all
    get :new, :project_id => 1, :copy_from => 3

    assert_select 'input[name=copy_attachments]', 0
  end

  def test_new_as_copy_with_subtasks_should_show_copy_subtasks_checkbox
    @request.session[:user_id] = 2
    issue = Issue.generate_with_descendants!
    get :new, :project_id => 1, :copy_from => issue.id

    assert_select 'input[type=checkbox][name=copy_subtasks][checked=checked][value=1]'
  end

  def test_new_as_copy_with_invalid_issue_should_respond_with_404
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :copy_from => 99999
    assert_response 404
  end

  def test_create_as_copy_on_different_project
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1, :copy_from => 1,
        :issue => {:project_id => '2', :tracker_id => '3', :status_id => '1', :subject => 'Copy'}

      assert_not_nil assigns(:issue)
      assert assigns(:issue).copy?
    end
    issue = Issue.order('id DESC').first
    assert_redirected_to "/issues/#{issue.id}"

    assert_equal 2, issue.project_id
    assert_equal 3, issue.tracker_id
    assert_equal 'Copy', issue.subject
  end

  def test_create_as_copy_should_copy_attachments
    @request.session[:user_id] = 2
    issue = Issue.find(3)
    count = issue.attachments.count
    assert count > 0
    assert_difference 'Issue.count' do
      assert_difference 'Attachment.count', count do
        assert_difference 'Journal.count', 2 do
          post :create, :project_id => 1, :copy_from => 3,
            :issue => {:project_id => '1', :tracker_id => '3',
                       :status_id => '1', :subject => 'Copy with attachments'},
            :copy_attachments => '1'
        end
      end
    end
    copy = Issue.order('id DESC').first
    assert_equal count, copy.attachments.count
    assert_equal issue.attachments.map(&:filename).sort, copy.attachments.map(&:filename).sort
  end

  def test_create_as_copy_without_copy_attachments_option_should_not_copy_attachments
    @request.session[:user_id] = 2
    issue = Issue.find(3)
    count = issue.attachments.count
    assert count > 0
    assert_difference 'Issue.count' do
      assert_no_difference 'Attachment.count' do
        assert_difference 'Journal.count', 2 do
          post :create, :project_id => 1, :copy_from => 3,
            :issue => {:project_id => '1', :tracker_id => '3',
                       :status_id => '1', :subject => 'Copy with attachments'}
        end
      end
    end
    copy = Issue.order('id DESC').first
    assert_equal 0, copy.attachments.count
  end

  def test_create_as_copy_with_attachments_should_add_new_files
    @request.session[:user_id] = 2
    issue = Issue.find(3)
    count = issue.attachments.count
    assert count > 0
    assert_difference 'Issue.count' do
      assert_difference 'Attachment.count', count + 1 do
        assert_difference 'Journal.count', 2 do
          post :create, :project_id => 1, :copy_from => 3,
            :issue => {:project_id => '1', :tracker_id => '3',
                       :status_id => '1', :subject => 'Copy with attachments'},
            :copy_attachments => '1',
            :attachments => {'1' =>
                   {'file' => uploaded_test_file('testfile.txt', 'text/plain'),
                    'description' => 'test file'}}
        end
      end
    end
    copy = Issue.order('id DESC').first
    assert_equal count + 1, copy.attachments.count
  end

  def test_create_as_copy_should_add_relation_with_copied_issue
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      assert_difference 'IssueRelation.count' do
        post :create, :project_id => 1, :copy_from => 1,
          :issue => {:project_id => '1', :tracker_id => '3',
                     :status_id => '1', :subject => 'Copy'}
      end
    end
    copy = Issue.order('id DESC').first
    assert_equal 1, copy.relations.size
  end

  def test_create_as_copy_should_copy_subtasks
    @request.session[:user_id] = 2
    issue = Issue.generate_with_descendants!
    count = issue.descendants.count
    assert_difference 'Issue.count', count + 1 do
      assert_difference 'Journal.count', (count + 1) * 2 do
        post :create, :project_id => 1, :copy_from => issue.id,
          :issue => {:project_id => '1', :tracker_id => '3',
                     :status_id => '1', :subject => 'Copy with subtasks'},
          :copy_subtasks => '1'
      end
    end
    copy = Issue.where(:parent_id => nil).order('id DESC').first
    assert_equal count, copy.descendants.count
    assert_equal issue.descendants.map(&:subject).sort, copy.descendants.map(&:subject).sort
  end

  def test_create_as_copy_without_copy_subtasks_option_should_not_copy_subtasks
    @request.session[:user_id] = 2
    issue = Issue.generate_with_descendants!
    assert_difference 'Issue.count', 1 do
      assert_difference 'Journal.count', 2 do
        post :create, :project_id => 1, :copy_from => 3,
          :issue => {:project_id => '1', :tracker_id => '3',
                     :status_id => '1', :subject => 'Copy with subtasks'}
      end
    end
    copy = Issue.where(:parent_id => nil).order('id DESC').first
    assert_equal 0, copy.descendants.count
  end

  def test_create_as_copy_with_failure
    @request.session[:user_id] = 2
    post :create, :project_id => 1, :copy_from => 1,
      :issue => {:project_id => '2', :tracker_id => '3', :status_id => '1', :subject => ''}

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:issue)
    assert assigns(:issue).copy?

    assert_select 'form#issue-form[action=/projects/ecookbook/issues]' do
      assert_select 'select[name=?]', 'issue[project_id]' do
        assert_select 'option[value=1]:not([selected])', :text => 'eCookbook'
        assert_select 'option[value=2][selected=selected]', :text => 'OnlineStore'
      end
      assert_select 'input[name=copy_from][value=1]'
    end
  end

  def test_create_as_copy_on_project_without_permission_should_ignore_target_project
    @request.session[:user_id] = 2
    assert !User.find(2).member_of?(Project.find(4))

    assert_difference 'Issue.count' do
      post :create, :project_id => 1, :copy_from => 1,
        :issue => {:project_id => '4', :tracker_id => '3', :status_id => '1', :subject => 'Copy'}
    end
    issue = Issue.order('id DESC').first
    assert_equal 1, issue.project_id
  end

  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)

    # Be sure we don't display inactive IssuePriorities
    assert ! IssuePriority.find(15).active?
    assert_select 'select[name=?]', 'issue[priority_id]' do
      assert_select 'option[value=15]', 0
    end
  end

  def test_get_edit_should_display_the_time_entry_form_with_log_time_permission
    @request.session[:user_id] = 2
    Role.find_by_name('Manager').update_attribute :permissions, [:view_issues, :edit_issues, :log_time]
    
    get :edit, :id => 1
    assert_select 'input[name=?]', 'time_entry[hours]'
  end

  def test_get_edit_should_not_display_the_time_entry_form_without_log_time_permission
    @request.session[:user_id] = 2
    Role.find_by_name('Manager').remove_permission! :log_time
    
    get :edit, :id => 1
    assert_select 'input[name=?]', 'time_entry[hours]', 0
  end

  def test_get_edit_with_params
    @request.session[:user_id] = 2
    get :edit, :id => 1, :issue => { :status_id => 5, :priority_id => 7 },
        :time_entry => { :hours => '2.5', :comments => 'test_get_edit_with_params', :activity_id => 10 }
    assert_response :success
    assert_template 'edit'

    issue = assigns(:issue)
    assert_not_nil issue

    assert_equal 5, issue.status_id
    assert_select 'select[name=?]', 'issue[status_id]' do
      assert_select 'option[value=5][selected=selected]', :text => 'Closed'
    end

    assert_equal 7, issue.priority_id
    assert_select 'select[name=?]', 'issue[priority_id]' do
      assert_select 'option[value=7][selected=selected]', :text => 'Urgent'
    end

    assert_select 'input[name=?][value=2.5]', 'time_entry[hours]'
    assert_select 'select[name=?]', 'time_entry[activity_id]' do
      assert_select 'option[value=10][selected=selected]', :text => 'Development'
    end
    assert_select 'input[name=?][value=test_get_edit_with_params]', 'time_entry[comments]'
  end

  def test_get_edit_with_multi_custom_field
    field = CustomField.find(1)
    field.update_attribute :multiple, true
    issue = Issue.find(1)
    issue.custom_field_values = {1 => ['MySQL', 'Oracle']}
    issue.save!

    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'

    assert_select 'select[name=?][multiple=multiple]', 'issue[custom_field_values][1][]' do
      assert_select 'option', 3
      assert_select 'option[value=MySQL][selected=selected]'
      assert_select 'option[value=Oracle][selected=selected]'
      assert_select 'option[value=PostgreSQL]:not([selected])'
    end
  end

  def test_update_form_for_existing_issue
    @request.session[:user_id] = 2
    xhr :put, :update_form, :project_id => 1,
                             :id => 1,
                             :issue => {:tracker_id => 2,
                                        :subject => 'This is the test_new issue',
                                        :description => 'This is the description',
                                        :priority_id => 5}
    assert_response :success
    assert_equal 'text/javascript', response.content_type
    assert_template 'update_form'
    assert_template :partial => '_form'

    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.id
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 'This is the test_new issue', issue.subject
  end

  def test_update_form_for_existing_issue_should_keep_issue_author
    @request.session[:user_id] = 3
    xhr :put, :update_form, :project_id => 1, :id => 1, :issue => {:subject => 'Changed'}
    assert_response :success
    assert_equal 'text/javascript', response.content_type

    issue = assigns(:issue)
    assert_equal User.find(2), issue.author
    assert_equal 2, issue.author_id
    assert_not_equal User.current, issue.author
  end

  def test_update_form_for_existing_issue_should_propose_transitions_based_on_initial_status
    @request.session[:user_id] = 2
    WorkflowTransition.delete_all
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 2, :new_status_id => 1)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 2, :new_status_id => 5)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 5, :new_status_id => 4)

    xhr :put, :update_form, :project_id => 1,
                    :id => 2,
                    :issue => {:tracker_id => 2,
                               :status_id => 5,
                               :subject => 'This is an issue'}

    assert_equal 5, assigns(:issue).status_id
    assert_equal [1,2,5], assigns(:allowed_statuses).map(&:id).sort
  end

  def test_update_form_for_existing_issue_with_project_change
    @request.session[:user_id] = 2
    xhr :put, :update_form, :project_id => 1,
                             :id => 1,
                             :issue => {:project_id => 2,
                                        :tracker_id => 2,
                                        :subject => 'This is the test_new issue',
                                        :description => 'This is the description',
                                        :priority_id => 5}
    assert_response :success
    assert_template :partial => '_form'

    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.id
    assert_equal 2, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 'This is the test_new issue', issue.subject
  end

  def test_update_form_should_propose_default_status_for_existing_issue
    @request.session[:user_id] = 2
    WorkflowTransition.delete_all
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 2, :new_status_id => 3)

    xhr :put, :update_form, :project_id => 1, :id => 2
    assert_response :success
    assert_equal [2,3], assigns(:allowed_statuses).map(&:id).sort
  end

  def test_put_update_without_custom_fields_param
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 2) do
        put :update, :id => 1, :issue => {:subject => new_subject,
                                         :priority_id => '6',
                                         :category_id => '1' # no change
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal new_subject, issue.subject
    # Make sure custom fields were not cleared
    assert_equal '125', issue.custom_value_for(2).value

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert_mail_body_match "Subject changed from #{old_subject} to #{new_subject}", mail
  end

  def test_put_update_with_project_change
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        put :update, :id => 1, :issue => {:project_id => '2',
                                         :tracker_id => '1', # no change
                                         :priority_id => '6',
                                         :category_id => '3'
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue = Issue.find(1)
    assert_equal 2, issue.project_id
    assert_equal 1, issue.tracker_id
    assert_equal 6, issue.priority_id
    assert_equal 3, issue.category_id

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert_mail_body_match "Project changed from eCookbook to OnlineStore", mail
  end

  def test_put_update_with_tracker_change
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 2) do
        put :update, :id => 1, :issue => {:project_id => '1',
                                         :tracker_id => '2',
                                         :priority_id => '6'
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue = Issue.find(1)
    assert_equal 1, issue.project_id
    assert_equal 2, issue.tracker_id
    assert_equal 6, issue.priority_id
    assert_equal 1, issue.category_id

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}]")
    assert_mail_body_match "Tracker changed from Bug to Feature request", mail
  end

  def test_put_update_with_custom_field_change
    @request.session[:user_id] = 2
    issue = Issue.find(1)
    assert_equal '125', issue.custom_value_for(2).value

    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        put :update, :id => 1, :issue => {:subject => 'Custom field change',
                                         :priority_id => '6',
                                         :category_id => '1', # no change
                                         :custom_field_values => { '2' => 'New custom value' }
                                        }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 'New custom value', issue.custom_value_for(2).value

    mail = ActionMailer::Base.deliveries.last
    assert_not_nil mail
    assert_mail_body_match "Searchable field changed from 125 to New custom value", mail
  end

  def test_put_update_with_multi_custom_field_change
    field = CustomField.find(1)
    field.update_attribute :multiple, true
    issue = Issue.find(1)
    issue.custom_field_values = {1 => ['MySQL', 'Oracle']}
    issue.save!

    @request.session[:user_id] = 2
    assert_difference('Journal.count') do
      assert_difference('JournalDetail.count', 3) do
        put :update, :id => 1,
          :issue => {
            :subject => 'Custom field change',
            :custom_field_values => { '1' => ['', 'Oracle', 'PostgreSQL'] }
          }
      end
    end
    assert_redirected_to :action => 'show', :id => '1'
    assert_equal ['Oracle', 'PostgreSQL'], Issue.find(1).custom_field_value(1).sort
  end

  def test_put_update_with_status_and_assignee_change
    issue = Issue.find(1)
    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    assert_difference('TimeEntry.count', 0) do
      put :update,
           :id => 1,
           :issue => { :status_id => 2, :assigned_to_id => 3, :notes => 'Assigned to dlopper' },
           :time_entry => { :hours => '', :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to :action => 'show', :id => '1'
    issue.reload
    assert_equal 2, issue.status_id
    j = Journal.order('id DESC').first
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match "Status changed from New to Assigned", mail
    # subject should contain the new status
    assert mail.subject.include?("(#{ IssueStatus.find(2).name })")
  end

  def test_put_update_with_note_only
    notes = 'Note added by IssuesControllerTest#test_update_with_note_only'
    # anonymous user
    put :update,
         :id => 1,
         :issue => { :notes => notes }
    assert_redirected_to :action => 'show', :id => '1'
    j = Journal.order('id DESC').first
    assert_equal notes, j.notes
    assert_equal 0, j.details.size
    assert_equal User.anonymous, j.user

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match notes, mail
  end

  def test_put_update_with_private_note_only
    notes = 'Private note'
    @request.session[:user_id] = 2

    assert_difference 'Journal.count' do
      put :update, :id => 1, :issue => {:notes => notes, :private_notes => '1'}
      assert_redirected_to :action => 'show', :id => '1'
    end

    j = Journal.order('id DESC').first
    assert_equal notes, j.notes
    assert_equal true, j.private_notes
  end

  def test_put_update_with_private_note_and_changes
    notes = 'Private note'
    @request.session[:user_id] = 2

    assert_difference 'Journal.count', 2 do
      put :update, :id => 1, :issue => {:subject => 'New subject', :notes => notes, :private_notes => '1'}
      assert_redirected_to :action => 'show', :id => '1'
    end

    j = Journal.order('id DESC').first
    assert_equal notes, j.notes
    assert_equal true, j.private_notes
    assert_equal 0, j.details.count

    j = Journal.order('id DESC').offset(1).first
    assert_nil j.notes
    assert_equal false, j.private_notes
    assert_equal 1, j.details.count
  end

  def test_put_update_with_note_and_spent_time
    @request.session[:user_id] = 2
    spent_hours_before = Issue.find(1).spent_hours
    assert_difference('TimeEntry.count') do
      put :update,
           :id => 1,
           :issue => { :notes => '2.5 hours added' },
           :time_entry => { :hours => '2.5', :comments => 'test_put_update_with_note_and_spent_time', :activity_id => TimeEntryActivity.first.id }
    end
    assert_redirected_to :action => 'show', :id => '1'

    issue = Issue.find(1)

    j = Journal.order('id DESC').first
    assert_equal '2.5 hours added', j.notes
    assert_equal 0, j.details.size

    t = issue.time_entries.find_by_comments('test_put_update_with_note_and_spent_time')
    assert_not_nil t
    assert_equal 2.5, t.hours
    assert_equal spent_hours_before + 2.5, issue.spent_hours
  end

  def test_put_update_should_preserve_parent_issue_even_if_not_visible
    parent = Issue.generate!(:project_id => 1, :is_private => true)
    issue = Issue.generate!(:parent_issue_id => parent.id)
    assert !parent.visible?(User.find(3))
    @request.session[:user_id] = 3

    get :edit, :id => issue.id
    assert_select 'input[name=?][value=?]', 'issue[parent_issue_id]', parent.id.to_s

    put :update, :id => issue.id, :issue => {:subject => 'New subject', :parent_issue_id => parent.id.to_s}
    assert_response 302
    assert_equal parent, issue.parent
  end

  def test_put_update_with_attachment_only
    set_tmp_attachments_directory

    # Delete all fixtured journals, a race condition can occur causing the wrong
    # journal to get fetched in the next find.
    Journal.delete_all

    # anonymous user
    assert_difference 'Attachment.count' do
      put :update, :id => 1,
        :issue => {:notes => ''},
        :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
    end

    assert_redirected_to :action => 'show', :id => '1'
    j = Issue.find(1).journals.reorder('id DESC').first
    assert j.notes.blank?
    assert_equal 1, j.details.size
    assert_equal 'testfile.txt', j.details.first.value
    assert_equal User.anonymous, j.user

    attachment = Attachment.order('id DESC').first
    assert_equal Issue.find(1), attachment.container
    assert_equal User.anonymous, attachment.author
    assert_equal 'testfile.txt', attachment.filename
    assert_equal 'text/plain', attachment.content_type
    assert_equal 'test file', attachment.description
    assert_equal 59, attachment.filesize
    assert File.exists?(attachment.diskfile)
    assert_equal 59, File.size(attachment.diskfile)

    mail = ActionMailer::Base.deliveries.last
    assert_mail_body_match 'testfile.txt', mail
  end

  def test_put_update_with_failure_should_save_attachments
    set_tmp_attachments_directory
    @request.session[:user_id] = 2

    assert_no_difference 'Journal.count' do
      assert_difference 'Attachment.count' do
        put :update, :id => 1,
          :issue => { :subject => '' },
          :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain'), 'description' => 'test file'}}
        assert_response :success
        assert_template 'edit'
      end
    end

    attachment = Attachment.order('id DESC').first
    assert_equal 'testfile.txt', attachment.filename
    assert File.exists?(attachment.diskfile)
    assert_nil attachment.container

    assert_select 'input[name=?][value=?]', 'attachments[p0][token]', attachment.token
    assert_select 'input[name=?][value=?]', 'attachments[p0][filename]', 'testfile.txt'
  end

  def test_put_update_with_failure_should_keep_saved_attachments
    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => uploaded_test_file("testfile.txt", "text/plain"), :author_id => 2)
    @request.session[:user_id] = 2

    assert_no_difference 'Journal.count' do
      assert_no_difference 'Attachment.count' do
        put :update, :id => 1,
          :issue => { :subject => '' },
          :attachments => {'p0' => {'token' => attachment.token}}
        assert_response :success
        assert_template 'edit'
      end
    end

    assert_select 'input[name=?][value=?]', 'attachments[p0][token]', attachment.token
    assert_select 'input[name=?][value=?]', 'attachments[p0][filename]', 'testfile.txt'
  end

  def test_put_update_should_attach_saved_attachments
    set_tmp_attachments_directory
    attachment = Attachment.create!(:file => uploaded_test_file("testfile.txt", "text/plain"), :author_id => 2)
    @request.session[:user_id] = 2

    assert_difference 'Journal.count' do
      assert_difference 'JournalDetail.count' do
        assert_no_difference 'Attachment.count' do
          put :update, :id => 1,
            :issue => {:notes => 'Attachment added'},
            :attachments => {'p0' => {'token' => attachment.token}}
          assert_redirected_to '/issues/1'
        end
      end
    end

    attachment.reload
    assert_equal Issue.find(1), attachment.container

    journal = Journal.order('id DESC').first
    assert_equal 1, journal.details.size
    assert_equal 'testfile.txt', journal.details.first.value
  end

  def test_put_update_with_attachment_that_fails_to_save
    set_tmp_attachments_directory

    # Delete all fixtured journals, a race condition can occur causing the wrong
    # journal to get fetched in the next find.
    Journal.delete_all

    # Mock out the unsaved attachment
    Attachment.any_instance.stubs(:create).returns(Attachment.new)

    # anonymous user
    put :update,
         :id => 1,
         :issue => {:notes => ''},
         :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    assert_redirected_to :action => 'show', :id => '1'
    assert_equal '1 file(s) could not be saved.', flash[:warning]
  end

  def test_put_update_with_no_change
    issue = Issue.find(1)
    issue.journals.clear
    ActionMailer::Base.deliveries.clear

    put :update,
         :id => 1,
         :issue => {:notes => ''}
    assert_redirected_to :action => 'show', :id => '1'

    issue.reload
    assert issue.journals.empty?
    # No email should be sent
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_put_update_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'

    put :update, :id => 1, :issue => {:subject => new_subject,
                                     :priority_id => '6',
                                     :category_id => '1' # no change
                                    }
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def test_put_update_with_invalid_spent_time_hours_only
    @request.session[:user_id] = 2
    notes = 'Note added by IssuesControllerTest#test_post_edit_with_invalid_spent_time'

    assert_no_difference('Journal.count') do
      put :update,
           :id => 1,
           :issue => {:notes => notes},
           :time_entry => {"comments"=>"", "activity_id"=>"", "hours"=>"2z"}
    end
    assert_response :success
    assert_template 'edit'

    assert_error_tag :descendant => {:content => /Activity #{ESCAPED_CANT} be blank/}
    assert_select 'textarea[name=?]', 'issue[notes]', :text => notes
    assert_select 'input[name=?][value=?]', 'time_entry[hours]', '2z'
  end

  def test_put_update_with_invalid_spent_time_comments_only
    @request.session[:user_id] = 2
    notes = 'Note added by IssuesControllerTest#test_post_edit_with_invalid_spent_time'

    assert_no_difference('Journal.count') do
      put :update,
           :id => 1,
           :issue => {:notes => notes},
           :time_entry => {"comments"=>"this is my comment", "activity_id"=>"", "hours"=>""}
    end
    assert_response :success
    assert_template 'edit'

    assert_error_tag :descendant => {:content => /Activity #{ESCAPED_CANT} be blank/}
    assert_error_tag :descendant => {:content => /Hours #{ESCAPED_CANT} be blank/}
    assert_select 'textarea[name=?]', 'issue[notes]', :text => notes
    assert_select 'input[name=?][value=?]', 'time_entry[comments]', 'this is my comment'
  end

  def test_put_update_should_allow_fixed_version_to_be_set_to_a_subproject
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         }

    assert_response :redirect
    issue.reload
    assert_equal 4, issue.fixed_version_id
    assert_not_equal issue.project_id, issue.fixed_version.project_id
  end

  def test_put_update_should_redirect_back_using_the_back_url_parameter
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end

  def test_put_update_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue.id
  end

  def test_get_bulk_edit
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'

    assert_select 'ul#bulk-selection' do
      assert_select 'li', 2
      assert_select 'li a', :text => 'Bug #1'
    end

    assert_select 'form#bulk_edit_form[action=?]', '/issues/bulk_update' do
      assert_select 'input[name=?]', 'ids[]', 2
      assert_select 'input[name=?][value=1][type=hidden]', 'ids[]'

      assert_select 'select[name=?]', 'issue[project_id]'
      assert_select 'input[name=?]', 'issue[parent_issue_id]'
  
      # Project specific custom field, date type
      field = CustomField.find(9)
      assert !field.is_for_all?
      assert_equal 'date', field.field_format
      assert_select 'input[name=?]', 'issue[custom_field_values][9]'
  
      # System wide custom field
      assert CustomField.find(1).is_for_all?
      assert_select 'select[name=?]', 'issue[custom_field_values][1]'
  
      # Be sure we don't display inactive IssuePriorities
      assert ! IssuePriority.find(15).active?
      assert_select 'select[name=?]', 'issue[priority_id]' do
        assert_select 'option[value=15]', 0
      end
    end
  end

  def test_get_bulk_edit_on_different_projects
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2, 6]
    assert_response :success
    assert_template 'bulk_edit'

    # Can not set issues from different projects as children of an issue
    assert_select 'input[name=?]', 'issue[parent_issue_id]', 0

    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert !field.project_ids.include?(Issue.find(6).project_id)
    assert_select 'input[name=?]', 'issue[custom_field_values][9]', 0
  end

  def test_get_bulk_edit_with_user_custom_field
    field = IssueCustomField.create!(:name => 'Tester', :field_format => 'user', :is_for_all => true)

    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'

    assert_select 'select.user_cf[name=?]', "issue[custom_field_values][#{field.id}]" do
      assert_select 'option', Project.find(1).users.count + 2 # "no change" + "none" options
    end
  end

  def test_get_bulk_edit_with_version_custom_field
    field = IssueCustomField.create!(:name => 'Affected version', :field_format => 'version', :is_for_all => true)

    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'

    assert_select 'select.version_cf[name=?]', "issue[custom_field_values][#{field.id}]" do
      assert_select 'option', Project.find(1).shared_versions.count + 2 # "no change" + "none" options
    end
  end

  def test_get_bulk_edit_with_multi_custom_field
    field = CustomField.find(1)
    field.update_attribute :multiple, true

    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'

    assert_select 'select[name=?]', 'issue[custom_field_values][1][]' do
      assert_select 'option', field.possible_values.size + 1 # "none" options
    end
  end

  def test_bulk_edit_should_propose_to_clear_text_custom_fields
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 3]
    assert_select 'input[name=?][value=?]', 'issue[custom_field_values][2]', '__none__'
  end

  def test_bulk_edit_should_only_propose_statuses_allowed_for_all_issues
    WorkflowTransition.delete_all
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1,
                               :old_status_id => 1, :new_status_id => 1)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1,
                               :old_status_id => 1, :new_status_id => 3)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1,
                               :old_status_id => 1, :new_status_id => 4)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2,
                               :old_status_id => 2, :new_status_id => 1)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2,
                               :old_status_id => 2, :new_status_id => 3)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2,
                               :old_status_id => 2, :new_status_id => 5)
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]

    assert_response :success
    statuses = assigns(:available_statuses)
    assert_not_nil statuses
    assert_equal [1, 3], statuses.map(&:id).sort

    assert_select 'select[name=?]', 'issue[status_id]' do
      assert_select 'option', 3 # 2 statuses + "no change" option
    end
  end

  def test_bulk_edit_should_propose_target_project_open_shared_versions
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1, 2, 6], :issue => {:project_id => 1}
    assert_response :success
    assert_template 'bulk_edit'
    assert_equal Project.find(1).shared_versions.open.all.sort, assigns(:versions).sort

    assert_select 'select[name=?]', 'issue[fixed_version_id]' do
      assert_select 'option', :text => '2.0'
    end
  end

  def test_bulk_edit_should_propose_target_project_categories
    @request.session[:user_id] = 2
    post :bulk_edit, :ids => [1, 2, 6], :issue => {:project_id => 1}
    assert_response :success
    assert_template 'bulk_edit'
    assert_equal Project.find(1).issue_categories.sort, assigns(:categories).sort

    assert_select 'select[name=?]', 'issue[category_id]' do
      assert_select 'option', :text => 'Recipes'
    end
  end

  def test_bulk_update
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_update, :ids => [1, 2], :notes => 'Bulk editing',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}

    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], Issue.where(:id =>[1, 2]).collect {|i| i.priority.id}

    issue = Issue.find(1)
    journal = issue.journals.reorder('created_on DESC').first
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bulk_update_with_group_assignee
    group = Group.find(11)
    project = Project.find(1)
    project.members << Member.new(:principal => group, :roles => [Role.givable.first])

    @request.session[:user_id] = 2
    # update issues assignee
    post :bulk_update, :ids => [1, 2], :notes => 'Bulk editing',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => group.id,
                                                :custom_field_values => {'2' => ''}}

    assert_response 302
    assert_equal [group, group], Issue.where(:id => [1, 2]).collect {|i| i.assigned_to}
  end

  def test_bulk_update_on_different_projects
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_update, :ids => [1, 2, 6], :notes => 'Bulk editing',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}

    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7, 7], Issue.find([1,2,6]).map(&:priority_id)

    issue = Issue.find(1)
    journal = issue.journals.reorder('created_on DESC').first
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bulk_update_on_different_projects_without_rights
    @request.session[:user_id] = 3
    user = User.find(3)
    action = { :controller => "issues", :action => "bulk_update" }
    assert user.allowed_to?(action, Issue.find(1).project)
    assert ! user.allowed_to?(action, Issue.find(6).project)
    post :bulk_update, :ids => [1, 6], :notes => 'Bulk should fail',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}
    assert_response 403
    assert_not_equal "Bulk should fail", Journal.last.notes
  end

  def test_bullk_update_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    post(:bulk_update,
         {
           :ids => [1, 2],
           :notes => 'Bulk editing',
           :issue => {
             :priority_id => 7,
             :assigned_to_id => '',
             :custom_field_values => {'2' => ''}
           }
         })

    assert_response 302
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_bulk_update_project
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :issue => {:project_id => '2'}
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook'
    # Issues moved to project 2
    assert_equal 2, Issue.find(1).project_id
    assert_equal 2, Issue.find(2).project_id
    # No tracker change
    assert_equal 1, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end

  def test_bulk_update_project_on_single_issue_should_follow_when_needed
    @request.session[:user_id] = 2
    post :bulk_update, :id => 1, :issue => {:project_id => '2'}, :follow => '1'
    assert_redirected_to '/issues/1'
  end

  def test_bulk_update_project_on_multiple_issues_should_follow_when_needed
    @request.session[:user_id] = 2
    post :bulk_update, :id => [1, 2], :issue => {:project_id => '2'}, :follow => '1'
    assert_redirected_to '/projects/onlinestore/issues'
  end

  def test_bulk_update_tracker
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :issue => {:tracker_id => '2'}
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook'
    assert_equal 2, Issue.find(1).tracker_id
    assert_equal 2, Issue.find(2).tracker_id
  end

  def test_bulk_update_status
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_update, :ids => [1, 2], :notes => 'Bulk editing status',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :status_id => '5'}

    assert_response 302
    issue = Issue.find(1)
    assert issue.closed?
  end

  def test_bulk_update_priority
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :issue => {:priority_id => 6}

    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook'
    assert_equal 6, Issue.find(1).priority_id
    assert_equal 6, Issue.find(2).priority_id
  end

  def test_bulk_update_with_notes
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :notes => 'Moving two issues'

    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => 'ecookbook'
    assert_equal 'Moving two issues', Issue.find(1).journals.sort_by(&:id).last.notes
    assert_equal 'Moving two issues', Issue.find(2).journals.sort_by(&:id).last.notes
  end

  def test_bulk_update_parent_id
    IssueRelation.delete_all
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 3],
      :notes => 'Bulk editing parent',
      :issue => {:priority_id => '', :assigned_to_id => '',
                 :status_id => '', :parent_issue_id => '2'}
    assert_response 302
    parent = Issue.find(2)
    assert_equal parent.id, Issue.find(1).parent_id
    assert_equal parent.id, Issue.find(3).parent_id
    assert_equal [1, 3], parent.children.collect(&:id).sort
  end

  def test_bulk_update_custom_field
    @request.session[:user_id] = 2
    # update issues priority
    post :bulk_update, :ids => [1, 2], :notes => 'Bulk editing custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => '777'}}

    assert_response 302

    issue = Issue.find(1)
    journal = issue.journals.reorder('created_on DESC').first
    assert_equal '777', issue.custom_value_for(2).value
    assert_equal 1, journal.details.size
    assert_equal '125', journal.details.first.old_value
    assert_equal '777', journal.details.first.value
  end

  def test_bulk_update_custom_field_to_blank
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 3], :notes => 'Bulk editing custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'1' => '__none__'}}
    assert_response 302
    assert_equal '', Issue.find(1).custom_field_value(1)
    assert_equal '', Issue.find(3).custom_field_value(1)
  end

  def test_bulk_update_multi_custom_field
    field = CustomField.find(1)
    field.update_attribute :multiple, true

    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2, 3], :notes => 'Bulk editing multi custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'1' => ['MySQL', 'Oracle']}}

    assert_response 302

    assert_equal ['MySQL', 'Oracle'], Issue.find(1).custom_field_value(1).sort
    assert_equal ['MySQL', 'Oracle'], Issue.find(3).custom_field_value(1).sort
    # the custom field is not associated with the issue tracker
    assert_nil Issue.find(2).custom_field_value(1)
  end

  def test_bulk_update_multi_custom_field_to_blank
    field = CustomField.find(1)
    field.update_attribute :multiple, true

    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 3], :notes => 'Bulk editing multi custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'1' => ['__none__']}}
    assert_response 302
    assert_equal [''], Issue.find(1).custom_field_value(1)
    assert_equal [''], Issue.find(3).custom_field_value(1)
  end

  def test_bulk_update_unassign
    assert_not_nil Issue.find(2).assigned_to
    @request.session[:user_id] = 2
    # unassign issues
    post :bulk_update, :ids => [1, 2], :notes => 'Bulk unassigning', :issue => {:assigned_to_id => 'none'}
    assert_response 302
    # check that the issues were updated
    assert_nil Issue.find(2).assigned_to
  end

  def test_post_bulk_update_should_allow_fixed_version_to_be_set_to_a_subproject
    @request.session[:user_id] = 2

    post :bulk_update, :ids => [1,2], :issue => {:fixed_version_id => 4}

    assert_response :redirect
    issues = Issue.find([1,2])
    issues.each do |issue|
      assert_equal 4, issue.fixed_version_id
      assert_not_equal issue.project_id, issue.fixed_version.project_id
    end
  end

  def test_post_bulk_update_should_redirect_back_using_the_back_url_parameter
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1,2], :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end

  def test_post_bulk_update_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1,2], :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => Project.find(1).identifier
  end

  def test_bulk_update_with_all_failures_should_show_errors
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :issue => {:start_date => 'foo'}

    assert_response :success
    assert_template 'bulk_edit'
    assert_select '#errorExplanation span', :text => 'Failed to save 2 issue(s) on 2 selected: #1, #2.'
    assert_select '#errorExplanation ul li', :text => 'Start date is not a valid date: #1, #2'

    assert_equal [1, 2], assigns[:issues].map(&:id)
  end

  def test_bulk_update_with_some_failures_should_show_errors
    issue1 = Issue.generate!(:start_date => '2013-05-12')
    issue2 = Issue.generate!(:start_date => '2013-05-15')
    issue3 = Issue.generate!
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [issue1.id, issue2.id, issue3.id],
                       :issue => {:due_date => '2013-05-01'}
    assert_response :success
    assert_template 'bulk_edit'
    assert_select '#errorExplanation span',
                  :text => "Failed to save 2 issue(s) on 3 selected: ##{issue1.id}, ##{issue2.id}."
    assert_select '#errorExplanation ul li',
                   :text => "Due date must be greater than start date: ##{issue1.id}, ##{issue2.id}"
    assert_equal [issue1.id, issue2.id], assigns[:issues].map(&:id)
  end

  def test_bulk_update_with_failure_should_preserved_form_values
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :issue => {:tracker_id => '2', :start_date => 'foo'}

    assert_response :success
    assert_template 'bulk_edit'
    assert_select 'select[name=?]', 'issue[tracker_id]' do
      assert_select 'option[value=2][selected=selected]'
    end
    assert_select 'input[name=?][value=?]', 'issue[start_date]', 'foo'
  end

  def test_get_bulk_copy
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2, 3], :copy => '1'
    assert_response :success
    assert_template 'bulk_edit'

    issues = assigns(:issues)
    assert_not_nil issues
    assert_equal [1, 2, 3], issues.map(&:id).sort

    assert_select 'input[name=copy_attachments]'
  end

  def test_bulk_copy_to_another_project
    @request.session[:user_id] = 2
    assert_difference 'Issue.count', 2 do
      assert_no_difference 'Project.find(1).issues.count' do
        post :bulk_update, :ids => [1, 2], :issue => {:project_id => '2'}, :copy => '1'
      end
    end
    assert_redirected_to '/projects/ecookbook/issues'

    copies = Issue.order('id DESC').limit(issues.size)
    copies.each do |copy|
      assert_equal 2, copy.project_id
    end
  end

  def test_bulk_copy_should_allow_not_changing_the_issue_attributes
    @request.session[:user_id] = 2
    issues = [
      Issue.create!(:project_id => 1, :tracker_id => 1, :status_id => 1,
                    :priority_id => 2, :subject => 'issue 1', :author_id => 1,
                    :assigned_to_id => nil),
      Issue.create!(:project_id => 2, :tracker_id => 3, :status_id => 2,
                    :priority_id => 1, :subject => 'issue 2', :author_id => 2,
                    :assigned_to_id => 3)
    ]
    assert_difference 'Issue.count', issues.size do
      post :bulk_update, :ids => issues.map(&:id), :copy => '1', 
           :issue => {
             :project_id => '', :tracker_id => '', :assigned_to_id => '',
             :status_id => '', :start_date => '', :due_date => ''
           }
    end

    copies = Issue.order('id DESC').limit(issues.size)
    issues.each do |orig|
      copy = copies.detect {|c| c.subject == orig.subject}
      assert_not_nil copy
      assert_equal orig.project_id, copy.project_id
      assert_equal orig.tracker_id, copy.tracker_id
      assert_equal orig.status_id, copy.status_id
      assert_equal orig.assigned_to_id, copy.assigned_to_id
      assert_equal orig.priority_id, copy.priority_id
    end
  end

  def test_bulk_copy_should_allow_changing_the_issue_attributes
    # Fixes random test failure with Mysql
    # where Issue.where(:project_id => 2).limit(2).order('id desc')
    # doesn't return the expected results
    Issue.delete_all("project_id=2")

    @request.session[:user_id] = 2
    assert_difference 'Issue.count', 2 do
      assert_no_difference 'Project.find(1).issues.count' do
        post :bulk_update, :ids => [1, 2], :copy => '1', 
             :issue => {
               :project_id => '2', :tracker_id => '', :assigned_to_id => '4',
               :status_id => '1', :start_date => '2009-12-01', :due_date => '2009-12-31'
             }
      end
    end

    copied_issues = Issue.where(:project_id => 2).limit(2).order('id desc').to_a
    assert_equal 2, copied_issues.size
    copied_issues.each do |issue|
      assert_equal 2, issue.project_id, "Project is incorrect"
      assert_equal 4, issue.assigned_to_id, "Assigned to is incorrect"
      assert_equal 1, issue.status_id, "Status is incorrect"
      assert_equal '2009-12-01', issue.start_date.to_s, "Start date is incorrect"
      assert_equal '2009-12-31', issue.due_date.to_s, "Due date is incorrect"
    end
  end

  def test_bulk_copy_should_allow_adding_a_note
    @request.session[:user_id] = 2
    assert_difference 'Issue.count', 1 do
      post :bulk_update, :ids => [1], :copy => '1',
           :notes => 'Copying one issue',
           :issue => {
             :project_id => '', :tracker_id => '', :assigned_to_id => '4',
             :status_id => '3', :start_date => '2009-12-01', :due_date => '2009-12-31'
           }
    end
    issue = Issue.order('id DESC').first
    assert_equal 1, issue.journals.size
    journal = issue.journals.first
    assert_equal 1, journal.details.size
    assert_equal 'Copying one issue', journal.notes
  end

  def test_bulk_copy_should_allow_not_copying_the_attachments
    attachment_count = Issue.find(3).attachments.size
    assert attachment_count > 0
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', 1 do
      assert_no_difference 'Attachment.count' do
        post :bulk_update, :ids => [3], :copy => '1',
             :issue => {
               :project_id => ''
             }
      end
    end
  end

  def test_bulk_copy_should_allow_copying_the_attachments
    attachment_count = Issue.find(3).attachments.size
    assert attachment_count > 0
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', 1 do
      assert_difference 'Attachment.count', attachment_count do
        post :bulk_update, :ids => [3], :copy => '1', :copy_attachments => '1',
             :issue => {
               :project_id => ''
             }
      end
    end
  end

  def test_bulk_copy_should_add_relations_with_copied_issues
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', 2 do
      assert_difference 'IssueRelation.count', 2 do
        post :bulk_update, :ids => [1, 3], :copy => '1', 
             :issue => {
               :project_id => '1'
             }
      end
    end
  end

  def test_bulk_copy_should_allow_not_copying_the_subtasks
    issue = Issue.generate_with_descendants!
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', 1 do
      post :bulk_update, :ids => [issue.id], :copy => '1',
           :issue => {
             :project_id => ''
           }
    end
  end

  def test_bulk_copy_should_allow_copying_the_subtasks
    issue = Issue.generate_with_descendants!
    count = issue.descendants.count
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', count+1 do
      post :bulk_update, :ids => [issue.id], :copy => '1', :copy_subtasks => '1',
           :issue => {
             :project_id => ''
           }
    end
    copy = Issue.where(:parent_id => nil).order("id DESC").first
    assert_equal count, copy.descendants.count
  end

  def test_bulk_copy_should_not_copy_selected_subtasks_twice
    issue = Issue.generate_with_descendants!
    count = issue.descendants.count
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', count+1 do
      post :bulk_update, :ids => issue.self_and_descendants.map(&:id), :copy => '1', :copy_subtasks => '1',
           :issue => {
             :project_id => ''
           }
    end
    copy = Issue.where(:parent_id => nil).order("id DESC").first
    assert_equal count, copy.descendants.count
  end

  def test_bulk_copy_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1], :copy => '1', :issue => {:project_id => 2}, :follow => '1'
    issue = Issue.order('id DESC').first
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue
  end

  def test_bulk_copy_with_all_failures_should_display_errors
    @request.session[:user_id] = 2
    post :bulk_update, :ids => [1, 2], :copy => '1', :issue => {:start_date => 'foo'}

    assert_response :success
  end

  def test_destroy_issue_with_no_time_entries
    assert_nil TimeEntry.find_by_issue_id(2)
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', -1 do
      delete :destroy, :id => 2
    end
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Issue.find_by_id(2)
  end

  def test_destroy_issues_with_time_entries
    @request.session[:user_id] = 2

    assert_no_difference 'Issue.count' do
      delete :destroy, :ids => [1, 3]
    end
    assert_response :success
    assert_template 'destroy'
    assert_not_nil assigns(:hours)
    assert Issue.find_by_id(1) && Issue.find_by_id(3)

    assert_select 'form' do
      assert_select 'input[name=_method][value=delete]'
    end
  end

  def test_destroy_issues_and_destroy_time_entries
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', -2 do
      assert_difference 'TimeEntry.count', -3 do
        delete :destroy, :ids => [1, 3], :todo => 'destroy'
      end
    end
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find_by_id([1, 2])
  end

  def test_destroy_issues_and_assign_time_entries_to_project
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', -2 do
      assert_no_difference 'TimeEntry.count' do
        delete :destroy, :ids => [1, 3], :todo => 'nullify'
      end
    end
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find(1).issue_id
    assert_nil TimeEntry.find(2).issue_id
  end

  def test_destroy_issues_and_reassign_time_entries_to_another_issue
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', -2 do
      assert_no_difference 'TimeEntry.count' do
        delete :destroy, :ids => [1, 3], :todo => 'reassign', :reassign_to_id => 2
      end
    end
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_equal 2, TimeEntry.find(1).issue_id
    assert_equal 2, TimeEntry.find(2).issue_id
  end

  def test_destroy_issues_from_different_projects
    @request.session[:user_id] = 2

    assert_difference 'Issue.count', -3 do
      delete :destroy, :ids => [1, 2, 6], :todo => 'destroy'
    end
    assert_redirected_to :controller => 'issues', :action => 'index'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(2) || Issue.find_by_id(6))
  end

  def test_destroy_parent_and_child_issues
    parent = Issue.create!(:project_id => 1, :author_id => 1, :tracker_id => 1, :subject => 'Parent Issue')
    child = Issue.create!(:project_id => 1, :author_id => 1, :tracker_id => 1, :subject => 'Child Issue', :parent_issue_id => parent.id)
    assert child.is_descendant_of?(parent.reload)

    @request.session[:user_id] = 2
    assert_difference 'Issue.count', -2 do
      delete :destroy, :ids => [parent.id, child.id], :todo => 'destroy'
    end
    assert_response 302
  end

  def test_destroy_invalid_should_respond_with_404
    @request.session[:user_id] = 2
    assert_no_difference 'Issue.count' do
      delete :destroy, :id => 999
    end
    assert_response 404
  end

  def test_default_search_scope
    get :index

    assert_select 'div#quick-search form' do
      assert_select 'input[name=issues][value=1][type=hidden]'
    end
  end
end
