#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'journals_controller'

# Re-raise errors caught by the controller.
class JournalsController; def rescue_action(e) raise e end; end

class JournalsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles, :issues, :journals, :journal_details, :enabled_modules,
  :trackers, :issue_statuses, :enumerations, :custom_fields, :custom_values, :custom_fields_projects

  def setup
    @controller = JournalsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_get_edit
    @request.session[:user_id] = 1
    xhr :get, :edit, :id => 2
    assert_response :success
    assert_select_rjs :insert, :after, 'journal-2-notes' do
      assert_select 'form[id=journal-2-form]'
      assert_select 'textarea'
    end
  end

  def test_post_edit
    @request.session[:user_id] = 1
    xhr :post, :edit, :id => 2, :notes => 'Updated notes'
    assert_response :success
    assert_select_rjs :replace, 'journal-2-notes'
    assert_equal 'Updated notes', Journal.find(2).notes
  end

  def test_post_edit_with_empty_notes
    @request.session[:user_id] = 1
    xhr :post, :edit, :id => 2, :notes => ''
    assert_response :success
    assert_select_rjs :remove, 'change-2'
    assert_nil Journal.find_by_id(2)
  end

  def test_index
    get :index, :project_id => 1
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end

  def test_reply_to_issue
    @request.session[:user_id] = 2
    get :new, :id => 6
    assert_response :success
    assert_select_rjs :show, "update"
  end

  def test_reply_to_issue_without_permission
    @request.session[:user_id] = 7
    get :new, :id => 6
    assert_response 403
  end

  def test_reply_to_note
    @request.session[:user_id] = 2
    get :new, :id => 6, :journal_id => 4
    assert_response :success
    assert_select_rjs :show, "update"
  end

  context "#diff" do
    setup do
      @request.session[:user_id] = 1
      @issue = Issue.find(6)
      @previous_description = @issue.description
      @new_description = "New description"
      
      assert_difference("Journal.count") do
        @issue.description = @new_description
        assert @issue.save
      end
      @last_journal = @issue.last_journal
    end
    
    context "without a valid journal" do
      should "return a 404" do
        get :diff, :id => '0'
        assert_response :not_found
      end
    end


    context "with no field parameter" do
      should "return a 404" do
        get :diff, :id => @last_journal.id
        assert_response :not_found
      end
    end

    context "for an invalid field" do
      should "return a 404" do
        get :diff, :id => @last_journal.id, :field => 'id'
        assert_response :not_found
      end
    end

    context "without permission to view_issues" do
      should "return a 403" do
        @request.session[:user_id] = 7
        get :diff, :id => @last_journal.id, :field => 'description'

        assert_response :forbidden
      end
      
    end

    context "with permission to view_issues" do
      setup do
        get :diff, :id => @last_journal.id, :field => 'description'
      end
      
      should "create a diff" do
        assert_not_nil assigns(:diff)
        assert assigns(:diff).is_a?(Redmine::Helpers::Diff)
      end

      should "render an inline diff" do
        assert_select "#content .text-diff"
      end
      
    end
      
  end
  
end
