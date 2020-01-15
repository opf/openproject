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
require 'timelog_controller'

describe TimelogController, type: :controller do
  render_views

  fixtures :all

  it 'should get new' do
    session[:user_id] = 3
    get :new, params: { project_id: 1 }
    assert_response :success
    assert_template 'edit'
    # Default activity selected
    assert_select 'option',
                  attributes: { selected: 'selected' },
                  content: 'Development'
  end

  it 'should get new should only show active time entry activities' do
    session[:user_id] = 3
    get :new, params: { project_id: 1 }
    assert_response :success
    assert_template 'edit'
    assert_select('option', { content: 'Inactive Activity' }, false)
  end

  it 'should get edit existing time' do
    session[:user_id] = 2
    get :edit, params: { id: 2, project_id: nil }
    assert_response :success
    assert_template 'edit'
    # Default activity selected
    assert_select 'form', attributes: { action: '/projects/ecookbook/time_entries/2' }
  end

  it 'should get edit with an existing time entry with inactive activity' do
    te = TimeEntry.find(1)
    te.activity = TimeEntryActivity.find_by(name: 'Inactive Activity')
    te.save!

    session[:user_id] = 1
    get :edit, params: { project_id: 1, id: 1 }
    assert_response :success
    assert_template 'edit'
    # Blank option since nothing is pre-selected
    assert_select 'option', content: '--- Please select ---'
  end

  it 'should update' do
    entry = TimeEntry.find(1)
    assert_equal 1, entry.work_package_id
    assert_equal 2, entry.user_id

    session[:user_id] = 1
    put :update, params: { id: 1,
                           time_entry: { work_package_id: '2',
                                         hours: '8' } }
    assert_redirected_to action: 'index', project_id: 'ecookbook'
    entry.reload

    assert_equal 8, entry.hours
    assert_equal 2, entry.work_package_id
    assert_equal 2, entry.user_id
  end
end
