#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
require 'statuses_controller'

# Re-raise errors caught by the controller.
class StatusesController; def rescue_action(e) raise e end; end


class StatusesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = StatusesController.new
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

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_create
    assert_difference 'Status.count' do
      post :create, :status => {:name => 'New status'}
    end
    assert_redirected_to :action => 'index'
    status = Status.find(:first, :order => 'id DESC')
    assert_equal 'New status', status.name
  end

  def test_edit
    get :edit, :id => '3'
    assert_response :success
    assert_template 'edit'
  end

  def test_update
    post :update, :id => '3', :status => {:name => 'Renamed status'}
    assert_redirected_to :action => 'index'
    status = Status.find(3)
    assert_equal 'Renamed status', status.name
  end

  def test_destroy
    WorkPackage.delete_all("status_id = 1")

    assert_difference 'Status.count', -1 do
      post :destroy, :id => '1'
    end
    assert_redirected_to :action => 'index'
    assert_nil Status.find_by_id(1)
  end

  def test_destroy_should_block_if_status_in_use
    assert_not_nil WorkPackage.find_by_status_id(1)

    assert_no_difference 'Status.count' do
      post :destroy, :id => '1'
    end
    assert_redirected_to :action => 'index'
    assert_not_nil Status.find_by_id(1)
  end

  context "on POST to :update_work_package_done_ratio" do
    context "with Setting.work_package_done_ratio using the issue_field" do
      setup do
        Setting.work_package_done_ratio = 'issue_field'
        post :update_work_package_done_ratio
      end

      should set_the_flash.to /not updated/
      should redirect_to('the index') { '/statuses' }
    end

    context "with Setting.work_package_done_ratio using the status" do
      setup do
        Setting.work_package_done_ratio = 'status'
        post :update_work_package_done_ratio
      end

      should set_the_flash.to /Work package done ratios updated/
      should redirect_to('the index') { '/statuses' }
    end
  end

end
