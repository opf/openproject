#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
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

  context '#new' do
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
        project = Project.find_by(identifier: 'ecookbook')
        get :new, params: { parent_id: project.id }
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
                 public: 1,
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
        assert_equal true, project.public?
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
                 public: 1,
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
                 public: 1,
                 custom_field_values: { '3' => '5' },
                 type_ids: ['1', '3'],
                 enabled_module_names: ['work_package_tracking', 'news', 'repository']
               }
             }

        assert_redirected_to '/projects/blog/work_packages'

        project = Project.find_by(name: 'blog')
        assert_kind_of Project, project
        assert_equal 'weblog', project.description
        assert_equal true, project.public?
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
                   public: 1,
                   custom_field_values: { '3' => '5' },
                   parent_id: 1
                 }
               }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        errors = assigns(:errors)
        refute_empty errors[:parent]
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
                 public: 1,
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
                   public: 1,
                   custom_field_values: { '3' => '5' }
                 }
               }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        errors = assigns(:errors)
        expect(errors.symbols_for(:base))
          .to match_array [:error_unauthorized]
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
                   public: 1,
                   custom_field_values: { '3' => '5' },
                   parent_id: 6
                 }
               }
        end
        assert_response :success
        project = assigns(:project)
        assert_kind_of Project, project
        errors = assigns(:errors)
        refute_empty errors[:parent]
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
    assert_redirected_to '/projects/ecookbook/settings/generic'
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

  it 'should archive' do
    session[:user_id] = 1 # admin
    put :archive, params: { id: 1 }
    assert_redirected_to '/projects'
    assert Project.find(1).archived?
  end

  it 'should unarchive' do
    session[:user_id] = 1 # admin
    Project.find(1).update(active: false)
    put :unarchive, params: { id: 1 }
    assert_redirected_to '/projects'
    assert Project.find(1).active?
  end
end
