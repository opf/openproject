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
require 'trackers_controller'

# Re-raise errors caught by the controller.
class TrackersController; def rescue_action(e) raise e end; end

class TrackersControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = TrackersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_get_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_post_create
    post :create, :tracker => { :name => 'New tracker', :project_ids => ['1', '', ''], :custom_field_ids => ['1', '6', ''] }
    assert_redirected_to :action => 'index'
    tracker = Tracker.find_by_name('New tracker')
    assert_equal [1], tracker.project_ids.sort
    assert_equal [1, 6], tracker.custom_field_ids
    assert_equal 0, tracker.workflows.count
  end

  def test_post_create_with_workflow_copy
    post :create, :tracker => { :name => 'New tracker' }, :copy_workflow_from => 1
    assert_redirected_to :action => 'index'
    tracker = Tracker.find_by_name('New tracker')
    assert_equal 0, tracker.projects.count
    assert_equal Tracker.find(1).workflows.count, tracker.workflows.count
  end

  def test_get_edit
    Tracker.find(1).project_ids = [1, 3]

    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'

    assert_tag :input, :attributes => { :name => 'tracker[project_ids][]',
                                        :value => '1',
                                        :checked => 'checked' }

    assert_tag :input, :attributes => { :name => 'tracker[project_ids][]',
                                        :value => '2',
                                        :checked => nil }

    assert_tag :input, :attributes => { :name => 'tracker[project_ids][]',
                                        :value => '',
                                        :type => 'hidden'}
  end

  def test_post_update
    post :update, :id => 1, :tracker => { :name => 'Renamed',
                                        :project_ids => ['1', '2', ''] }
    assert_redirected_to :action => 'index'
    assert_equal [1, 2], Tracker.find(1).project_ids.sort
  end

  def test_post_update_without_projects
    post :update, :id => 1, :tracker => { :name => 'Renamed',
                                        :project_ids => [''] }
    assert_redirected_to :action => 'index'
    assert Tracker.find(1).project_ids.empty?
  end

  def test_move_lower
   tracker = Tracker.find_by_position(1)
   post :update, :id => 1, :tracker => { :move_to => 'lower' }
   assert_equal 2, tracker.reload.position
  end

  def test_destroy
    tracker = Tracker.create!(:name => 'Destroyable')
    assert_difference 'Tracker.count', -1 do
      post :destroy, :id => tracker.id
    end
    assert_redirected_to :action => 'index'
    assert_nil flash[:error]
  end

  def test_destroy_tracker_in_use
    assert_no_difference 'Tracker.count' do
      post :destroy, :id => 1
    end
    assert_redirected_to :action => 'index'
    assert_not_nil flash[:error]
  end
end
