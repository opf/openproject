#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)

class AutoCompletesControllerTest < ActionController::TestCase
  fixtures :all

  def test_issues_should_not_be_case_sensitive
    get :issues, :project_id => 'ecookbook', :q => 'ReCiPe'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).detect {|issue| issue.subject.match /recipe/}
  end

  def test_issues_should_return_issue_with_given_id
    get :issues, :project_id => 'subproject1', :q => '13'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(Issue.find(13))
  end

  test 'should return issues matching a given id' do
    @project = Project.find('subproject1')
    @issue_21 = Issue.generate_for_project!(@project, :id => 21)
    @issue_2101 = Issue.generate_for_project!(@project, :id => 2101)
    @issue_2102 = Issue.generate_for_project!(@project, :id => 2102)
    @issue_with_subject = Issue.generate_for_project!(@project, :subject => 'This has 21 in the subject')

    get :issues, :project_id => @project.id, :q => '21'

    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(@issue_21)
    assert assigns(:issues).include?(@issue_2101)
    assert assigns(:issues).include?(@issue_2102)
    assert assigns(:issues).include?(@issue_with_subject)
    assert_equal assigns(:issues).size, assigns(:issues).uniq.size, "Issues list includes duplicates"
  end

  def test_auto_complete_with_scope_all_and_cross_project_relations
    Setting.cross_project_issue_relations = '1'
    get :issues, :project_id => 'ecookbook', :q => '13', :scope => 'all'
    assert_response :success
    assert_not_nil assigns(:issues)
    assert assigns(:issues).include?(Issue.find(13))
  end

  def test_auto_complete_with_scope_all_without_cross_project_relations
    Setting.cross_project_issue_relations = '0'
    get :issues, :project_id => 'ecookbook', :q => '13', :scope => 'all'
    assert_response :success
    assert_equal [], assigns(:issues)
  end

  context "GET :users" do
    setup do
      @login = User.generate!(:login => 'Acomplete')
      @firstname = User.generate!(:firstname => 'Complete')
      @lastname = User.generate!(:lastname => 'Complete')
      @none = User.generate!(:login => 'hello', :firstname => 'ABC', :lastname => 'DEF')
      @inactive = User.generate!(:firstname => 'Complete', :status => User::STATUS_LOCKED)
    end

    context "with no restrictions" do
      setup do
        get :users, :q => 'complete'
      end
      
      should_respond_with :success
      
      should "render a list of matching users in checkboxes" do
        assert_select "input[type=checkbox][value=?]", @login.id
        assert_select "input[type=checkbox][value=?]", @firstname.id
        assert_select "input[type=checkbox][value=?]", @lastname.id
        assert_select "input[type=checkbox][value=?]", @none.id, :count => 0
      end
      
      should "only show active users" do
        assert_select "input[type=checkbox][value=?]", @inactive.id, :count => 0
      end
    end

    context "including groups" do
      setup do
        @group = Group.generate(:lastname => 'Complete Group').reload
        get :users, :q => 'complete', :include_groups => true
      end
      
      should_respond_with :success
      
      should "include matching groups" do
        assert_select "input[type=checkbox][value=?]", @group.id
      end

    end

    context "restrict by removing group members" do
      setup do
        @group = Group.first
        @group.users << @login
        @group.users << @firstname
        get :users, :q => 'complete', :remove_group_members => @group.id
      end
      
      should_respond_with :success
      
      should "not include existing members of the Group" do
        assert_select "input[type=checkbox][value=?]", @lastname.id

        assert_select "input[type=checkbox][value=?]", @login.id, :count => 0
        assert_select "input[type=checkbox][value=?]", @firstname.id, :count => 0
      end
    end
    
    context "restrict by removing issue watchers" do
      setup do
        @issue = Issue.find(2)
        @issue.add_watcher(@login)
        @issue.add_watcher(@firstname)
        get :users, :q => 'complete', :remove_watchers => @issue.id, :klass => 'Issue'
      end
      
      should_respond_with :success
      
      should "not include existing watchers" do
        assert_select "input[type=checkbox][value=?]", @lastname.id

        assert_select "input[type=checkbox][value=?]", @login.id, :count => 0
        assert_select "input[type=checkbox][value=?]", @firstname.id, :count => 0
      end
    end
  end

  context "POST to #projects" do
    setup do
      # Clear out some fixtures
      Project.delete_all
      ProjectCustomField.delete_all
    end

    should 'require admin' do
      @request.session[:user_id] = 2
      post :projects, {}

      assert_response 403
    end
    
    context 'with a valid search' do
      setup do
        @user = User.generate_with_protected!
        @projects = [
                     Project.generate!(:name => "Test"),
                     Project.generate!(:name => "This is a Test")
                    ]
        Project.generate!(:name => "No match")
        
        @request.session[:user_id] = 1
        post :projects, {
          :id => @user.id,
          :q => 'TeST'
        }
        
      end
      
      should_assign_to(:principal) { @user }
      should_assign_to(:projects) { @projects }
      should_render_template :projects
    end

    context 'with an invalid search' do
      setup do
        @user = User.generate_with_protected!
        Project.generate!(:name => "Test")
        
        @request.session[:user_id] = 1
        post :projects, {
          :id => @user.id,
          :q => 'nothing'
        }
        
      end
      should_assign_to(:principal) { @user }
      should_assign_to(:projects) { [] }
      should_render_template :projects
      
    end
  end
end
