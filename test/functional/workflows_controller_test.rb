# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.dirname(__FILE__) + '/../test_helper'
require 'workflows_controller'

# Re-raise errors caught by the controller.
class WorkflowsController; def rescue_action(e) raise e end; end

class WorkflowsControllerTest < ActionController::TestCase
  fixtures :roles, :trackers, :workflows, :users
  
  def setup
    @controller = WorkflowsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    
    count = Workflow.count(:all, :conditions => 'role_id = 1 AND tracker_id = 2')
    assert_tag :tag => 'a', :content => count.to_s,
                            :attributes => { :href => '/workflows/edit?role_id=1&amp;tracker_id=2' }
  end
  
  def test_get_edit
    get :edit
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:roles)
    assert_not_nil assigns(:trackers)
  end
  
  def test_get_edit_with_role_and_tracker
    get :edit, :role_id => 2, :tracker_id => 1
    assert_response :success
    assert_template 'edit'
    # allowed transitions
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'issue_status[2][]',
                                                 :value => '1',
                                                 :checked => 'checked' }
    # not allowed
    assert_tag :tag => 'input', :attributes => { :type => 'checkbox',
                                                 :name => 'issue_status[2][]',
                                                 :value => '3',
                                                 :checked => nil }
  end
  
  def test_post_edit
    post :edit, :role_id => 2, :tracker_id => 1, :issue_status => {'4' => ['5'], '3' => ['1', '2']}
    assert_redirected_to '/workflows/edit?role_id=2&tracker_id=1'
    
    assert_equal 3, Workflow.count(:conditions => {:tracker_id => 1, :role_id => 2})
    assert_not_nil  Workflow.find(:first, :conditions => {:role_id => 2, :tracker_id => 1, :old_status_id => 3, :new_status_id => 2})
    assert_nil      Workflow.find(:first, :conditions => {:role_id => 2, :tracker_id => 1, :old_status_id => 5, :new_status_id => 4})
  end
  
  def test_clear_workflow
    assert Workflow.count(:conditions => {:tracker_id => 1, :role_id => 2}) > 0

    post :edit, :role_id => 2, :tracker_id => 1
    assert_equal 0, Workflow.count(:conditions => {:tracker_id => 1, :role_id => 2})
  end
  
  def test_get_copy
    get :copy
    assert_response :success
    assert_template 'copy'
  end
  
  def test_post_copy_one_to_one
    source_transitions = status_transitions(:tracker_id => 1, :role_id => 2)
    
    post :copy, :source_tracker_id => '1', :source_role_id => '2',
                :target_tracker_ids => ['3'], :target_role_ids => ['1']
    assert_response 302
    assert_equal source_transitions, status_transitions(:tracker_id => 3, :role_id => 1)
  end
  
  def test_post_copy_one_to_many
    source_transitions = status_transitions(:tracker_id => 1, :role_id => 2)
    
    post :copy, :source_tracker_id => '1', :source_role_id => '2',
                :target_tracker_ids => ['2', '3'], :target_role_ids => ['1', '3']
    assert_response 302
    assert_equal source_transitions, status_transitions(:tracker_id => 2, :role_id => 1)
    assert_equal source_transitions, status_transitions(:tracker_id => 3, :role_id => 1)
    assert_equal source_transitions, status_transitions(:tracker_id => 2, :role_id => 3)
    assert_equal source_transitions, status_transitions(:tracker_id => 3, :role_id => 3)
  end
  
  def test_post_copy_many_to_many
    source_t2 = status_transitions(:tracker_id => 2, :role_id => 2)
    source_t3 = status_transitions(:tracker_id => 3, :role_id => 2)
    
    post :copy, :source_tracker_id => 'any', :source_role_id => '2',
                :target_tracker_ids => ['2', '3'], :target_role_ids => ['1', '3']
    assert_response 302
    assert_equal source_t2, status_transitions(:tracker_id => 2, :role_id => 1)
    assert_equal source_t3, status_transitions(:tracker_id => 3, :role_id => 1)
    assert_equal source_t2, status_transitions(:tracker_id => 2, :role_id => 3)
    assert_equal source_t3, status_transitions(:tracker_id => 3, :role_id => 3)
  end
  
  # Returns an array of status transitions that can be compared
  def status_transitions(conditions)
    Workflow.find(:all, :conditions => conditions,
                        :order => 'tracker_id, role_id, old_status_id, new_status_id').collect {|w| [w.old_status, w.new_status_id]}
  end
end
