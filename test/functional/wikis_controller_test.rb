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
require 'wikis_controller'

# Re-raise errors caught by the controller.
class WikisController; def rescue_action(e) raise e end; end

class WikisControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = WikisController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_create
    @request.session[:user_id] = 1
    assert_nil Project.find(3).wiki
    post :edit, :id => 3, :wiki => { :start_page => 'Start page' }
    assert_response :success
    wiki = Project.find(3).wiki
    assert_not_nil wiki
    assert_equal 'Start page', wiki.start_page
  end

  def test_destroy
    @request.session[:user_id] = 1
    post :destroy, :id => 1, :confirm => 1
    assert_redirected_to :controller => 'projects', :action => 'settings', :id => 'ecookbook', :tab => 'wiki'
    assert_nil Project.find(1).wiki
  end

  def test_not_found
    @request.session[:user_id] = 1
    post :destroy, :id => 999, :confirm => 1
    assert_response 404
  end
end
