#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require 'roles_controller'

# Re-raise errors caught by the controller.
class RolesController; def rescue_action(e) raise e end; end

class RolesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = RolesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_get_index
    get :index
    assert_response :success
    assert_template 'index'

    assert_not_nil assigns(:roles)
    assert_equal Role.find(:all, order: 'builtin, position'), assigns(:roles)

    assert_tag tag: 'a', attributes: { href: edit_role_path(1) },
                            content: 'Manager'
  end

  def test_get_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_post_new_with_validaton_failure
    post :create, role: { name: '',
                             permissions: ['add_work_packages', 'edit_work_packages', 'log_time', ''],
                             assignable: '0' }

    assert_response :success
    assert_template 'new'
    assert_tag tag: 'div', attributes: { id: 'errorExplanation' }
  end

  def test_post_new_without_workflow_copy
    post :create, role: { name: 'RoleWithoutWorkflowCopy',
                             permissions: ['add_work_packages', 'edit_work_packages', 'log_time', ''],
                             assignable: '0' }

    assert_redirected_to roles_path
    role = Role.find_by_name('RoleWithoutWorkflowCopy')
    assert_not_nil role
    assert_equal [:add_work_packages, :edit_work_packages, :log_time], role.permissions
    assert !role.assignable?
  end

  def test_post_new_with_workflow_copy
    post :create, role: { name: 'RoleWithWorkflowCopy',
                             permissions: ['add_work_packages', 'edit_work_packages', 'log_time', ''],
                             assignable: '0' },
                  copy_workflow_from: '1'

    assert_redirected_to roles_path
    role = Role.find_by_name('RoleWithWorkflowCopy')
    assert_not_nil role
    assert_equal Role.find(1).workflows.size, role.workflows.size
  end

  def test_get_edit
    get :edit, id: 1
    assert_response :success
    assert_template 'edit'
    assert_equal Role.find(1), assigns(:role)
  end

  def test_put_update
    put :update, id: 1,
                 role: {name: 'Manager',
                           permissions: ['edit_project', ''],
                           assignable: '0'}

    assert_redirected_to roles_path
    role = Role.find(1)
    assert_equal [:edit_project], role.permissions
  end

  def test_destroy
    r = Role.new(name: 'ToBeDestroyed', permissions: [:view_wiki_pages])
    assert r.save

    delete :destroy, id: r
    assert_redirected_to roles_path
    assert_nil Role.find_by_id(r.id)
  end

  def test_destroy_role_in_use
    delete :destroy, id: 1
    assert_redirected_to roles_path
    assert flash[:error] == 'This role is in use and cannot be deleted.'
    assert_not_nil Role.find_by_id(1)
  end

  def test_get_report
    get :report
    assert_response :success
    assert_template 'report'

    assert_not_nil assigns(:roles)
    assert_equal Role.find(:all, order: 'builtin, position'), assigns(:roles)

    assert_tag tag: 'input', attributes: { type: 'checkbox',
                                                 name: 'permissions[3][]',
                                                 value: 'add_work_packages',
                                                 checked: 'checked' }

    assert_tag tag: 'input', attributes: { type: 'checkbox',
                                                 name: 'permissions[3][]',
                                                 value: 'delete_work_packages',
                                                 checked: nil }
  end

  def test_put_bulk_update
    put :bulk_update, permissions: { '0' => '', '1' => ['edit_work_packages'], '3' => ['add_work_packages', 'delete_work_packages']}
    assert_redirected_to roles_path

    assert_equal [:edit_work_packages], Role.find(1).permissions
    assert_equal [:add_work_packages, :delete_work_packages], Role.find(3).permissions
    assert Role.find(2).permissions.empty?
  end

  def test_clear_all_permissions
    put :bulk_update, permissions: { '0' => '' }
    assert_redirected_to roles_path
    assert Role.find(1).permissions.empty?
  end

  def test_move_highest
    put :update, id: 3, role: {move_to: 'highest'}
    assert_redirected_to roles_path
    assert_equal 1, Role.find(3).position
  end

  def test_move_higher
    position = Role.find(3).position
    put :update, id: 3, role: {move_to: 'higher'}
    assert_redirected_to roles_path
    assert_equal position - 1, Role.find(3).position
  end

  def test_move_lower
    position = Role.find(2).position
    put :update, id: 2, role: {move_to: 'lower'}
    assert_redirected_to roles_path
    assert_equal position + 1, Role.find(2).position
  end

  def test_move_lowest
    put :update, id: 2, role: {move_to: 'lowest'}
    assert_redirected_to roles_path
    assert_equal Role.count, Role.find(2).position
  end
end
