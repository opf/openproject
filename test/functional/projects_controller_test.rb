#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < ActionController::TestCase
  include MiniTest::Assertions # refute

  fixtures :all

  def setup
    super
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
    assert_template 'common/feed'
    assert_select 'feed>title', :text => 'OpenProject: Latest projects'
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

  context "#new" do
    context "by admin user" do
      setup do
        @request.session[:user_id] = 1
      end

      should "accept get" do
        get :new
        assert_response :success
        assert_template 'new'
      end

    end

    context "by non-admin user with add_project permission" do
      setup do
        Role.non_member.add_permission! :add_project
        @request.session[:user_id] = 9
      end

      should "accept get" do
        get :new
        assert_response :success
        assert_template 'new'
        assert_no_tag :select, :attributes => {:name => 'project[parent_id]'}
      end
    end

    context "by non-admin user with add_subprojects permission" do
      setup do
        Role.find(1).remove_permission! :add_project
        Role.find(1).add_permission! :add_subprojects
        @request.session[:user_id] = 2
      end

      should "accept get" do
        get :new, :parent_id => 'ecookbook'
        assert_response :success
        assert_template 'new'
        # parent project selected
        assert_tag :select, :attributes => {:name => 'project[parent_id]'},
                            :child => {:tag => 'option', :attributes => {:value => '1', :selected => 'selected'}}
        # no empty value
        assert_no_tag :select, :attributes => {:name => 'project[parent_id]'},
                               :child => {:tag => 'option', :attributes => {:value => ''}}
      end
    end

  end

  context "POST :create" do
    context "by admin user" do
      setup do
        @request.session[:user_id] = 1
      end

      should "create a new project" do
        post :create,
          :project => {
            :name => "blog",
            :description => "weblog",
            :homepage => 'http://weblog',
            :identifier => "blog",
            :is_public => 1,
            :custom_field_values => { '3' => 'Beta' },
            :type_ids => ['1', '3'],
            # an issue custom field that is not for all project
            :work_package_custom_field_ids => ['9'],
            :enabled_module_names => ['work_package_tracking', 'news', 'repository']
          }
        assert_redirected_to '/projects/blog/settings'

        project = Project.find_by_name('blog')
        assert_kind_of Project, project
        assert project.active?
        assert_equal 'weblog', project.description
        assert_equal 'http://weblog', project.homepage
        assert_equal true, project.is_public?
        assert_nil project.parent
        assert_equal 'Beta', project.custom_value_for(3).value
        assert_equal [1, 3], project.types.map(&:id).sort
        assert_equal ['news', 'repository', 'work_package_tracking'], project.enabled_module_names.sort
        assert project.work_package_custom_fields.include?(WorkPackageCustomField.find(9))
      end

      should "create a new subproject" do
        post :create, :project => { :name => "blog",
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

      should "accept create a Project" do
        post :create, :project => { :name => "blog",
                                 :description => "weblog",
                                 :identifier => "blog",
                                 :is_public => 1,
                                 :custom_field_values => { '3' => 'Beta' },
                                 :type_ids => ['1', '3'],
                                 :enabled_module_names => ['work_package_tracking', 'news', 'repository']
                                }

        assert_redirected_to '/projects/blog/settings'

        project = Project.find_by_name('blog')
        assert_kind_of Project, project
        assert_equal 'weblog', project.description
        assert_equal true, project.is_public?
        assert_equal [1, 3], project.types.map(&:id).sort
        assert_equal ['news', 'repository', 'work_package_tracking'], project.enabled_module_names.sort

        # User should be added as a project member
        assert User.find(9).member_of?(project)
        assert_equal 1, project.members.size
      end

      should "fail with parent_id" do
        assert_no_difference 'Project.count' do
          post :create, :project => { :name => "blog",
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
        refute_empty project.errors[:parent_id]
      end
    end

    context "by non-admin user with add_subprojects permission" do
      setup do
        Role.find(1).remove_permission! :add_project
        Role.find(1).add_permission! :add_subprojects
        @request.session[:user_id] = 2
      end

      should "create a project with a parent_id" do
        post :create, :project => { :name => "blog",
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
          post :create, :project => { :name => "blog",
                                   :description => "weblog",
                                   :identifier => "blog",
                                   :is_public => 1,
                                   :custom_field_values => { '3' => 'Beta' }
                                  }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        refute_empty project.errors[:parent_id]
      end

      should "fail with unauthorized parent_id" do
        assert !User.find(2).member_of?(Project.find(6))
        assert_no_difference 'Project.count' do
          post :create, :project => { :name => "blog",
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
        refute_empty project.errors[:parent_id]
      end
    end
  end

  def test_create_should_preserve_modules_on_validation_failure
    with_settings :default_projects_modules => ['work_package_tracking', 'repository'] do
      @request.session[:user_id] = 1
      assert_no_difference 'Project.count' do
        post :create, :project => {
          :name => "blog",
          :identifier => "",
          :enabled_module_names => %w(work_package_tracking news)
        }
      end
      assert_response :success
      project = assigns(:project)
      assert_equal %w(news work_package_tracking), project.enabled_module_names.sort
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

    assert_tag 'li', :content => /Development status/
  end

  def test_show_should_not_display_hidden_custom_fields
    ProjectCustomField.find_by_name('Development status').update_attribute :visible, false
    get :show, :id => 'ecookbook'
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:project)

    assert_no_tag 'li', :content => /Development status/
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

  def show_archived_project_should_be_denied
    project = Project.find_by_identifier('ecookbook')
    project.archive!

    get :show, :id => 'ecookbook'
    assert_response 403
    assert_nil assigns(:project)
    assert_tag :tag => 'p', :content => /archived/
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

  def test_update
    @request.session[:user_id] = 2 # manager
    put :update, :id => 1, :project => {:name => 'Test changed name',
                                       :issue_custom_field_ids => ['']}
    assert_redirected_to '/projects/ecookbook/settings'
    project = Project.find(1)
    assert_equal 'Test changed name', project.name
  end

  def test_modules
    @request.session[:user_id] = 2
    Project.find(1).enabled_module_names = ['work_package_tracking', 'news']

    put :modules, :id => 1, :enabled_module_names => ['work_package_tracking', 'repository']
    assert_redirected_to '/projects/ecookbook/settings/modules'
    assert_equal ['repository', 'work_package_tracking'], Project.find(1).enabled_module_names.sort
  end

  def test_get_destroy_info
    @request.session[:user_id] = 1 # admin
    get :destroy_info, :id => 1
    assert_response :success
    assert_template 'destroy_info'
    assert_not_nil Project.find_by_id(1)
  end

  def test_post_destroy
    @request.session[:user_id] = 1 # admin
    delete :destroy, :id => 1, :confirm => 1
    assert_redirected_to '/admin/projects'
    assert_nil Project.find_by_id(1)
  end

  def test_archive
    @request.session[:user_id] = 1 # admin
    put :archive, :id => 1
    assert_redirected_to '/admin/projects'
    assert !Project.find(1).active?
  end

  def test_unarchive
    @request.session[:user_id] = 1 # admin
    Project.find(1).archive
    put :unarchive, :id => 1
    assert_redirected_to '/admin/projects'
    assert Project.find(1).active?
  end

  def test_jump_should_redirect_to_active_tab
    get :show, :id => 1, :jump => 'work_packages'
    assert_redirected_to controller: :work_packages, action: :index, project_id: 'ecookbook'
  end

  def test_jump_should_not_redirect_to_inactive_tab
    get :show, :id => 3, :jump => 'news'
    assert_response :success
    assert_template 'show'
  end

  def test_jump_should_not_redirect_to_unknown_tab
    get :show, :id => 3, :jump => 'foobar'
    assert_response :success
    assert_template 'show'
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
    assert_tag :tag => 'link', :attributes => {:href => '/assets/ecookbook.css'},
                               :parent => {:tag => 'head'}

    Redmine::Hook.clear_listeners
  end
end
