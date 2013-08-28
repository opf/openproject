#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'issues_controller'

# Re-raise errors caught by the controller.
class IssuesController; def rescue_action(e) raise e end; end

class IssuesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = IssuesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_index
    Setting.default_language = 'en'

    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_tag :tag => 'a', :content => ERB::Util.html_escape("Can't print recipes")
    assert_tag :tag => 'a', :content => /Subproject issue/
    # private projects hidden
    assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
    assert_no_tag :tag => 'a', :content => /Issue on project 2/
    # project column
    assert_tag :tag => 'th', :content => /Project/
  end

  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_no_tag :tag => 'a', :content => ERB::Util.html_escape("Can't print recipes")
    assert_tag :tag => 'a', :content => /Subproject issue/
  end

  def test_index_should_not_list_issues_when_module_disabled
    EnabledModule.delete_all("name = 'issue_tracking' AND project_id = 1")
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:project)
    assert_no_tag :tag => 'a', :content => ERB::Util.html_escape("Can't print recipes")
    assert_tag :tag => 'a', :content => /Subproject issue/
  end

  def test_index_with_project
    Setting.display_subprojects_issues = 0
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => ERB::Util.html_escape("Can't print recipes")
    assert_no_tag :tag => 'a', :content => /Subproject issue/
  end

  def test_index_with_project_and_subprojects
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => ERB::Util.html_escape("Can't print recipes")
    assert_tag :tag => 'a', :content => /Subproject issue/
    assert_no_tag :tag => 'a', :content => /Issue of a private subproject/
  end

  def test_index_with_project_and_subprojects_should_show_private_subprojects
    @request.session[:user_id] = 2
    Setting.display_subprojects_issues = 1
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_tag :tag => 'a', :content => ERB::Util.html_escape("Can't print recipes")
    assert_tag :tag => 'a', :content => /Subproject issue/
    assert_tag :tag => 'a', :content => /Issue of a private subproject/
  end

  def test_index_with_project_and_default_filter
    get :index, :project_id => 1, :set_filter => 1
    assert_response :success
    assert_template ''
    assert_not_nil assigns(:issues)

    query = assigns(:query)
    assert_not_nil query
    # default filter
    assert_equal({'status_id' => {:operator => 'o', :values => ['']}}, query.filters)
  end

  def test_index_with_project_and_filter
    get :index, :project_id => 1, :set_filter => 1,
      :f => ['type_id'],
      :op => {'type_id' => '='},
      :v => {'type_id' => ['1']}
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)

    query = assigns(:query)
    assert_not_nil query
    assert_equal({'type_id' => {:operator => '=', :values => ['1']}}, query.filters)
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

  def test_index_with_query
    get :index, :project_id => 1, :query_id => 5
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:issues)
    assert_nil assigns(:issue_count_by_group)
  end

  def test_index_with_query_grouped_by_type
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

  def test_index_sort_by_field_not_included_in_columns
    Setting.issue_list_default_columns = %w(subject author)
    get :index, :sort => 'type'
  end

  def test_index_csv_with_project
    Setting.default_language = 'en'
    Role.anonymous.add_permission!(:export_issues)

    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv; header=present', @response.content_type
    assert @response.body.starts_with?("#,")

    get :index, :project_id => 1, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_equal 'text/csv; header=present', @response.content_type
  end

  def test_index_pdf
    Role.anonymous.add_permission!(:export_issues)

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

  def test_index_pdf_with_query_grouped_by_list_custom_field
    Role.anonymous.add_permission!(:export_issues)

    get :index, :project_id => 1, :query_id => 9, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert_not_nil assigns(:issue_count_by_group)
    assert_equal 'application/pdf', @response.content_type
  end

  def test_index_sort
    get :index, :sort => 'type,id:desc'
    assert_response :success

    sort_params = @request.session['issues_index_sort']
    assert sort_params.is_a?(String)
    assert_equal 'type,id:desc', sort_params

    issues = assigns(:issues)
    assert_not_nil issues
    assert !issues.empty?
    assert_equal issues.sort {|a,b| a.type == b.type ? b.id <=> a.id : a.type <=> b.type }.collect(&:id), issues.collect(&:id)
  end

  def test_index_with_columns
    columns = ['type', 'subject', 'assigned_to']
    get :index, :set_filter => 1, :c => columns
    assert_response :success

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of Query, query
    assert_equal columns, query.column_names.map(&:to_s)

    # columns should be stored in session
    assert_kind_of Hash, session[:query]
    assert_kind_of Array, session[:query][:column_names]
    assert_equal columns, session[:query][:column_names].map(&:to_s)
  end

  def test_show_by_anonymous
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)

    # anonymous role is allowed to add a note
    assert_tag :tag => 'ul',
               :attributes => { :class => "action_menu_main" },
               :child => { :tag => 'li',
                           :child => { :tag => 'a',
                                       :content => /Update/ } }
  end

  def test_show_by_manager
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response :success

    assert_tag :tag => 'a',
      :content => /Quote/

    assert_tag :tag => 'ul',
               :attributes => { :class => "action_menu_main" },
               :child => { :tag => 'li',
                           :child => { :tag => 'a',
                                       :content => /Update/ } },
               :child => { :tag => 'li',
                           :child => { :tag => 'ul',
                                       :attributes => { :class => 'action_menu_more' },
                                       :child => { :tag => 'li',
                                                   :child => { :tag => 'a',
                                                               :content => /Log time/ } },
                                       :child => { :tag => 'li',
                                                   :child => { :tag => 'a',
                                                               :content => /Delete/ } } } }
  end

  def test_show_should_deny_anonymous_access_without_permission
    Role.anonymous.remove_permission!(:view_work_packages)
    get :show, :id => 1
    assert_response :redirect
  end

  def test_show_should_deny_non_member_access_without_permission
    Role.non_member.remove_permission!(:view_work_packages)
    @request.session[:user_id] = 9
    get :show, :id => 1
    assert_response 403
  end

  def test_show_should_deny_member_access_without_permission
    Role.find(1).remove_permission!(:view_work_packages)
    @request.session[:user_id] = 2
    get :show, :id => 1
    assert_response 403
  end

  def test_show_should_not_disclose_relations_to_invisible_issues
    Setting.cross_project_issue_relations = '1'
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(2), :relation_type => 'relates')
    # Relation to a private project issue
    IssueRelation.create!(:issue_from => Issue.find(1), :issue_to => Issue.find(4), :relation_type => 'relates')

    get :show, :id => 1
    assert_response :success

    assert_select 'div#relations a[href*="work_packages/2"]'
    assert_select 'div#relations a[href*="work_packages/4"]', false
  end

  def test_show_atom
    issue = Issue.find(2)

    issue.recreate_initial_journal!

    get :show, :id => 2, :format => 'atom'
    assert_response :success
    assert_template 'journals/index'
    assert_match /http:\/\/test\.host\/work_packages\/2/, response.body
  end

  def test_show_export_to_pdf
    get :show, :id => 3, :format => 'pdf'
    assert_response :success
    assert_equal 'application/pdf', @response.content_type
    assert @response.body.starts_with?('%PDF')
    assert_not_nil assigns(:issue)
  end

  def test_get_new
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :type_id => 1
    assert_response :success
    assert_template 'new'

    assert_tag :tag => 'input', :attributes => { :name => 'issue[custom_field_values][2]',
                                                 :value => 'Default string' }
  end

  def test_get_new_without_type_id
    @request.session[:user_id] = 2
    get :new, :project_id => 1
    assert_response :success
    assert_template 'new'

    issue = assigns(:issue)
    assert_not_nil issue
    assert_equal Project.find(1).types.first, issue.type
  end

  def test_get_new_with_no_default_status_should_display_an_error
    @request.session[:user_id] = 2
    IssueStatus.delete_all

    get :new, :project_id => 1
    assert_response 500
    assert_error_tag :content => /No default work package/
  end

  def test_get_new_with_no_type_should_display_an_error
    @request.session[:user_id] = 2
    Type.delete_all

    get :new, :project_id => 1
    assert_response 500
    assert_error_tag :content => /No type/
  end

  def test_update_new_form
    @request.session[:user_id] = 2
    xhr :post, :new, :project_id => 1,
                     :issue => {:type_id => 2,
                                :subject => 'This is the test_new issue',
                                :description => 'This is the description',
                                :priority_id => 5}
    assert_response :success
    assert_template 'attributes'

    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.project_id
    assert_equal 2, issue.type_id
    assert_equal 'This is the test_new issue', issue.subject
  end

  def test_post_create
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:type_id => 3,
                            :status_id => 2,
                            :subject => 'This is the test_create issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :start_date => '2010-11-07',
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    issue = Issue.find_by_subject('This is the test_create issue')
    assert_not_nil issue
    assert_equal 2, issue.author_id
    assert_equal 3, issue.type_id
    assert_equal 2, issue.status_id
    assert_equal Date.parse('2010-11-07'), issue.start_date
    assert_nil issue.estimated_hours
    v = issue.custom_values.find(:first, :conditions => {:custom_field_id => 2})
    assert_not_nil v
    assert_equal 'Value for field 2', v.value
  end

  def test_post_create_should_not_send_a_notification_if_send_notification_is_off
    Journal.delete_all
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 2
    post :create, :project_id => 1,
               :send_notification => '0',
               :issue => {:type_id => 3,
                          :subject => 'This is the test_new issue',
                          :description => 'This is the description',
                          :priority_id => 5,
                          :estimated_hours => '',
                          :custom_field_values => {'2' => 'Value for field 2'}}
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    assert_equal 0, ActionMailer::Base.deliveries.size
    end

  def test_post_create_without_start_date
    with_settings :issue_startdate_is_adddate => "0" do
      @request.session[:user_id] = 2
      assert_difference 'Issue.count' do
        post :create, :project_id => 1,
                   :issue => {:type_id => 3,
                              :status_id => 2,
                              :subject => 'This is the test_new issue',
                              :description => 'This is the description',
                              :priority_id => 5,
                              :start_date => '',
                              :estimated_hours => '',
                              :custom_field_values => {'2' => 'Value for field 2'}}
      end
      assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

      issue = Issue.find_by_subject('This is the test_new issue')
      assert_not_nil issue
      assert_nil issue.start_date
    end
  end

  def test_post_create_and_continue
    @request.session[:user_id] = 2
    post :create, :project_id => 1,
               :issue => {:type_id => 3,
                          :subject => 'This is first issue',
                          :priority_id => 5},
               :continue => ''
    assert_redirected_to :controller => 'issues', :action => 'new', :project_id => 'ecookbook',
                         :issue => {:type_id => 3}
  end

  def test_post_create_without_custom_fields_param
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:type_id => 1,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id
  end

  def test_post_create_with_required_custom_field_and_without_custom_fields_param
    field = WorkPackageCustomField.find_by_name('Database')
    field.update_attribute(:is_required, true)

    @request.session[:user_id] = 2
    post :create, :project_id => 1,
               :issue => {:type_id => 1,
                          :subject => 'This is the test_new issue',
                          :description => 'This is the description',
                          :priority_id => 5}
    assert_response :success
    assert_template 'new'
    issue = assigns(:issue)
    assert_not_nil issue
    assert_include issue.errors[:custom_values], I18n.translate('activerecord.errors.messages.invalid')
  end

  def test_post_create_with_watchers
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    assert_difference 'Watcher.count', 2 do
      post :create, :project_id => 1,
                 :issue => {:type_id => 1,
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
    recipients = ActionMailer::Base.deliveries.collect(&:to)
    assert recipients.flatten.include?(User.find(3).mail)
  end

  def test_post_create_subissue
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:type_id => 1,
                            :subject => 'This is a child issue',
                            :parent_id => 2}
    end
    issue = Issue.find_by_subject('This is a child issue')
    assert_not_nil issue
    assert_equal Issue.find(2), issue.parent
  end

  def test_post_create_subissue_with_non_numeric_parent_id
    @request.session[:user_id] = 2

    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:type_id => 1,
                            :subject => 'This is a child issue',
                            :parent_id => 'ABC'}
    end
    issue = Issue.find_by_subject('This is a child issue')
    assert_not_nil issue
    assert_nil issue.parent
  end

  def test_post_create_should_send_a_notification
    Journal.delete_all
    ActionMailer::Base.deliveries.clear
    @request.session[:user_id] = 2
    assert_difference 'Issue.count' do
      post :create, :project_id => 1,
                 :issue => {:type_id => 3,
                            :subject => 'This is the test_new issue',
                            :description => 'This is the description',
                            :priority_id => 5,
                            :estimated_hours => '',
                            :custom_field_values => {'2' => 'Value for field 2'}}
    end
    assert_redirected_to :controller => 'issues', :action => 'show', :id => Issue.last.id

    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_post_create_should_preserve_fields_values_on_validation_failure
    @request.session[:user_id] = 2
    post :create, :project_id => 1,
               :issue => {:type_id => 1,
                          # empty subject
                          :subject => '',
                          :description => 'This is a description',
                          :priority_id => 6,
                          :custom_field_values => {'1' => 'Oracle', '2' => 'Value for field 2'}}
    assert_response :success
    assert_template 'new'

    assert_tag :textarea, :attributes => { :name => 'issue[description]' },
                          :content => /This is a description/
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option', :attributes => { :selected => 'selected',
                                                                       :value => '6' },
                                                      :content => 'High' }
    # Custom fields
    assert_tag :select, :attributes => { :name => 'issue[custom_field_values][1]' },
                        :child => { :tag => 'option', :attributes => { :selected => 'selected',
                                                                       :value => 'Oracle' },
                                                      :content => 'Oracle' }
    assert_tag :input, :attributes => { :name => 'issue[custom_field_values][2]',
                                        :value => 'Value for field 2'}
  end

  def test_post_create_should_ignore_non_safe_attributes
    @request.session[:user_id] = 2
    assert_nothing_raised do
      post :create, :project_id => 1, :issue => { :type => "A param can not be a Type" }
    end
  end

  context "without workflow privilege" do
    setup do
      Workflow.delete_all(["role_id = ?", Role.anonymous.id])
      Role.anonymous.add_permission! :add_issues, :add_issue_notes
    end

    context "#new" do
      should "propose default status only" do
        get :new, :project_id => 1
        assert_response :success
        assert_template 'new'
        assert_tag :tag => 'select',
          :attributes => {:name => 'issue[status_id]'},
          :children => {:count => 1},
          :child => {:tag => 'option', :attributes => {:value => IssueStatus.default.id.to_s}}
      end

      should "accept default status" do
        assert_difference 'Issue.count' do
          post :create, :project_id => 1,
                     :issue => {:type_id => 1,
                                :subject => 'This is an issue',
                                :status_id => 1}
        end
        issue = Issue.last(:order => 'id')
        assert_equal IssueStatus.default, issue.status
      end

      should "ignore unauthorized status" do
        assert_difference 'Issue.count' do
          post :create, :project_id => 1,
                     :issue => {:type_id => 1,
                                :subject => 'This is an issue',
                                :status_id => 3}
        end
        issue = Issue.last(:order => 'id')
        assert_equal IssueStatus.default, issue.status
      end
    end

    context "#update" do
      should "ignore status change" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:status_id => 3}
        end
        assert_equal 1, Issue.find(1).status_id
      end

      should "ignore attributes changes" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:subject => 'changed', :assigned_to_id => 2}
        end
        issue = Issue.find(1)
        assert_equal "Can't print recipes", issue.subject
        assert_nil issue.assigned_to
      end
    end
  end

  context "with workflow privilege" do
    setup do
      Workflow.delete_all(["role_id = ?", Role.anonymous.id])
      Workflow.create!(:role => Role.anonymous, :type_id => 1, :old_status_id => 1, :new_status_id => 3)
      Workflow.create!(:role => Role.anonymous, :type_id => 1, :old_status_id => 1, :new_status_id => 4)
      Role.anonymous.add_permission! :add_issues, :add_issue_notes
    end

    context "#update" do
      should "accept authorized status" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:status_id => 3}
        end
        assert_equal 3, Issue.find(1).status_id
      end

      should "ignore unauthorized status" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:status_id => 2}
        end
        assert_equal 1, Issue.find(1).status_id
      end

      should "accept authorized attributes changes" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:assigned_to_id => 2}
        end
        issue = Issue.find(1)
        assert_equal 2, issue.assigned_to_id
      end

      should "ignore unauthorized attributes changes" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:subject => 'changed'}
        end
        issue = Issue.find(1)
        assert_equal "Can't print recipes", issue.subject
      end
    end

    context "and :edit_work_packages permission" do
      setup do
        Role.anonymous.add_permission! :add_issues, :edit_work_packages
      end

      should "accept authorized status" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:status_id => 3}
        end
        assert_equal 3, Issue.find(1).status_id
      end

      should "ignore unauthorized status" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:status_id => 2}
        end
        assert_equal 1, Issue.find(1).status_id
      end

      should "accept authorized attributes changes" do
        assert_difference 'Journal::WorkPackageJournal.count' do
          put :update, :id => 1, :notes => 'just trying', :issue => {:subject => 'changed', :assigned_to_id => 2}
        end
        issue = Issue.find(1)
        assert_equal "changed", issue.subject
        assert_equal 2, issue.assigned_to_id
      end
    end
  end

  def test_copy_issue
    @request.session[:user_id] = 2
    get :new, :project_id => 1, :copy_from => 1
    assert_template 'new'
    assert_not_nil assigns(:issue)
    orig = Issue.find(1)
    assert_equal orig.subject, assigns(:issue).subject
  end

  def test_get_edit
    @request.session[:user_id] = 2
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(1), assigns(:issue)
  end

  def test_get_edit_with_params
    @request.session[:user_id] = 2
    get :edit, :id => 1, :issue => { :status_id => 5, :priority_id => 7 },
        :time_entry => { :hours => '2.5', :comments => 'test_get_edit_with_params', :activity_id => TimeEntryActivity.first.id }
    assert_response :success
    assert_template 'edit'

    issue = assigns(:issue)
    assert_not_nil issue

    assert_equal 5, issue.status_id
    assert_tag :select, :attributes => { :name => 'issue[status_id]' },
                        :child => { :tag => 'option',
                                    :content => 'Closed',
                                    :attributes => { :selected => 'selected' } }

    assert_equal 7, issue.priority_id
    assert_tag :select, :attributes => { :name => 'issue[priority_id]' },
                        :child => { :tag => 'option',
                                    :content => 'Urgent',
                                    :attributes => { :selected => 'selected' } }

    assert_tag :input, :attributes => { :name => 'time_entry[hours]', :value => '2.5' }
    assert_tag :select, :attributes => { :name => 'time_entry[activity_id]' },
                        :child => { :tag => 'option',
                                    :attributes => { :selected => 'selected', :value => TimeEntryActivity.first.id } }
    assert_tag :input, :attributes => { :name => 'time_entry[comments]', :value => 'test_get_edit_with_params' }
  end

  def test_update_edit_form
    @request.session[:user_id] = 2
    xhr :post, :new, :project_id => 1,
                     :id => 1,
                     :issue => {:type_id => 2,
                                :subject => 'This is the test_new issue',
                                :description => 'This is the description',
                                :priority_id => 5}
    assert_response :success
    assert_template 'attributes'

    issue = assigns(:issue)
    assert_kind_of Issue, issue
    assert_equal 1, issue.id
    assert_equal 1, issue.project_id
    assert_equal 2, issue.type_id
    assert_equal 'This is the test_new issue', issue.subject
  end

  def test_put_update_without_custom_fields_param
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear

    issue = Issue.find(1)
    issue.recreate_initial_journal!

    assert_equal '125', issue.custom_value_for(2).value
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'

    assert_difference('Journal::WorkPackageJournal.count') do
      put :update, :id => 1, :issue => {:subject => new_subject,
        :priority_id => '6',
        :category_id => '1' # no change
      }
    end
    issue.reload
    assert issue.current_journal.changed_data.has_key? :subject
    assert issue.current_journal.changed_data.has_key? :priority_id
    assert !issue.current_journal.changed_data.has_key?(:category_id)

    assert_redirected_to work_package_path(1)
    issue.reload
    assert_equal new_subject, issue.subject
    # Make sure custom fields were not cleared
    assert_equal '125', issue.custom_value_for(2).value

    mail = ActionMailer::Base.deliveries.last
    assert_kind_of Mail::Message, mail
    assert mail.subject.starts_with?("[#{issue.project.name} - #{issue.type.name} ##{issue.id}]")
    mail.text_part.body.encoded.include?("Subject changed from #{old_subject} to #{new_subject}")
    mail.html_part.body.encoded.include?("Subject changed from #{ERB::Util.html_escape(old_subject)} to #{new_subject}")
  end

  def test_put_update_with_custom_field_change
    @request.session[:user_id] = 2
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    ActionMailer::Base.deliveries.clear
    assert_equal '125', issue.custom_value_for(2).value

    assert_difference('Journal::WorkPackageJournal.count') do
      put :update, :id => 1, :issue => {:subject => 'Custom field change',
        :priority_id => '6',
        :category_id => '1', # no change
        :custom_field_values => { '2' => 'New custom value' }
      }
    end
    issue.reload
    assert issue.current_journal.changed_data.has_key? :subject
    assert issue.current_journal.changed_data.has_key? :priority_id
    assert !issue.current_journal.changed_data.has_key?(:category_id)
    assert issue.current_journal.changed_data.has_key? :custom_fields_2

    assert_redirected_to work_package_path(1)
    issue.reload
    assert_equal 'New custom value', issue.custom_value_for(2).value

    mail = ActionMailer::Base.deliveries.last
    assert_kind_of Mail::Message, mail
    assert mail.body.encoded.include?("Searchable field changed from 125 to New custom value")
  end

  def test_put_update_with_status_and_assignee_change
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    assert_equal 1, issue.status_id
    @request.session[:user_id] = 2
    assert_difference('TimeEntry.count', 0) do
      put :update,
           :id => 1,
           :issue => { :status_id => 2, :assigned_to_id => 3 },
           :notes => 'Assigned to dlopper',
           :time_entry => { :hours => '', :comments => '', :activity_id => TimeEntryActivity.first }
    end
    assert_redirected_to work_package_path(1)
    issue.reload
    assert_equal 2, issue.status_id
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal 'Assigned to dlopper', j.notes
    assert_equal 2, j.details.size

    mail = ActionMailer::Base.deliveries.last
    assert mail.body.encoded.include?("Status changed from New to Assigned")
    # subject should contain the new status
    assert mail.subject.include?("(#{ IssueStatus.find(2).name })")
  end

  def test_put_update_with_note_only
    issue = Issue.find(1)
    issue.recreate_initial_journal!
    notes = 'Note added by IssuesControllerTest#test_update_with_note_only'

    # anonymous user
    put :update,
         :id => 1,
         :notes => notes
    assert_redirected_to work_package_path(1)
    issue.reload
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal notes, j.notes
    assert_equal 0, j.details.size
    assert_equal User.anonymous, j.user

    mail = ActionMailer::Base.deliveries.last
    assert mail.body.encoded.include?(notes)
  end

  def test_put_update_with_note_and_spent_time
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    spent_hours_before = Issue.find(1).spent_hours
    assert_difference('TimeEntry.count') do
      put :update,
           :id => 1,
           :notes => '2.5 hours added',
           :time_entry => { :hours => '2.5', :comments => 'test_put_update_with_note_and_spent_time', :activity_id => TimeEntryActivity.first.id }
    end
    assert_redirected_to work_package_path(1)

    issue.reload
    j = Journal.find(:first, :order => 'id DESC')
    assert_equal '2.5 hours added', j.notes
    assert_equal 0, j.details.size

    t = issue.time_entries.find_by_comments('test_put_update_with_note_and_spent_time')
    assert_not_nil t
    assert_equal 2.5, t.hours
    assert_equal spent_hours_before + 2.5, issue.spent_hours
  end

  def test_put_update_with_attachment_only
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    Setting.host_name = 'mydomain.foo'
    Setting.protocol = 'https'

    set_tmp_attachments_directory

    # anonymous user
    put :update,
         :id => 1,
         :notes => '',
         :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    assert_redirected_to work_package_path(1)
    j = Issue.find(1).last_journal
    assert j.notes.blank?
    assert_equal 1, j.details.size
    assert_equal 'testfile.txt', j.new_value_for(j.details.keys.first)
    assert_equal User.anonymous, j.user

    mail = ActionMailer::Base.deliveries.last
    assert mail.text_part.body.encoded.include?('testfile.txt')
    assert mail.html_part.body.encoded =~ /<a href="https:\/\/mydomain.foo\/attachments\/\d+\/testfile.txt">testfile.txt<\/a>/
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
         :notes => '',
         :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    assert_redirected_to work_package_path(1)
    assert_equal '1 file(s) could not be saved.', flash[:warning]

  end if Object.const_defined?(:Mocha)

  def test_put_update_with_no_change
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    ActionMailer::Base.deliveries.clear

    assert_no_difference('Journal.count') do
      put :update,
           :id => 1,
           :notes => ''
    end
    assert_redirected_to work_package_path(1)

    issue.reload
    # No email should be sent
    assert ActionMailer::Base.deliveries.empty?
  end

  def test_put_update_should_send_a_notification
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    issue.recreate_initial_journal!
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'

    put :update, :id => 1, :issue => {:subject => new_subject,
                                     :priority_id => '6',
                                     :category_id => '1' # no change
                                    }
    assert_equal 2, ActionMailer::Base.deliveries.size
  end

  def test_put_update_should_not_send_a_notification_if_send_notification_is_off
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    issue = Issue.find(1)
    old_subject = issue.subject
    new_subject = 'Subject modified by IssuesControllerTest#test_post_edit'

    put :update, :id => 1,
                 :send_notification => '0',
                 :issue => {:subject => new_subject,
                            :priority_id => '6',
                            :category_id => '1' # no change
                           }
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_put_update_with_invalid_spent_time_hours_only
    @request.session[:user_id] = 2
    notes = 'Note added by IssuesControllerTest#test_post_edit_with_invalid_spent_time'

    assert_no_difference('Journal::WorkPackageJournal.count') do
      put :update,
           :id => 1,
           :notes => notes,
           :time_entry => {"comments"=>"", "activity_id"=>"", "hours"=>"2z"}
    end
    assert_response :success
    assert_template 'edit'

    assert_error_tag :descendant => {:content => ERB::Util.html_escape("Activity can't be blank")}
    assert_tag :textarea, :attributes => { :name => 'notes' }, :content => /#{notes}/
    assert_tag :input, :attributes => { :name => 'time_entry[hours]', :value => "2z" }
  end

  def test_put_update_with_invalid_spent_time_comments_only
    @request.session[:user_id] = 2
    notes = 'Note added by IssuesControllerTest#test_post_edit_with_invalid_spent_time'

    assert_no_difference('Journal::WorkPackageJournal.count') do
      put :update,
           :id => 1,
           :notes => notes,
           :time_entry => {"comments"=>"this is my comment", "activity_id"=>"", "hours"=>""}
    end
    assert_response :success
    assert_template 'edit'

    assert_error_tag :descendant => {:content => ERB::Util.html_escape("Activity can't be blank")}
    assert_error_tag :descendant => {:content => ERB::Util.html_escape("Hours can't be blank")}
    assert_tag :textarea, :attributes => { :name => 'notes' }, :content => /#{notes}/
    assert_tag :input, :attributes => { :name => 'time_entry[comments]', :value => "this is my comment" }
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

  def test_put_update_should_redirect_back_using_the_back_url_parameter_off_the_host
    issue = Issue.find(2)
    @request.session[:user_id] = 2

    put :update,
         :id => issue.id,
         :issue => {
           :fixed_version_id => 4
         },
         :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to work_package_path(issue.id)
  end

  def test_get_bulk_edit
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2]
    assert_response :success
    assert_template 'bulk_edit'

    assert_tag :input, :attributes => {:name => 'issue[parent_id]'}

    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert_equal 'date', field.field_format
    assert_tag :input, :attributes => {:name => 'issue[custom_field_values][9]'}

    # System wide custom field
    assert CustomField.find(1).is_for_all?
    assert_tag :select, :attributes => {:name => 'issue[custom_field_values][1]'}
  end

  def test_get_bulk_edit_on_different_projects
    @request.session[:user_id] = 2
    get :bulk_edit, :ids => [1, 2, 6]
    assert_response :success
    assert_template 'bulk_edit'

    # Can not set issues from different projects as children of an issue
    assert_no_tag :input, :attributes => {:name => 'issue[parent_id]'}

    # Project specific custom field, date type
    field = CustomField.find(9)
    assert !field.is_for_all?
    assert !field.project_ids.include?(Issue.find(6).project_id)
    assert_no_tag :input, :attributes => {:name => 'issue[custom_field_values][9]'}
  end

  def test_bulk_update
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk editing',
                                      :issue => { :priority_id => 7,
                                                  :assigned_to_id => '',
                                                  :custom_field_values => {'2' => ''} }

    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7], Issue.find_all_by_id([1, 2]).collect {|i| i.priority.id}

    issue.reload
    journal = issue.journals.reorder('created_at DESC').first
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bullk_update_should_not_send_a_notification_if_send_notification_is_off
    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    put(:bulk_update,
         {
           :ids => [1, 2],
           :issue => {
             :priority_id => 7,
             :assigned_to_id => '',
             :custom_field_values => {'2' => ''}
           },
           :notes => 'Bulk editing',
           :send_notification => '0'
         })

    assert_response 302
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_bulk_update_on_different_projects
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2, 6], :notes => 'Bulk editing',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}

    assert_response 302
    # check that the issues were updated
    assert_equal [7, 7, 7], Issue.find([1,2,6]).map(&:priority_id)

    issue.reload
    journal = issue.journals.reorder('created_at DESC').first
    assert_equal '125', issue.custom_value_for(2).value
    assert_equal 'Bulk editing', journal.notes
    assert_equal 1, journal.details.size
  end

  def test_bulk_update_on_different_projects_without_rights
    Journal.delete_all

    @request.session[:user_id] = 3
    user = User.find(3)
    action = { :controller => "issues", :action => "bulk_update" }
    assert user.allowed_to?(action, Issue.find(1).project)
    assert ! user.allowed_to?(action, Issue.find(6).project)
    put :bulk_update, :ids => [1, 6], :notes => 'Bulk should fail',
                                     :issue => {:priority_id => 7,
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => ''}}
    assert_response 403
    assert Journal.all.empty?
  end

  def test_bulk_update_should_send_a_notification
    WorkPackage.find(1).recreate_initial_journal!
    WorkPackage.find(2).recreate_initial_journal!

    @request.session[:user_id] = 2
    ActionMailer::Base.deliveries.clear
    put(:bulk_update,
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
    assert_equal 5, ActionMailer::Base.deliveries.size
  end

  def test_bulk_update_status
    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk editing status',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :status_id => '5'}

    assert_response 302
    issue = Issue.find(1)
    assert issue.closed?
  end

  def test_bulk_update_parent_id
    @request.session[:user_id] = 2
    put :bulk_update, :ids => [1, 3],
      :notes => 'Bulk editing parent',
      :issue => {:priority_id => '', :assigned_to_id => '', :status_id => '', :parent_id => '2'}

    assert_response 302
    parent = Issue.find(2)
    assert_equal parent.id, Issue.find(1).parent_id
    assert_equal parent.id, Issue.find(3).parent_id
    assert_equal [1, 3], parent.children.collect(&:id).sort
  end

  def test_bulk_update_custom_field
    issue = Issue.find(1)
    issue.recreate_initial_journal!

    @request.session[:user_id] = 2
    # update issues priority
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk editing custom field',
                                     :issue => {:priority_id => '',
                                                :assigned_to_id => '',
                                                :custom_field_values => {'2' => '777'}}

    assert_response 302

    issue.reload
    journal = issue.journals.last
    assert_equal '777', issue.custom_value_for(2).value
    assert_equal 1, journal.details.size
    assert_equal '125', journal.old_value_for(:custom_fields_2)
    assert_equal '777', journal.new_value_for(:custom_fields_2)
  end

  def test_bulk_update_unassign
    assert_not_nil Issue.find(2).assigned_to
    @request.session[:user_id] = 2
    # unassign issues
    put :bulk_update, :ids => [1, 2], :notes => 'Bulk unassigning', :issue => {:assigned_to_id => 'none'}
    assert_response 302
    # check that the issues were updated
    assert_nil Issue.find(2).assigned_to
  end

  def test_post_bulk_update_should_allow_fixed_version_to_be_set_to_a_subproject
    @request.session[:user_id] = 2

    put :bulk_update, :ids => [1,2], :issue => {:fixed_version_id => 4}

    assert_response :redirect
    issues = Issue.find([1,2])
    issues.each do |issue|
      assert_equal 4, issue.fixed_version_id
      assert_not_equal issue.project_id, issue.fixed_version.project_id
    end
  end

  def test_post_bulk_update_should_redirect_back_using_the_back_url_parameter
    @request.session[:user_id] = 2
    put :bulk_update, :ids => [1,2], :back_url => '/issues'

    assert_response :redirect
    assert_redirected_to '/issues'
  end

  def test_post_bulk_update_should_not_redirect_back_using_the_back_url_parameter_off_the_host
    @request.session[:user_id] = 2
    put :bulk_update, :ids => [1,2], :back_url => 'http://google.com'

    assert_response :redirect
    assert_redirected_to :controller => 'issues', :action => 'index', :project_id => Project.find(1).identifier
  end

  def test_destroy_issue_with_no_time_entries
    assert_nil TimeEntry.find_by_work_package_id(2)
    @request.session[:user_id] = 2
    post :destroy, :id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert_nil Issue.find_by_id(2)
  end

  def test_destroy_issues_with_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3]
    assert_response :success
    assert_template 'destroy'
    assert_not_nil assigns(:hours)
    assert Issue.find_by_id(1) && Issue.find_by_id(3)
  end

  def test_destroy_issues_and_destroy_time_entries
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'destroy'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find_by_id([1, 2])
  end

  def test_destroy_issues_and_assign_time_entries_to_project
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'nullify'
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_nil TimeEntry.find(1).work_package_id
    assert_nil TimeEntry.find(2).work_package_id
  end

  def test_destroy_issues_and_reassign_time_entries_to_another_issue
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 3], :todo => 'reassign', :reassign_to_id => 2
    assert_redirected_to :action => 'index', :project_id => 'ecookbook'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(3))
    assert_equal 2, TimeEntry.find(1).work_package_id
    assert_equal 2, TimeEntry.find(2).work_package_id
  end

  def test_destroy_issues_from_different_projects
    @request.session[:user_id] = 2
    post :destroy, :ids => [1, 2, 6], :todo => 'destroy'
    assert_redirected_to :controller => 'issues', :action => 'index'
    assert !(Issue.find_by_id(1) || Issue.find_by_id(2) || Issue.find_by_id(6))
  end

  def test_destroy_parent_and_child_issues
    parent = Issue.generate!(:project_id => 1, :type_id => 1)
    child = Issue.generate!(:project_id => 1, :type_id => 1, :parent_id => parent.id)
    assert child.is_descendant_of?(parent.reload)

    @request.session[:user_id] = 2
    assert_difference 'Issue.count', -2 do
      post :destroy, :ids => [parent.id, child.id], :todo => 'destroy'
    end
    assert_response 302
  end

  def test_default_search_scope
    get :index
    assert_select "#search form" do
      assert_select "input[type=hidden][name=issues][value=1]"
    end
  end

  def test_quote_issue
    issue = WorkPackage.find(6)

    @request.session[:user_id] = 2
    get :quoted, :id => 6
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal issue, assigns(:issue)
  end

  def test_quote_issue_without_permission
    @request.session[:user_id] = 7
    get :quoted, :id => 6
    assert_response 403
  end

  def test_quote_note
    issue = Issue.find(6)

    journal = FactoryGirl.create :work_package_journal, journable_id: issue.id

    @request.session[:user_id] = 2
    get :quoted, :id => 6, :journal_id => journal.id
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:issue)
    assert_equal Issue.find(6), assigns(:issue)
    assert_equal journal, assigns(:journal)
  end
end
