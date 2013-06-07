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

class Issues::PreviewsControllerTest < ActionController::TestCase
  fixtures :all

  def test_preview_new_issue
    @request.session[:user_id] = 2
    post :create, :project_id => '1', :issue => {:description => 'Foo'}
    assert_response :success
    assert_template 'preview'
    assert_not_nil assigns(:description)
  end

  def test_preview_issue_notes
    @request.session[:user_id] = 2
    post :create, :project_id => '1', :id => 1, :issue => {:description => Issue.find(1).description}, :notes => 'Foo'
    assert_response :success
    assert_template 'preview'
    assert_not_nil assigns(:notes)
  end

  def test_preview_journal_notes_for_update
    @request.session[:user_id] = 2
    post :create, :project_id => '1', :id => 1, :notes => 'Foo'
    assert_response :success
    assert_template 'preview'
    assert_not_nil assigns(:notes)
    assert_tag :p, :content => 'Foo'
  end
end
