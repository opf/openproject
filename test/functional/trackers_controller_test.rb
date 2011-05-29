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
require 'trackers_controller'

# Re-raise errors caught by the controller.
class TrackersController; def rescue_action(e) raise e end; end

class TrackersControllerTest < ActionController::TestCase
  fixtures :trackers, :projects, :projects_trackers, :users, :issues, :custom_fields
  
  def setup
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

  def test_post_new
    post :new, :tracker => { :name => 'New tracker', :project_ids => ['1', '', ''], :custom_field_ids => ['1', '6', ''] }
    assert_redirected_to :action => 'index'
    tracker = Tracker.find_by_name('New tracker')
    assert_equal [1], tracker.project_ids.sort
    assert_equal [1, 6], tracker.custom_field_ids
    assert_equal 0, tracker.workflows.count
  end

  def test_post_new_with_workflow_copy
    post :new, :tracker => { :name => 'New tracker' }, :copy_workflow_from => 1
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

  def test_post_edit
    post :edit, :id => 1, :tracker => { :name => 'Renamed',
                                        :project_ids => ['1', '2', ''] }
    assert_redirected_to :action => 'index'
    assert_equal [1, 2], Tracker.find(1).project_ids.sort
  end

  def test_post_edit_without_projects
    post :edit, :id => 1, :tracker => { :name => 'Renamed',
                                        :project_ids => [''] }
    assert_redirected_to :action => 'index'
    assert Tracker.find(1).project_ids.empty?
  end
  
  def test_move_lower
   tracker = Tracker.find_by_position(1)
   post :edit, :id => 1, :tracker => { :move_to => 'lower' }
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
