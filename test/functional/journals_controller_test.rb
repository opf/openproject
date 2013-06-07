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
require 'journals_controller'

# Re-raise errors caught by the controller.
class JournalsController; def rescue_action(e) raise e end; end

class JournalsControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
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
    xhr :post, :update, :id => 2, :notes => 'Updated notes'
    assert_response :success
    assert_select_rjs :replace, 'journal-2-notes'
    assert_equal 'Updated notes', Journal.find(2).notes
  end

  def test_post_edit_with_empty_notes
    @request.session[:user_id] = 1
    xhr :post, :update, :id => 2, :notes => ''
    assert_response :success
    assert_select_rjs :remove, 'change-2'
    assert_nil Journal.find_by_id(2)
  end

  def test_index
    get :index, :project_id => 1, :format => :atom
    assert_response :success
    assert_not_nil assigns(:journals)
    assert_equal 'application/atom+xml', @response.content_type
  end


end
