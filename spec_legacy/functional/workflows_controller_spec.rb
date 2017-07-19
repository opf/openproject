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
require 'workflows_controller'

describe WorkflowsController, type: :controller do
  render_views

  fixtures :all

  before do
    User.current = nil
    session[:user_id] = 1 # admin
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'

    count = Workflow.where('role_id = 1 AND type_id = 2').count
    assert_select 'a', content: count.to_s,
                       attributes: { href: '/workflows/edit?role_id=1&amp;type_id=2' }
  end

  it 'should get edit' do
    get :edit
    assert_response :success
    assert_template 'edit'
    refute_nil assigns(:roles)
    refute_nil assigns(:types)
  end

  it 'should get edit with role and type' do
    Workflow.delete_all
    Workflow.create!(role_id: 1, type_id: 1, old_status_id: 2, new_status_id: 3)
    Workflow.create!(role_id: 2, type_id: 1, old_status_id: 3, new_status_id: 5)

    get :edit, params: { role_id: 2, type_id: 1 }
    assert_response :success
    assert_template 'edit'

    # used status only
    refute_nil assigns(:statuses)
    assert_equal [2, 3, 5], assigns(:statuses).map(&:id)

    # allowed transitions
    assert_select 'input', attributes: { type: 'checkbox',
                                         name: 'status[3][5][]',
                                         value: 'always',
                                         checked: 'checked' }
    # not allowed
    assert_select 'input', attributes: { type: 'checkbox',
                                         name: 'status[3][2][]',
                                         value: 'always',
                                         checked: nil }
    # unused
    assert_select('input', { attributes: { type: 'checkbox',
                                           name: 'status[1][1][]' } }, false)
  end

  it 'should get edit with role and type and all statuses' do
    Workflow.delete_all

    get :edit, params: { role_id: 2, type_id: 1, used_statuses_only: '0' }
    assert_response :success
    assert_template 'edit'

    refute_nil assigns(:statuses)
    assert_equal Status.count, assigns(:statuses).size

    assert_select 'input', attributes: { type: 'checkbox',
                                         name: 'status[1][1][]',
                                         value: 'always',
                                         checked: nil }
  end

  it 'should post edit' do
    post :edit, params: { role_id: 2, type_id: 1,
                          status: {
                            '4' => { '5' => ['always'] },
                            '3' => { '1' => ['always'], '2' => ['always'] }
                          } }
    assert_redirected_to '/workflows/edit?role_id=2&type_id=1'

    assert_equal 3, Workflow.where(type_id: 1, role_id: 2).count
    refute_nil Workflow.where(role_id: 2, type_id: 1, old_status_id: 3, new_status_id: 2).first
    assert_nil Workflow.where(role_id: 2, type_id: 1, old_status_id: 5, new_status_id: 4).first
  end

  it 'should post edit with additional transitions' do
    post :edit, params: { role_id: 2, type_id: 1,
                          status: {
                            '4' => { '5' => ['always'] },
                            '3' => { '1' => ['author'], '2' => ['assignee'], '4' => ['author', 'assignee'] }
                          } }
    assert_redirected_to '/workflows/edit?role_id=2&type_id=1'

    assert_equal 4, Workflow.where(type_id: 1, role_id: 2).count

    w = Workflow.where(role_id: 2, type_id: 1, old_status_id: 4, new_status_id: 5).first
    assert !w.author
    assert !w.assignee
    w = Workflow.where(role_id: 2, type_id: 1, old_status_id: 3, new_status_id: 1).first
    assert w.author
    assert !w.assignee
    w = Workflow.where(role_id: 2, type_id: 1, old_status_id: 3, new_status_id: 2).first
    assert !w.author
    assert w.assignee
    w = Workflow.where(role_id: 2, type_id: 1, old_status_id: 3, new_status_id: 4).first
    assert w.author
    assert w.assignee
  end

  it 'should clear workflow' do
    assert Workflow.where(type_id: 1, role_id: 2).count > 0

    post :edit, params: { role_id: 2, type_id: 1 }
    assert_equal 0, Workflow.where(type_id: 1, role_id: 2).count
  end

  it 'should get copy' do
    get :copy
    assert_response :success
    assert_template 'copy'
  end

  it 'should post copy one to one' do
    source_transitions = status_transitions(type_id: 1, role_id: 2)

    post :copy, params: { source_type_id: '1', source_role_id: '2',
                          target_type_ids: ['3'], target_role_ids: ['1'] }
    assert_response 302
    assert_equal source_transitions, status_transitions(type_id: 3, role_id: 1)
  end

  it 'should post copy one to many' do
    source_transitions = status_transitions(type_id: 1, role_id: 2)

    post :copy, params: { source_type_id: '1', source_role_id: '2',
                          target_type_ids: ['2', '3'], target_role_ids: ['1', '3'] }
    assert_response 302
    assert_equal source_transitions, status_transitions(type_id: 2, role_id: 1)
    assert_equal source_transitions, status_transitions(type_id: 3, role_id: 1)
    assert_equal source_transitions, status_transitions(type_id: 2, role_id: 3)
    assert_equal source_transitions, status_transitions(type_id: 3, role_id: 3)
  end

  it 'should post copy many to many' do
    source_t2 = status_transitions(type_id: 2, role_id: 2)
    source_t3 = status_transitions(type_id: 3, role_id: 2)

    post :copy, params: { source_type_id: 'any', source_role_id: '2',
                          target_type_ids: ['2', '3'], target_role_ids: ['1', '3'] }
    assert_response 302
    assert_equal source_t2, status_transitions(type_id: 2, role_id: 1)
    assert_equal source_t3, status_transitions(type_id: 3, role_id: 1)
    assert_equal source_t2, status_transitions(type_id: 2, role_id: 3)
    assert_equal source_t3, status_transitions(type_id: 3, role_id: 3)
  end

  # Returns an array of status transitions that can be compared
  def status_transitions(conditions)
    Workflow
      .where(conditions)
      .order('type_id, role_id, old_status_id, new_status_id')
      .map { |w| [w.old_status, w.new_status_id] }
  end
end
