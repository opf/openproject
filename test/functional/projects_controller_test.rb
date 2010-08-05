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
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < ActionController::TestCase
  fixtures :projects, :versions, :users, :roles, :members, :member_roles, :issues, :journals,
           :trackers, :projects_trackers, :issue_statuses, :enabled_modules, :enumerations, :boards, :messages,
           :attachments, :custom_fields, :custom_values, :time_entries

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:user_id] = nil
    Setting.default_language = 'en'
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)
    
    assert_tag :ul, :child => {:tag => 'li',
                               :descendant => {:tag => 'a', :content => 'eCookbook'},
                               :child => { :tag => 'ul',
                                           :descendant => { :tag => 'a',
                                                            :content => 'Child of private child'
                                                           }
                                          }
                               }
                               
    assert_no_tag :a, :content => /Private child of eCookbook/
  end
  
  def test_index_atom
    get :index, :format => 'atom'
    assert_response :success
    assert_template 'common/feed.atom.rxml'
    assert_select 'feed>title', :text => 'Redmine: Latest projects'
    assert_select 'feed>entry', :count => Project.count(:conditions => Project.visible_by(User.current))
  end
  
  context "#index" do
    context "by non-admin user with view_time_entries permission" do
      setup do
        @request.session[:user_id] = 3
      end
      should "show overall spent time link" do
        get :index
        assert_template 'index'
        assert_tag :a, :attributes => {:href => '/time_entries'}
      end
    end
    
    context "by non-admin user without view_time_entries permission" do
      setup do
        Role.find(2).remove_permission! :view_time_entries
        Role.non_member.remove_permission! :view_time_entries
        Role.anonymous.remove_permission! :view_time_entries
        @request.session[:user_id] = 3
      end
      should "not show overall spent time link" do
        get :index
        assert_template 'index'
        assert_no_tag :a, :attributes => {:href => '/time_entries'}
      end
    end 
  end
  
  context "#add" do
    context "by admin user" do
      setup do
        @request.session[:user_id] = 1
      end
      
      should "accept get" do
        get :add
        assert_response :success
        assert_template 'add'
      end
      
      should "accept post" do
        post :add, :project => { :name => "blog", 
                                 :description => "weblog",
                                 :identifier => "blog",
                                 :is_public => 1,
                                 :custom_field_values => { '3' => 'Beta' }
                                }
        assert_redirected_to '/projects/blog/settings'
        
        project = Project.find_by_name('blog')
        assert_kind_of Project, project
        assert_equal 'weblog', project.description 
        assert_equal true, project.is_public?
        assert_nil project.parent
      end
      
      should "accept post with parent" do
        post :add, :project => { :name => "blog", 
                                 :description => "weblog",
                                 :identifier => "blog",
                                 :is_public => 1,
                                 :custom_field_values => { '3' => 'Beta' },
                                 :parent_id => 1
                                }
        assert_redirected_to '/projects/blog/settings'
        
        project = Project.find_by_name('blog')
        assert_kind_of Project, project
        assert_equal Project.find(1), project.parent
      end
    end
    
    context "by non-admin user with add_project permission" do
      setup do
        Role.non_member.add_permission! :add_project
        @request.session[:user_id] = 9
      end
      
      should "accept get" do
        get :add
        assert_response :success
        assert_template 'add'
        assert_no_tag :select, :attributes => {:name => 'project[parent_id]'}
      end
      
      should "accept post" do
        post :add, :project => { :name => "blog", 
                                 :description => "weblog",
                                 :identifier => "blog",
                                 :is_public => 1,
                                 :custom_field_values => { '3' => 'Beta' }
                                }
        
        assert_redirected_to '/projects/blog/settings'
        
        project = Project.find_by_name('blog')
        assert_kind_of Project, project
        assert_equal 'weblog', project.description 
        assert_equal true, project.is_public?
        
        # User should be added as a project member
        assert User.find(9).member_of?(project)
        assert_equal 1, project.members.size
      end
      
      should "fail with parent_id" do
        assert_no_difference 'Project.count' do
          post :add, :project => { :name => "blog", 
                                   :description => "weblog",
                                   :identifier => "blog",
                                   :is_public => 1,
                                   :custom_field_values => { '3' => 'Beta' },
                                   :parent_id => 1
                                  }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        assert_not_nil project.errors.on(:parent_id)
      end
    end
    
    context "by non-admin user with add_subprojects permission" do
      setup do
        Role.find(1).remove_permission! :add_project
        Role.find(1).add_permission! :add_subprojects
        @request.session[:user_id] = 2
      end
      
      should "accept get" do
        get :add, :parent_id => 'ecookbook'
        assert_response :success
        assert_template 'add'
        # parent project selected
        assert_tag :select, :attributes => {:name => 'project[parent_id]'},
                            :child => {:tag => 'option', :attributes => {:value => '1', :selected => 'selected'}}
        # no empty value
        assert_no_tag :select, :attributes => {:name => 'project[parent_id]'},
                               :child => {:tag => 'option', :attributes => {:value => ''}}
      end
      
      should "accept post with parent_id" do
        post :add, :project => { :name => "blog", 
                                 :description => "weblog",
                                 :identifier => "blog",
                                 :is_public => 1,
                                 :custom_field_values => { '3' => 'Beta' },
                                 :parent_id => 1
                                }
        assert_redirected_to '/projects/blog/settings'
        project = Project.find_by_name('blog')
      end
      
      should "fail without parent_id" do
        assert_no_difference 'Project.count' do
          post :add, :project => { :name => "blog", 
                                   :description => "weblog",
                                   :identifier => "blog",
                                   :is_public => 1,
                                   :custom_field_values => { '3' => 'Beta' }
                                  }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        assert_not_nil project.errors.on(:parent_id)
      end
      
      should "fail with unauthorized parent_id" do
        assert !User.find(2).member_of?(Project.find(6))
        assert_no_difference 'Project.count' do
          post :add, :project => { :name => "blog", 
                                   :description => "weblog",
                                   :identifier => "blog",
                                   :is_public => 1,
                                   :custom_field_values => { '3' => 'Beta' },
                                   :parent_id => 6
                                  }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        assert_not_nil project.errors.on(:parent_id)
      end
    end
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
  
  def test_show_should_not_fail_when_custom_values_are_nil
    project = Project.find_by_identifier('ecookbook')
    project.custom_values.first.update_attribute(:value, nil)
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
    assert_redirected_to 'projects/ecookbook/settings'
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
  
  def test_add_file
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    Setting.notified_events = ['file_added']
    ActionMailer::Base.deliveries.clear
    
    assert_difference 'Attachment.count' do
      post :add_file, :id => 1, :version_id => '',
           :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    end
    assert_redirected_to 'projects/ecookbook/files'
    a = Attachment.find(:first, :order => 'created_on DESC')
    assert_equal 'testfile.txt', a.filename
    assert_equal Project.find(1), a.container

    mail = ActionMailer::Base.deliveries.last
    assert_kind_of TMail::Mail, mail
    assert_equal "[eCookbook] New file", mail.subject
    assert mail.body.include?('testfile.txt')
  end
  
  def test_add_version_file
    set_tmp_attachments_directory
    @request.session[:user_id] = 2
    Setting.notified_events = ['file_added']
    
    assert_difference 'Attachment.count' do
      post :add_file, :id => 1, :version_id => '2',
           :attachments => {'1' => {'file' => uploaded_test_file('testfile.txt', 'text/plain')}}
    end
    assert_redirected_to 'projects/ecookbook/files'
    a = Attachment.find(:first, :order => 'created_on DESC')
    assert_equal 'testfile.txt', a.filename
    assert_equal Version.find(2), a.container
  end
  
  def test_list_files
    get :list_files, :id => 1
    assert_response :success
    assert_template 'list_files'
    assert_not_nil assigns(:containers)
    
    # file attached to the project
    assert_tag :a, :content => 'project_file.zip',
                   :attributes => { :href => '/attachments/download/8/project_file.zip' }
    
    # file attached to a project's version
    assert_tag :a, :content => 'version_file.zip',
                   :attributes => { :href => '/attachments/download/9/version_file.zip' }
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

  def test_roadmap_showing_subprojects_versions
    @subproject_version = Version.generate!(:project => Project.find(3))
    get :roadmap, :id => 1, :with_subprojects => 1
    assert_response :success
    assert_template 'roadmap'
    assert_not_nil assigns(:versions)

    assert assigns(:versions).include?(Version.find(4)), "Shared version not found"
    assert assigns(:versions).include?(@subproject_version), "Subproject version not found"
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
  
  def test_user_activity
    get :activity, :user_id => 2
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
  
  def test_activity_atom_feed
    get :activity, :format => 'atom'
    assert_response :success
    assert_template 'common/feed.atom.rxml'
    assert_tag :tag => 'entry', :child => {
      :tag => 'link',
      :attributes => {:href => 'http://test.host/issues/11'}}
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
  
  def test_project_breadcrumbs_should_be_limited_to_3_ancestors
    CustomField.delete_all
    parent = nil
    6.times do |i|
      p = Project.create!(:name => "Breadcrumbs #{i}", :identifier => "breadcrumbs-#{i}")
      p.set_parent!(parent)
      get :show, :id => p
      assert_tag :h1, :parent => { :attributes => {:id => 'header'}},
                      :children => { :count => [i, 3].min,
                                     :only => { :tag => 'a' } }
                                     
      parent = p
    end
  end

  def test_copy_with_project
    @request.session[:user_id] = 1 # admin
    get :copy, :id => 1
    assert_response :success
    assert_template 'copy'
    assert assigns(:project)
    assert_equal Project.find(1).description, assigns(:project).description
    assert_nil assigns(:project).id
  end

  def test_copy_without_project
    @request.session[:user_id] = 1 # admin
    get :copy
    assert_response :redirect
    assert_redirected_to :controller => 'admin', :action => 'projects'
  end

  def test_jump_should_redirect_to_active_tab
    get :show, :id => 1, :jump => 'issues'
    assert_redirected_to 'projects/ecookbook/issues'
  end
  
  def test_jump_should_not_redirect_to_inactive_tab
    get :show, :id => 3, :jump => 'documents'
    assert_response :success
    assert_template 'show'
  end
  
  def test_jump_should_not_redirect_to_unknown_tab
    get :show, :id => 3, :jump => 'foobar'
    assert_response :success
    assert_template 'show'
  end

  def test_reset_activities
    @request.session[:user_id] = 2 # manager
    project_activity = TimeEntryActivity.new({
                                               :name => 'Project Specific',
                                               :parent => TimeEntryActivity.find(:first),
                                               :project => Project.find(1),
                                               :active => true
                                             })
    assert project_activity.save
    project_activity_two = TimeEntryActivity.new({
                                                   :name => 'Project Specific Two',
                                                   :parent => TimeEntryActivity.find(:last),
                                                   :project => Project.find(1),
                                                   :active => true
                                                 })
    assert project_activity_two.save

    delete :reset_activities, :id => 1
    assert_response :redirect
    assert_redirected_to 'projects/ecookbook/settings/activities'

    assert_nil TimeEntryActivity.find_by_id(project_activity.id)
    assert_nil TimeEntryActivity.find_by_id(project_activity_two.id)
  end
  
  def test_reset_activities_should_reassign_time_entries_back_to_the_system_activity
    @request.session[:user_id] = 2 # manager
    project_activity = TimeEntryActivity.new({
                                               :name => 'Project Specific Design',
                                               :parent => TimeEntryActivity.find(9),
                                               :project => Project.find(1),
                                               :active => true
                                             })
    assert project_activity.save
    assert TimeEntry.update_all("activity_id = '#{project_activity.id}'", ["project_id = ? AND activity_id = ?", 1, 9])
    assert 3, TimeEntry.find_all_by_activity_id_and_project_id(project_activity.id, 1).size
    
    delete :reset_activities, :id => 1
    assert_response :redirect
    assert_redirected_to 'projects/ecookbook/settings/activities'

    assert_nil TimeEntryActivity.find_by_id(project_activity.id)
    assert_equal 0, TimeEntry.find_all_by_activity_id_and_project_id(project_activity.id, 1).size, "TimeEntries still assigned to project specific activity"
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size, "TimeEntries still assigned to project specific activity"
  end
  
  def test_save_activities_to_override_system_activities
    @request.session[:user_id] = 2 # manager
    billable_field = TimeEntryActivityCustomField.find_by_name("Billable")

    post :save_activities, :id => 1, :enumerations => {
      "9"=> {"parent_id"=>"9", "custom_field_values"=>{"7" => "1"}, "active"=>"0"}, # Design, De-activate
      "10"=> {"parent_id"=>"10", "custom_field_values"=>{"7"=>"0"}, "active"=>"1"}, # Development, Change custom value
      "14"=>{"parent_id"=>"14", "custom_field_values"=>{"7"=>"1"}, "active"=>"1"}, # Inactive Activity, Activate with custom value
      "11"=>{"parent_id"=>"11", "custom_field_values"=>{"7"=>"1"}, "active"=>"1"} # QA, no changes
    }

    assert_response :redirect
    assert_redirected_to 'projects/ecookbook/settings/activities'

    # Created project specific activities...
    project = Project.find('ecookbook')

    # ... Design
    design = project.time_entry_activities.find_by_name("Design")
    assert design, "Project activity not found"

    assert_equal 9, design.parent_id # Relate to the system activity
    assert_not_equal design.parent.id, design.id # Different records
    assert_equal design.parent.name, design.name # Same name
    assert !design.active?

    # ... Development
    development = project.time_entry_activities.find_by_name("Development")
    assert development, "Project activity not found"

    assert_equal 10, development.parent_id # Relate to the system activity
    assert_not_equal development.parent.id, development.id # Different records
    assert_equal development.parent.name, development.name # Same name
    assert development.active?
    assert_equal "0", development.custom_value_for(billable_field).value

    # ... Inactive Activity
    previously_inactive = project.time_entry_activities.find_by_name("Inactive Activity")
    assert previously_inactive, "Project activity not found"

    assert_equal 14, previously_inactive.parent_id # Relate to the system activity
    assert_not_equal previously_inactive.parent.id, previously_inactive.id # Different records
    assert_equal previously_inactive.parent.name, previously_inactive.name # Same name
    assert previously_inactive.active?
    assert_equal "1", previously_inactive.custom_value_for(billable_field).value

    # ... QA
    assert_equal nil, project.time_entry_activities.find_by_name("QA"), "Custom QA activity created when it wasn't modified"
  end

  def test_save_activities_will_update_project_specific_activities
    @request.session[:user_id] = 2 # manager

    project_activity = TimeEntryActivity.new({
                                               :name => 'Project Specific',
                                               :parent => TimeEntryActivity.find(:first),
                                               :project => Project.find(1),
                                               :active => true
                                             })
    assert project_activity.save
    project_activity_two = TimeEntryActivity.new({
                                                   :name => 'Project Specific Two',
                                                   :parent => TimeEntryActivity.find(:last),
                                                   :project => Project.find(1),
                                                   :active => true
                                                 })
    assert project_activity_two.save

    
    post :save_activities, :id => 1, :enumerations => {
      project_activity.id => {"custom_field_values"=>{"7" => "1"}, "active"=>"0"}, # De-activate
      project_activity_two.id => {"custom_field_values"=>{"7" => "1"}, "active"=>"0"} # De-activate
    }

    assert_response :redirect
    assert_redirected_to 'projects/ecookbook/settings/activities'

    # Created project specific activities...
    project = Project.find('ecookbook')
    assert_equal 2, project.time_entry_activities.count

    activity_one = project.time_entry_activities.find_by_name(project_activity.name)
    assert activity_one, "Project activity not found"
    assert_equal project_activity.id, activity_one.id
    assert !activity_one.active?

    activity_two = project.time_entry_activities.find_by_name(project_activity_two.name)
    assert activity_two, "Project activity not found"
    assert_equal project_activity_two.id, activity_two.id
    assert !activity_two.active?
  end

  def test_save_activities_when_creating_new_activities_will_convert_existing_data
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size
    
    @request.session[:user_id] = 2 # manager
    post :save_activities, :id => 1, :enumerations => {
      "9"=> {"parent_id"=>"9", "custom_field_values"=>{"7" => "1"}, "active"=>"0"} # Design, De-activate
    }
    assert_response :redirect

    # No more TimeEntries using the system activity
    assert_equal 0, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size, "Time Entries still assigned to system activities"
    # All TimeEntries using project activity
    project_specific_activity = TimeEntryActivity.find_by_parent_id_and_project_id(9, 1)
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(project_specific_activity.id, 1).size, "No Time Entries assigned to the project activity"
  end

  def test_save_activities_when_creating_new_activities_will_not_convert_existing_data_if_an_exception_is_raised
    # TODO: Need to cause an exception on create but these tests
    # aren't setup for mocking.  Just create a record now so the
    # second one is a dupicate
    parent = TimeEntryActivity.find(9)
    TimeEntryActivity.create!({:name => parent.name, :project_id => 1, :position => parent.position, :active => true})
    TimeEntry.create!({:project_id => 1, :hours => 1.0, :user => User.find(1), :issue_id => 3, :activity_id => 10, :spent_on => '2009-01-01'})

    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size
    assert_equal 1, TimeEntry.find_all_by_activity_id_and_project_id(10, 1).size
    
    @request.session[:user_id] = 2 # manager
    post :save_activities, :id => 1, :enumerations => {
      "9"=> {"parent_id"=>"9", "custom_field_values"=>{"7" => "1"}, "active"=>"0"}, # Design
      "10"=> {"parent_id"=>"10", "custom_field_values"=>{"7"=>"0"}, "active"=>"1"} # Development, Change custom value
    }
    assert_response :redirect

    # TimeEntries shouldn't have been reassigned on the failed record
    assert_equal 3, TimeEntry.find_all_by_activity_id_and_project_id(9, 1).size, "Time Entries are not assigned to system activities"
    # TimeEntries shouldn't have been reassigned on the saved record either
    assert_equal 1, TimeEntry.find_all_by_activity_id_and_project_id(10, 1).size, "Time Entries are not assigned to system activities"
  end

  # A hook that is manually registered later
  class ProjectBasedTemplate < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context)
      # Adds a project stylesheet
      stylesheet_link_tag(context[:project].identifier) if context[:project]
    end
  end
  # Don't use this hook now
  Redmine::Hook.clear_listeners
  
  def test_hook_response
    Redmine::Hook.add_listener(ProjectBasedTemplate)
    get :show, :id => 1
    assert_tag :tag => 'link', :attributes => {:href => '/stylesheets/ecookbook.css'},
                               :parent => {:tag => 'head'}
    
    Redmine::Hook.clear_listeners
  end
end
