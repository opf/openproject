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
require 'watchers_controller'

# Re-raise errors caught by the controller.
class WatchersController; def rescue_action(e) raise e end; end

class WatchersControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = WatchersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
  end

  def test_watch
    @request.session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1'
      assert_response :success
      assert @response.body.include? "$$(\"#watcher\").each"
      assert @response.body.include? 'value.replace'
    end
    assert WorkPackage.find(1).watched_by?(User.find(3))
  end

  def test_watch_should_be_denied_without_permission
    Role.find(2).remove_permission! :view_work_packages
    @request.session[:user_id] = 3
    assert_no_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1'
      assert_response 403
    end
  end

  def test_watch_with_multiple_replacements
    @request.session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1', replace: ['#watch_item_1', '.watch_item_2']
      assert_response :success
      assert @response.body.include? "$$(\"#watch_item_1\").each"
      assert @response.body.include? "$$(\".watch_item_2\").each"
      assert @response.body.include? 'value.replace'
    end
  end

  def test_watch_with_watchers_special_logic
    @request.session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1', replace: ['#watchers', '.watcher']
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
      assert @response.body.include? "$$(\".watcher\").each"
      assert @response.body.include? 'value.replace'
    end
  end

  def test_unwatch
    @request.session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, object_type: 'work_package', object_id: '2'
      assert_response :success
      assert @response.body.include? "$$(\"#watcher\").each"
      assert @response.body.include? 'value.replace'
    end
    assert !WorkPackage.find(1).watched_by?(User.find(3))
  end

  def test_unwatch_with_multiple_replacements
    @request.session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, object_type: 'work_package', object_id: '2', replace: ['#watch_item_1', '.watch_item_2']
      assert_response :success
      assert @response.body.include? "$$(\"#watch_item_1\").each"
      assert @response.body.include? "$$(\".watch_item_2\").each"
      assert @response.body.include? 'value.replace'
    end
    assert !WorkPackage.find(1).watched_by?(User.find(3))
  end

  def test_unwatch_with_watchers_special_logic
    @request.session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, object_type: 'work_package', object_id: '2', replace: ['#watchers', '.watcher']
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
      assert @response.body.include? "$$(\".watcher\").each"
      assert @response.body.include? 'value.replace'
    end
    assert !WorkPackage.find(1).watched_by?(User.find(3))
  end

  def test_new_watcher
    Watcher.destroy_all
    @request.session[:user_id] = 2
    assert_difference('Watcher.count') do
      xhr :post, :new, object_type: 'work_package', object_id: '2', watcher: { user_id: '3' }
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
    end
    assert WorkPackage.find(2).watched_by?(User.find(3))
  end

  def test_remove_watcher
    @request.session[:user_id] = 2
    assert_difference('Watcher.count', -1) do
      xhr :delete, :destroy, id: Watcher.find_by_user_id_and_watchable_id(3, 2).id
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
    end
    assert !WorkPackage.find(2).watched_by?(User.find(3))
  end
end
