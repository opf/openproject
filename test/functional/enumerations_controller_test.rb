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
require 'enumerations_controller'

# Re-raise errors caught by the controller.
class EnumerationsController; def rescue_action(e) raise e end; end

class EnumerationsControllerTest < ActionController::TestCase
  fixtures :enumerations, :issues, :users

  def setup
    @controller = EnumerationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_destroy_enumeration_not_in_use
    post :destroy, :id => 7
    assert_redirected_to :controller => 'enumerations', :action => 'index'
    assert_nil Enumeration.find_by_id(7)
  end

  def test_destroy_enumeration_in_use
    post :destroy, :id => 4
    assert_response :success
    assert_template 'destroy'
    assert_not_nil Enumeration.find_by_id(4)
  end

  def test_destroy_enumeration_in_use_with_reassignment
    issue = Issue.find(:first, :conditions => {:priority_id => 4})
    post :destroy, :id => 4, :reassign_to_id => 6
    assert_redirected_to :controller => 'enumerations', :action => 'index'
    assert_nil Enumeration.find_by_id(4)
    # check that the issue was reassign
    assert_equal 6, issue.reload.priority_id
  end
end
