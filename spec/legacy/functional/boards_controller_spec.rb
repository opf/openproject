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
require 'legacy_spec_helper'
require 'boards_controller'

describe BoardsController, type: :controller do
  fixtures :all

  before do
    User.current = nil
  end

  it 'should index' do
    get :index, project_id: 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:boards)
    assert_not_nil assigns(:project)
  end

  it 'should index not found' do
    get :index, project_id: 97
    assert_response 404
  end

  it 'should index should show messages if only one board' do
    Project.find(1).boards.slice(1..-1).each(&:destroy)

    get :index, project_id: 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:topics)
  end

  it 'should create' do
    session[:user_id] = 2
    assert_difference 'Board.count' do
      post :create, project_id: 1, board: { name: 'Testing', description: 'Testing board creation' }
    end
    assert_redirected_to '/projects/ecookbook/settings/boards'
  end

  it 'should show' do
    get :show, project_id: 1, id: 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:topics)
  end

  it 'should show atom' do
    get :show, project_id: 1, id: 1, format: 'atom'
    assert_response :success
    assert_template 'common/feed'
    assert_not_nil assigns(:board)
    assert_not_nil assigns(:project)
    assert_not_nil assigns(:messages)
  end

  it 'should update' do
    session[:user_id] = 2
    assert_no_difference 'Board.count' do
      put :update, project_id: 1, id: 2, board: { name: 'Testing', description: 'Testing board update' }
    end
    assert_redirected_to '/projects/ecookbook/settings/boards'
    assert_equal 'Testing', Board.find(2).name
  end

  it 'should post destroy' do
    session[:user_id] = 2
    assert_difference 'Board.count', -1 do
      post :destroy, project_id: 1, id: 2
    end
    assert_redirected_to '/projects/ecookbook/settings/boards'
    assert_nil Board.find_by_id(2)
  end

  it 'should index should 404 with no board' do
    Project.find(1).boards.each(&:destroy)

    get :index, project_id: 1
    assert_response 404
  end
end
