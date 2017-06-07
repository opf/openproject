#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
require_relative '../legacy_spec_helper'
require 'projects_controller'

describe ProjectsController, type: :controller do
  include MiniTest::Assertions # refute

  render_views

  fixtures :all

  before do
    session[:user_id] = nil
    Setting.default_language = 'en'
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:projects)

    assert_select 'ul',
                  child: {
                    tag: 'li',
                    descendant: { tag: 'a', content: 'eCookbook' },
                    child: {
                      tag: 'ul',
                      descendant: {
                        tag: 'a',
                        content: 'Child of private child'
                      }
                    }
                  }

    assert_select('a', { content: /Private child of eCookbook/ }, false)
  end

  it 'should index atom' do
    get :index, format: 'atom'
    assert_response :success
    assert_template 'common/feed'
    assert_select 'feed>title', text: 'OpenProject: Latest projects'
    assert_select 'feed>entry', count: Project.visible(User.current).count
  end

  context '#index' do
    context 'by non-admin user without view_time_entries permission' do
      before do
        Role.find(2).remove_permission! :view_time_entries
        Role.non_member.remove_permission! :view_time_entries
        Role.anonymous.remove_permission! :view_time_entries
        session[:user_id] = 3
      end
      it 'should not show overall spent time link' do
        get :index
        assert_template 'index'
        assert_select('a', { attributes: { href: '/time_entries' } }, false)
      end
    end
  end

  context '#new' do
    context 'by admin user' do
      before do
        session[:user_id] = 1
      end

      it 'should accept get' do
        get :new
        assert_response :success
        assert_template 'new'
      end
    end

    context 'by non-admin user with add_project permission' do
      before do
        Role.non_member.add_permission! :add_project
        session[:user_id] = 9
      end

      it 'should accept get' do
        get :new
        assert_response :success
        assert_template 'new'
        assert_select('select', { attributes: { name: 'project[parent_id]' } }, false)
      end
    end

    context 'by non-admin user with add_subprojects permission' do
      before do
        Role.find(1).remove_permission! :add_project
        Role.find(1).add_permission! :add_subprojects
        session[:user_id] = 2
      end

      it 'should accept get' do
        get :new, params: { parent_id: 'ecookbook' }
        assert_response :success
        assert_template 'new'
        # parent project selected
        assert_select 'select',
                      attributes: { name: 'project[parent_id]' },
                      child: { tag: 'option', attributes: { value: '1', selected: 'selected' } }
        # no empty value
        assert_select('select',
                      {
                        attributes: { name: 'project[parent_id]' },
                        child: { tag: 'option', attributes: { value: '' } }
                      },
                      false)
      end
    end
  end

  context 'POST :create' do
    context 'by admin user' do
      before do
        session[:user_id] = 1
      end

      it 'should create a new project' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 is_public: 1,
                 custom_field_values: { '3': '5' },
                 type_ids: ['1', '3'],
                 # an issue custom field that is not for all project
                 work_package_custom_field_ids: ['9'],
                 enabled_module_names: ['work_package_tracking', 'news', 'repository']
               }
             }
        assert_redirected_to '/projects/blog/work_packages'

        project = Project.find_by(name: 'blog')
        assert_kind_of Project, project
        assert project.active?
        assert_equal 'weblog', project.description
        assert_equal true, project.is_public?
        assert_nil project.parent
        assert_equal 'Beta', project.custom_value_for(3).typed_value
        assert_equal [1, 3], project.types.map(&:id).sort
        assert_equal ['news', 'repository', 'work_package_tracking'], project.enabled_module_names.sort
        assert project.work_package_custom_fields.include?(WorkPackageCustomField.find(9))
      end

      it 'should create a new subproject' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 is_public: 1,
                 custom_field_values: { '3' => '5' },
                 parent_id: 1
               }
             }
        assert_redirected_to '/projects/blog/work_packages'

        project = Project.find_by(name: 'blog')
        assert_kind_of Project, project
        assert_equal Project.find(1), project.parent
      end
    end

    context 'by non-admin user with add_project permission' do
      before do
        Role.non_member.add_permission! :add_project
        session[:user_id] = 9
      end

      it 'should accept create a Project' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 is_public: 1,
                 custom_field_values: { '3' => '5' },
                 type_ids: ['1', '3'],
                 enabled_module_names: ['work_package_tracking', 'news', 'repository']
               }
             }

        assert_redirected_to '/projects/blog/work_packages'

        project = Project.find_by(name: 'blog')
        assert_kind_of Project, project
        assert_equal 'weblog', project.description
        assert_equal true, project.is_public?
        assert_equal [1, 3], project.types.map(&:id).sort
        assert_equal ['news', 'repository', 'work_package_tracking'], project.enabled_module_names.sort

        # User should be added as a project member
        assert User.find(9).member_of?(project)
        assert_equal 1, project.members.size
      end

      it 'should fail with parent_id' do
        assert_no_difference 'Project.count' do
          post :create,
               params: {
                 project: {
                   name: 'blog',
                   description: 'weblog',
                   identifier: 'blog',
                   is_public: 1,
                   custom_field_values: { '3' => '5' },
                   parent_id: 1
                 }
               }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        refute_empty project.errors[:parent_id]
      end
    end

    context 'by non-admin user with add_subprojects permission' do
      before do
        Role.find(1).remove_permission! :add_project
        Role.find(1).add_permission! :add_subprojects
        session[:user_id] = 2
      end

      it 'should create a project with a parent_id' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 description: 'weblog',
                 identifier: 'blog',
                 is_public: 1,
                 custom_field_values: { '3' => '5' },
                 parent_id: 1
               }
             }
        assert_redirected_to '/projects/blog/work_packages'
      end

      it 'should fail without parent_id' do
        assert_no_difference 'Project.count' do
          post :create,
               params: {
                 project: {
                   name: 'blog',
                   description: 'weblog',
                   identifier: 'blog',
                   is_public: 1,
                   custom_field_values: { '3' => '5' }
                 }
               }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        refute_empty project.errors[:parent_id]
      end

      it 'should fail with unauthorized parent_id' do
        assert !User.find(2).member_of?(Project.find(6))
        assert_no_difference 'Project.count' do
          post :create,
               params: {
                 project: {
                   name: 'blog',
                   description: 'weblog',
                   identifier: 'blog',
                   is_public: 1,
                   custom_field_values: { '3' => '5' },
                   parent_id: 6
                 }
               }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        refute_empty project.errors[:parent_id]
      end
    end
  end

  context 'with default modules',
          with_settings: { default_projects_modules: %w(work_package_tracking repository) } do
    it 'should create should preserve modules on validation failure' do
      session[:user_id] = 1
      assert_no_difference 'Project.count' do
        post :create,
             params: {
               project: {
                 name: 'blog',
                 identifier: '',
                 enabled_module_names: %w(work_package_tracking news)
               }
             }
      end
      assert_response :success
      project = assigns(:project)
      assert_equal %w(news work_package_tracking), project.enabled_module_names.sort
    end
  end

  it 'should show by id' do
    get :show, params: { id: 1 }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:project)
  end

  it 'should show by identifier' do
    get :show, params: { id: 'ecookbook' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:project)
    assert_equal Project.find_by(identifier: 'ecookbook'), assigns(:project)

    assert_select 'li', content: /Development status/
  end

  it 'should show should not display hidden custom fields' do
    ProjectCustomField.find_by(name: 'Development status').update_attribute :visible, false
    get :show, params: { id: 'ecookbook' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:project)

    assert_select('li', { content: /Development status/ }, false)
  end

  it 'should show should not fail when custom values are nil' do
    project = Project.find_by(identifier: 'ecookbook')
    project.custom_values.first.update_attribute(:value, nil)
    get :show, params: { id: 'ecookbook' }
    assert_response :success
    assert_template 'show'
    refute_nil assigns(:project)
    assert_equal Project.find_by(identifier: 'ecookbook'), assigns(:project)
  end

  def show_archived_project_should_be_denied
    project = Project.find_by(identifier: 'ecookbook')
    project.archive!

    get :show, params: { id: 'ecookbook' }
    assert_response 403
    assert_nil assigns(:project)
    assert_select 'p', content: /archived/
  end

  it 'should private subprojects hidden' do
    get :show, params: { id: 'ecookbook' }
    assert_response :success
    assert_template 'show'
    assert_select('a', { content: /Private child/ }, false)
  end

  it 'should private subprojects visible' do
    session[:user_id] = 2 # manager who is a member of the private subproject
    get :show, params: { id: 'ecookbook' }
    assert_response :success
    assert_template 'show'
    assert_select 'a', content: /Private child/
  end

  it 'should settings' do
    session[:user_id] = 2 # manager
    get :settings, params: { id: 1 }
    assert_response :success
    assert_template 'settings'
  end

  it 'should update' do
    session[:user_id] = 2 # manager
    put :update,
        params: {
          id: 1,
          project: {
            name: 'Test changed name',
            issue_custom_field_ids: ['']
          }
        }
    assert_redirected_to '/projects/ecookbook/settings'
    project = Project.find(1)
    assert_equal 'Test changed name', project.name
  end

  it 'should modules' do
    session[:user_id] = 2
    Project.find(1).enabled_module_names = ['work_package_tracking', 'news']

    put :modules, params: { id: 1, project: { enabled_module_names: ['work_package_tracking', 'repository'] } }
    assert_redirected_to '/projects/ecookbook/settings/modules'
    assert_equal ['repository', 'work_package_tracking'], Project.find(1).enabled_module_names.sort
  end

  it 'should get destroy info' do
    session[:user_id] = 1 # admin
    get :destroy_info, params: { id: 1 }
    assert_response :success
    assert_template 'destroy_info'
    refute_nil Project.find_by(id: 1)
  end

  it 'should post destroy' do
    session[:user_id] = 1 # admin
    delete :destroy, params: { id: 1, confirm: 1 }
    assert_redirected_to '/admin/projects'
    assert_nil Project.find_by(id: 1)
  end

  it 'should archive' do
    session[:user_id] = 1 # admin
    put :archive, params: { id: 1 }
    assert_redirected_to '/admin/projects'
    assert !Project.find(1).active?
  end

  it 'should unarchive' do
    session[:user_id] = 1 # admin
    Project.find(1).archive
    put :unarchive, params: { id: 1 }
    assert_redirected_to '/admin/projects'
    assert Project.find(1).active?
  end

  it 'should jump should redirect to active tab' do
    get :show, params: { id: 1, jump: 'work_packages' }
    assert_redirected_to controller: :work_packages, action: :index, project_id: 'ecookbook'
  end

  it 'should jump should not redirect to inactive tab' do
    get :show, params: { id: 3, jump: 'news' }
    assert_response :success
    assert_template 'show'
  end

  it 'should jump should not redirect to unknown tab' do
    get :show, params: { id: 3, jump: 'foobar' }
    assert_response :success
    assert_template 'show'
  end

  context 'with hooks' do
    # A hook that is manually registered later
    class ProjectBasedTemplate < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context)
        context[:controller].send(:render, html: '<p id="hookselector">Hello from hook!</p>'.html_safe)
      end
    end

    before do
      # Don't use this hook now
      Redmine::Hook.clear_listeners
    end

    after do
      Redmine::Hook.clear_listeners
    end

    it 'should hook response' do
      Redmine::Hook.add_listener(ProjectBasedTemplate)
      get :show, params: { id: 1 }
      assert_select('p#hookselector')
    end
  end
end
