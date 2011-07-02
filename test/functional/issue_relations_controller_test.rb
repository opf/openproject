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
require 'issue_relations_controller'

# Re-raise errors caught by the controller.
class IssueRelationsController; def rescue_action(e) raise e end; end


class IssueRelationsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :enabled_modules,
           :enumerations,
           :trackers

  def setup
    @controller = IssueRelationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_new
    assert_difference 'IssueRelation.count' do
      @request.session[:user_id] = 3
      post :new, :issue_id => 1,
                 :relation => {:issue_to_id => '2', :relation_type => 'relates', :delay => ''}
    end
  end

  def test_new_xhr
    assert_difference 'IssueRelation.count' do
      @request.session[:user_id] = 3
      xhr :post, :new,
        :issue_id => 3,
        :relation => {:issue_to_id => '1', :relation_type => 'relates', :delay => ''}
      assert_select_rjs 'relations' do
        assert_select 'table', 1
        assert_select 'tr', 2 # relations
      end
    end
  end

  def test_new_should_accept_id_with_hash
    assert_difference 'IssueRelation.count' do
      @request.session[:user_id] = 3
      post :new, :issue_id => 1,
                 :relation => {:issue_to_id => '#2', :relation_type => 'relates', :delay => ''}
    end
  end

  def test_new_should_not_break_with_non_numerical_id
    assert_no_difference 'IssueRelation.count' do
      assert_nothing_raised do
        @request.session[:user_id] = 3
        post :new, :issue_id => 1,
                   :relation => {:issue_to_id => 'foo', :relation_type => 'relates', :delay => ''}
      end
    end
  end

  def test_should_create_relations_with_visible_issues_only
    Setting.cross_project_issue_relations = '1'
    assert_nil Issue.visible(User.find(3)).find_by_id(4)

    assert_no_difference 'IssueRelation.count' do
      @request.session[:user_id] = 3
      post :new, :issue_id => 1,
                 :relation => {:issue_to_id => '4', :relation_type => 'relates', :delay => ''}
    end
  end

  def test_destroy
    assert_difference 'IssueRelation.count', -1 do
      @request.session[:user_id] = 3
      post :destroy, :id => '2', :issue_id => '3'
    end
  end

  def test_destroy_xhr
    IssueRelation.create!(:relation_type => IssueRelation::TYPE_RELATES) do |r|
      r.issue_from_id = 3
      r.issue_to_id = 1
    end

    assert_difference 'IssueRelation.count', -1 do
      @request.session[:user_id] = 3
      xhr :post, :destroy, :id => '2', :issue_id => '3'
      assert_select_rjs 'relations' do
        assert_select 'table', 1
        assert_select 'tr', 1 # relation left
      end
    end
  end
end
