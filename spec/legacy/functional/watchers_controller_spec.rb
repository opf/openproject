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
require 'watchers_controller'

describe WatchersController, type: :controller do
  fixtures :all

  render_views

  before do
    User.current = nil
  end

  it 'watch' do
    session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1'
      assert_response :success
      assert response.body.include? "$$(\"#watcher\").each"
      assert response.body.include? 'value.replace'
    end
    assert WorkPackage.find(1).watched_by?(User.find(3))
  end

  it 'watch should be denied without permission' do
    Role.find(2).remove_permission! :view_work_packages
    session[:user_id] = 3
    assert_no_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1'
      assert_response 403
    end
  end

  it 'watch with multiple replacements' do
    session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1', replace: ['#watch_item_1', '.watch_item_2']
      assert_response :success
      assert response.body.include? "$$(\"#watch_item_1\").each"
      assert response.body.include? "$$(\".watch_item_2\").each"
      assert response.body.include? 'value.replace'
    end
  end

  it 'watch with watchers special logic' do
    session[:user_id] = 3
    assert_difference('Watcher.count') do
      xhr :post, :watch, object_type: 'work_package', object_id: '1', replace: ['#watchers', '.watcher']
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
      assert response.body.include? "$$(\".watcher\").each"
      assert response.body.include? 'value.replace'
    end
  end

  it 'unwatch' do
    session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, object_type: 'work_package', object_id: '2'
      assert_response :success
      assert response.body.include? "$$(\"#watcher\").each"
      assert response.body.include? 'value.replace'
    end
    assert !WorkPackage.find(1).watched_by?(User.find(3))
  end

  it 'unwatch with multiple replacements' do
    session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, object_type: 'work_package', object_id: '2', replace: ['#watch_item_1', '.watch_item_2']
      assert_response :success
      assert response.body.include? "$$(\"#watch_item_1\").each"
      assert response.body.include? "$$(\".watch_item_2\").each"
      assert response.body.include? 'value.replace'
    end
    assert !WorkPackage.find(1).watched_by?(User.find(3))
  end

  it 'unwatch with watchers special logic' do
    session[:user_id] = 3
    assert_difference('Watcher.count', -1) do
      xhr :post, :unwatch, object_type: 'work_package', object_id: '2', replace: ['#watchers', '.watcher']
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
      assert response.body.include? "$$(\".watcher\").each"
      assert response.body.include? 'value.replace'
    end
    assert !WorkPackage.find(1).watched_by?(User.find(3))
  end

  it 'new watcher' do
    Watcher.destroy_all
    session[:user_id] = 2
    assert_difference('Watcher.count') do
      xhr :post, :new, object_type: 'work_package', object_id: '2', watcher: { user_id: '3' }
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
    end
    assert WorkPackage.find(2).watched_by?(User.find(3))
  end

  it 'remove watcher' do
    session[:user_id] = 2
    assert_difference('Watcher.count', -1) do
      xhr :delete, :destroy, id: Watcher.find_by_user_id_and_watchable_id(3, 2).id
      assert_response :success
      assert_select_rjs :replace_html, 'watchers'
    end
    assert !WorkPackage.find(2).watched_by?(User.find(3))
  end
end
