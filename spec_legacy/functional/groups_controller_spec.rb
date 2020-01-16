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
require 'groups_controller'

describe GroupsController, type: :controller do
  fixtures :all

  before do
    User.current = nil
    session[:user_id] = 1
  end

  it 'should index' do
    get :index
    assert_response :success
    assert_template 'index'
  end

  it 'should show' do
    get :show, params: { id: 10 }
    assert_response :success
    assert_template 'show'
  end

  it 'should new' do
    get :new
    assert_response :success
    assert_template 'new'
  end

  it 'should create' do
    assert_difference 'Group.count' do
      post :create, params: { group: { lastname: 'New group' } }
    end
    assert_redirected_to groups_path
  end

  it 'should edit' do
    get :edit, params: { id: 10 }
    assert_response :success
    assert_template 'edit'
  end

  it 'should update' do
    put :update, params: { id: 10, group: { lastname: 'new name' } }
    assert_redirected_to groups_path
  end

  it 'should destroy' do
    assert_difference 'Group.count', -1 do
      delete :destroy, params: { id: 10 }
    end
    assert_redirected_to groups_path
  end

  it 'should add users' do
    assert_difference 'Group.find(10).users.count', 2 do
      post :add_users, params: { id: 10, user_ids: ['2', '3'] }
    end
  end

  it 'should remove user' do
    assert_difference 'Group.find(10).users.count', -1 do
      delete :remove_user, params: { id: 10, user_id: '8' }
    end
  end

  it 'should create membership' do
    assert_difference 'Group.find(10).members.count' do
      post :create_memberships, params: { id: 10, new_membership: { project_id: 2, role_ids: ['1', '2'] } }
    end
  end

  it 'should edit membership' do
    assert_no_difference 'Group.find(10).members.count' do
      put :edit_membership, params: { id: 10, membership_id: 6, membership: { role_ids: ['1', '3'] } }
    end
  end

  it 'should destroy membership' do
    assert_difference 'Group.find(10).members.count', -1 do
      delete :destroy_membership, params: { id: 10, membership_id: 6 }
    end
  end
end
