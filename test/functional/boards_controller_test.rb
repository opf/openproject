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
require 'boards_controller'

# Re-raise errors caught by the controller.
class BoardsController; def rescue_action(e) raise e end; end

class BoardsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :members, :member_roles, :roles, :boards, :messages, :enabled_modules

  def setup
    @controller = BoardsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_index
    get :index, :project_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:boards)
    assert_not_nil assigns(:project)
  end

  def test_index_not_found
    get :index, :project_id => 97
    assert_response 404
  end

  def test_index_should_show_messages_if_only_one_board
    Project.find(1).boards.slice(1..-1).each(&:destroy)

    get :index, :project_id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:topics)
  end

  def test_post_new
    @request.session[:user_id] = 2
    assert_difference 'Board.count' do
      post :new, :project_id => 1, :board => { :name => 'Testing', :description => 'Testing board creation'}
    end
    assert_redirected_to '/projects/ecookbook/settings/boards'
  end

  def test_show
    get :show, :project_id => 1, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:topics)
  end

  def test_show_atom
    get :show, :project_id => 1, :id => 1, :format => 'atom'
    assert_response :success
    assert_template 'common/feed.atom'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:messages)
  end

  def test_post_edit
    @request.session[:user_id] = 2
    assert_no_difference 'Board.count' do
      post :edit, :project_id => 1, :id => 2, :board => { :name => 'Testing', :description => 'Testing board update'}
    end
    assert_redirected_to '/projects/ecookbook/settings/boards'
    assert_equal 'Testing', Board.find(2).name
  end

  def test_post_destroy
    @request.session[:user_id] = 2
    assert_difference 'Board.count', -1 do
      post :destroy, :project_id => 1, :id => 2
    end
    assert_redirected_to '/projects/ecookbook/settings/boards'
    assert_nil Board.find_by_id(2)
  end

  def test_index_should_404_with_no_board
    Project.find(1).boards.each(&:destroy)

    get :index, :project_id => 1
    assert_response 404
  end
end
