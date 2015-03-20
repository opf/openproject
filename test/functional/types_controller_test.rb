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
require 'types_controller'

# Re-raise errors caught by the controller.
class TypesController; def rescue_action(e) raise e end; end

class TypesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = TypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_get_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_post_create
    post :create, type: { name: 'New type', project_ids: ['1', '', ''], custom_field_ids: ['1', '6', ''] }
    assert_redirected_to action: 'index'
    type = Type.find_by_name('New type')
    assert_equal [1], type.project_ids.sort
    assert_equal [1, 6], type.custom_field_ids
    assert_equal 0, type.workflows.count
  end

  def test_post_create_with_workflow_copy
    post :create, type: { name: 'New type' }, copy_workflow_from: 1
    assert_redirected_to action: 'index'
    type = Type.find_by_name('New type')
    assert_equal 0, type.projects.count
    assert_equal Type.find(1).workflows.count, type.workflows.count
  end

  def test_get_edit
    Type.find(1).project_ids = [1, 3]

    get :edit, id: 1
    assert_response :success
    assert_template 'edit'

    assert_tag :input, attributes: { name: 'type[project_ids][]',
                                     value: '1',
                                     checked: 'checked' }

    assert_tag :input, attributes: { name: 'type[project_ids][]',
                                     value: '2',
                                     checked: nil }

    assert_tag :input, attributes: { name: 'type[project_ids][]',
                                     value: '',
                                     type: 'hidden' }
  end

  def test_post_update
    post :update, id: 1, type: { name: 'Renamed',
                                 project_ids: ['1', '2', ''] }
    assert_redirected_to action: 'index'
    assert_equal [1, 2], Type.find(1).project_ids.sort
  end

  def test_post_update_without_projects
    post :update, id: 1, type: { name: 'Renamed',
                                 project_ids: [''] }
    assert_redirected_to action: 'index'
    assert Type.find(1).project_ids.empty?
  end

  def test_move_lower
    type = Type.find_by_position(1)
    post :move, id: 1, type: { move_to: 'lower' }
    assert_equal 2, type.reload.position
  end

  def test_destroy
    type = Type.create!(name: 'Destroyable')
    assert_difference 'Type.count', -1 do
      post :destroy, id: type.id
    end
    assert_redirected_to action: 'index'
    assert_nil flash[:error]
  end

  def test_destroy_type_in_use
    assert_no_difference 'Type.count' do
      post :destroy, id: 1
    end
    assert_redirected_to action: 'index'
    assert_not_nil flash[:error]
  end
end
