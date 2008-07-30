# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < Test::Unit::TestCase
  fixtures :projects, :versions, :users, :roles, :members, :issues, :journals, :journal_details,
           :trackers, :projects_trackers, :issue_statuses, :enabled_modules, :enumerations, :boards, :messages

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = nil
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:project_tree)
    # Root project as hash key
    assert assigns(:project_tree).keys.include?(Project.find(1))
    # Subproject in corresponding value
    assert assigns(:project_tree)[Project.find(1)].include?(Project.find(3))
  end
  
  def test_index_atom
    get :index, :format => 'atom'
    assert_response :success
    assert_template 'common/feed.atom.rxml'
    assert_select 'feed>title', :text => 'Redmine: Latest projects'
    assert_select 'feed>entry', :count => Project.count(:conditions => Project.visible_by(User.current))
  end
  
  def test_show_by_id
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:project)
  end

  def test_show_by_identifier
    get :show, :id => 'ecookbook'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:project)
    assert_equal Project.find_by_identifier('ecookbook'), assigns(:project)
  end
  
  def test_private_subprojects_hidden
    get :show, :id => 'ecookbook'
    assert_response :success
    assert_template 'show'
    assert_no_tag :tag => 'a', :content => /Private child/
  end

  def test_private_subprojects_visible
    @request.session[:user_id] = 2 # manager who is a member of the private subproject
    get :show, :id => 'ecookbook'
    assert_response :success
    assert_template 'show'
    assert_tag :tag => 'a', :content => /Private child/
  end
  
  def test_settings
    @request.session[:user_id] = 2 # manager
    get :settings, :id => 1
    assert_response :success
    assert_template 'settings'
  end
  
  def test_edit
    @request.session[:user_id] = 2 # manager
    post :edit, :id => 1, :project => {:name => 'Test changed name',
                                       :issue_custom_field_ids => ['']}
    assert_redirected_to 'projects/settings/ecookbook'
    project = Project.find(1)
    assert_equal 'Test changed name', project.name
  end
  
  def test_get_destroy
    @request.session[:user_id] = 1 # admin
    get :destroy, :id => 1
    assert_response :success
    assert_template 'destroy'
    assert_not_nil Project.find_by_id(1)
  end

  def test_post_destroy
    @request.session[:user_id] = 1 # admin
    post :destroy, :id => 1, :confirm => 1
    assert_redirected_to 'admin/projects'
    assert_nil Project.find_by_id(1)
  end
  
  def test_list_files
    get :list_files, :id => 1
    assert_response :success
    assert_template 'list_files'
    assert_not_nil assigns(:versions)
  end

  def test_changelog
    get :changelog, :id => 1
    assert_response :success
    assert_template 'changelog'
    assert_not_nil assigns(:versions)
  end
  
  def test_roadmap
    get :roadmap, :id => 1
    assert_response :success
    assert_template 'roadmap'
    assert_not_nil assigns(:versions)
    # Version with no date set appears
    assert assigns(:versions).include?(Version.find(3))
    # Completed version doesn't appear
    assert !assigns(:versions).include?(Version.find(1))
  end
  
  def test_roadmap_with_completed_versions
    get :roadmap, :id => 1, :completed => 1
    assert_response :success
    assert_template 'roadmap'
    assert_not_nil assigns(:versions)
    # Version with no date set appears
    assert assigns(:versions).include?(Version.find(3))
    # Completed version appears
    assert assigns(:versions).include?(Version.find(1))
  end

  def test_project_activity
    get :activity, :id => 1, :with_subprojects => 0
    assert_response :success
    assert_template 'activity'
    assert_not_nil assigns(:events_by_day)
    
    assert_tag :tag => "h3", 
               :content => /#{2.days.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /issue-edit/ },
                   :child => { :tag => "a",
                     :content => /(#{IssueStatus.find(2).name})/,
                   }
                 }
               }
  end
  
  def test_previous_project_activity
    get :activity, :id => 1, :from => 3.days.ago.to_date
    assert_response :success
    assert_template 'activity'
    assert_not_nil assigns(:events_by_day)
               
    assert_tag :tag => "h3", 
               :content => /#{3.day.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /issue/ },
                   :child => { :tag => "a",
                     :content => /#{Issue.find(1).subject}/,
                   }
                 }
               }
  end
  
  def test_global_activity
    get :activity
    assert_response :success
    assert_template 'activity'
    assert_not_nil assigns(:events_by_day)
    
    assert_tag :tag => "h3", 
               :content => /#{5.day.ago.to_date.day}/,
               :sibling => { :tag => "dl",
                 :child => { :tag => "dt",
                   :attributes => { :class => /issue/ },
                   :child => { :tag => "a",
                     :content => /#{Issue.find(5).subject}/,
                   }
                 }
               }
  end
  
  def test_activity_atom_feed
    get :activity, :format => 'atom'
    assert_response :success
    assert_template 'common/feed.atom.rxml'
  end
  
  def test_calendar
    get :calendar, :id => 1
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
  end

  def test_calendar_with_subprojects_should_not_show_private_subprojects
    get :calendar, :id => 1, :with_subprojects => 1, :tracker_ids => [1, 2]
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
    assert_no_tag :tag => 'a', :content => /#6/
  end
  
  def test_calendar_with_subprojects_should_show_private_subprojects
    @request.session[:user_id] = 2
    get :calendar, :id => 1, :with_subprojects => 1, :tracker_ids => [1, 2]
    assert_response :success
    assert_template 'calendar'
    assert_not_nil assigns(:calendar)
    assert_tag :tag => 'a', :content => /#6/
  end

  def test_gantt
    get :gantt, :id => 1
    assert_response :success
    assert_template 'gantt.rhtml'
    events = assigns(:events)
    assert_not_nil events
    # Issue with start and due dates
    i = Issue.find(1)
    assert_not_nil i.due_date
    assert events.include?(Issue.find(1))
    # Issue with without due date but targeted to a version with date
    i = Issue.find(2)
    assert_nil i.due_date
    assert events.include?(i)
  end

  def test_gantt_with_subprojects_should_not_show_private_subprojects
    get :gantt, :id => 1, :with_subprojects => 1, :tracker_ids => [1, 2]
    assert_response :success
    assert_template 'gantt.rhtml'
    assert_not_nil assigns(:events)
    assert_no_tag :tag => 'a', :content => /#6/
  end
  
  def test_gantt_with_subprojects_should_show_private_subprojects
    @request.session[:user_id] = 2
    get :gantt, :id => 1, :with_subprojects => 1, :tracker_ids => [1, 2]
    assert_response :success
    assert_template 'gantt.rhtml'
    assert_not_nil assigns(:events)
    assert_tag :tag => 'a', :content => /#6/
  end

  def test_gantt_export_to_pdf
    get :gantt, :id => 1, :format => 'pdf'
    assert_response :success
    assert_template 'gantt.rfpdf'
    assert_equal 'application/pdf', @response.content_type
    assert_not_nil assigns(:events)
  end
  
  def test_archive    
    @request.session[:user_id] = 1 # admin
    post :archive, :id => 1
    assert_redirected_to 'admin/projects'
    assert !Project.find(1).active?
  end
  
  def test_unarchive
    @request.session[:user_id] = 1 # admin
    Project.find(1).archive
    post :unarchive, :id => 1
    assert_redirected_to 'admin/projects'
    assert Project.find(1).active?
  end
  
  def test_project_menu
    assert_no_difference 'Redmine::MenuManager.items(:project_menu).size' do
      Redmine::MenuManager.map :project_menu do |menu|
        menu.push :foo, { :controller => 'projects', :action => 'show' }, :cation => 'Foo'
        menu.push :bar, { :controller => 'projects', :action => 'show' }, :before => :activity
        menu.push :hello, { :controller => 'projects', :action => 'show' }, :caption => Proc.new {|p| p.name.upcase }, :after => :bar
      end
      
      get :show, :id => 1
      assert_tag :div, :attributes => { :id => 'main-menu' },
                       :descendant => { :tag => 'li', :child => { :tag => 'a', :content => 'Foo' } }
  
      assert_tag :div, :attributes => { :id => 'main-menu' },
                       :descendant => { :tag => 'li', :child => { :tag => 'a', :content => 'Bar' },
                                                      :before => { :tag => 'li', :child => { :tag => 'a', :content => 'ECOOKBOOK' } } }

      assert_tag :div, :attributes => { :id => 'main-menu' },
                       :descendant => { :tag => 'li', :child => { :tag => 'a', :content => 'ECOOKBOOK' },
                                                      :before => { :tag => 'li', :child => { :tag => 'a', :content => 'Activity' } } }
      
      # Remove the menu items
      Redmine::MenuManager.map :project_menu do |menu|
        menu.delete :foo
        menu.delete :bar
        menu.delete :hello
      end
    end
  end
end
