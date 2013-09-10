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
require 'enumerations_controller'

# Re-raise errors caught by the controller.
class EnumerationsController; def rescue_action(e) raise e end; end

class EnumerationsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = EnumerationsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_destroy_enumeration_not_in_use
    post :destroy, :id => 7
    assert_redirected_to enumerations_path
    assert_nil Enumeration.find_by_id(7)
  end

  def test_destroy_enumeration_in_use
    post :destroy, :id => 4
    assert_response :success
    assert_template 'destroy'
    assert_not_nil Enumeration.find_by_id(4)
  end

  def test_destroy_enumeration_in_use_with_reassignment
    issue = WorkPackage.find(:first, :conditions => {:priority_id => 4})
    post :destroy, :id => 4, :reassign_to_id => 6
    assert_redirected_to enumerations_path
    assert_nil Enumeration.find_by_id(4)
    # check that the issue was reassign
    assert_equal 6, issue.reload.priority_id
  end
end
