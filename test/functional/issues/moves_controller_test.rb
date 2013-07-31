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

require File.expand_path('../../../test_helper', __FILE__)

class Issues::MovesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    User.current = nil
  end

  def test_create_one_issue_to_another_project
    @request.session[:user_id] = 2
    post :create, :id => 1, :new_project_id => 2, :type_id => '', :assigned_to_id => '', :status_id => '', :start_date => '', :due_date => ''
    assert_redirected_to project_issues_path(:project_id => 'ecookbook')
    assert_equal 2, Issue.find(1).project_id
  end

  def test_create_one_issue_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :create, :id => 1, :new_project_id => 2, :follow => '1'
    assert_redirected_to '/issues/1'
  end

  def test_bulk_create_to_another_project
    @request.session[:user_id] = 2
    post :create, :ids => [1, 2], :new_project_id => 2
    assert_redirected_to project_issues_path(:project_id => 'ecookbook')
    # Issues moved to project 2
    assert_equal 2, Issue.find(1).project_id
    assert_equal 2, Issue.find(2).project_id
    # No type change
    assert_equal 1, Issue.find(1).type_id
    assert_equal 2, Issue.find(2).type_id
  end

  def test_bulk_create_to_another_type
    @request.session[:user_id] = 2
    post :create, :ids => [1, 2], :new_type_id => 2
    assert_redirected_to project_issues_path(:project_id => 'ecookbook')
    assert_equal 2, Issue.find(1).type_id
    assert_equal 2, Issue.find(2).type_id
  end

  context "#create via bulk move" do
    setup do
      @request.session[:user_id] = 2
    end

    should "allow changing the issue priority" do
      post :create, :ids => [1, 2], :priority_id => 6

      assert_redirected_to project_issues_path(:project_id => 'ecookbook')
      assert_equal 6, Issue.find(1).priority_id
      assert_equal 6, Issue.find(2).priority_id

    end

    should "allow adding a note when moving" do
      post :create, :ids => [1, 2], :notes => 'Moving two issues'

      assert_redirected_to project_issues_path(:project_id => 'ecookbook')
      assert_equal 'Moving two issues', Issue.find(1).journals.sort_by(&:id).last.notes
      assert_equal 'Moving two issues', Issue.find(2).journals.sort_by(&:id).last.notes

    end

  end

  def test_bulk_copy_to_another_project
    @request.session[:user_id] = 2
    assert_difference 'Issue.count', 2 do
      assert_no_difference 'Project.find(1).work_packages.count' do
        post :create, :ids => [1, 2], :new_project_id => 2, :copy_options => {:copy => '1'}
      end
    end
    assert_redirected_to '/projects/ecookbook/issues'
  end

  context "#create via bulk copy" do
    should "allow not changing the issue's attributes" do
      @request.session[:user_id] = 2
      issue_before_move = Issue.find(1)
      assert_difference 'Issue.count', 1 do
        assert_no_difference 'Project.find(1).work_packages.count' do
          post :create, :ids => [1], :new_project_id => 2, :copy_options => {:copy => '1'}, :new_type_id => '', :assigned_to_id => '', :status_id => '', :start_date => '', :due_date => ''
        end
      end
      issue_after_move = Issue.first(:order => 'id desc', :conditions => {:project_id => 2})
      assert_equal issue_before_move.type_id, issue_after_move.type_id
      assert_equal issue_before_move.status_id, issue_after_move.status_id
      assert_equal issue_before_move.assigned_to_id, issue_after_move.assigned_to_id
    end

    should "allow changing the issue's attributes" do
      # Fixes random test failure with Mysql
      # where Issue.all(:limit => 2, :order => 'id desc', :conditions => {:project_id => 2}) doesn't return the expected results
      Issue.delete_all("project_id=2")

      @request.session[:user_id] = 2
      assert_difference 'Issue.count', 2 do
        assert_no_difference 'Project.find(1).work_packages.count' do
          post :create, :ids => [1, 2], :new_project_id => 2, :copy_options => {:copy => '1'}, :new_type_id => '', :assigned_to_id => 4, :status_id => 3, :start_date => '2009-12-01', :due_date => '2009-12-31'
        end
      end

      copied_issues = Issue.all(:limit => 2, :order => 'id desc', :conditions => {:project_id => 2})
      assert_equal 2, copied_issues.size
      copied_issues.each do |issue|
        assert_equal 2, issue.project_id, "Project is incorrect"
        assert_equal 4, issue.assigned_to_id, "Assigned to is incorrect"
        assert_equal 3, issue.status_id, "Status is incorrect"
        assert_equal '2009-12-01', issue.start_date.to_s, "Start date is incorrect"
        assert_equal '2009-12-31', issue.due_date.to_s, "Due date is incorrect"
      end
    end
  end

  def test_copy_to_another_project_should_follow_when_needed
    @request.session[:user_id] = 2
    post :create, :ids => [1], :new_project_id => 2, :copy_options => {:copy => '1'}, :follow => '1'
    issue = Issue.first(:order => 'id DESC')
    assert_redirected_to issue_path(issue)
  end

end
