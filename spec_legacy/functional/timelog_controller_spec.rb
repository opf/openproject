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

  it 'should post create' do
    # TODO: should POST to issues’ time log instead of project. change form
    # and routing
    session[:user_id] = 3
    post :create, params: { project_id: 1,
                            time_entry: { comments: 'Some work on TimelogControllerTest',
                                          # Not the default activity
                                          activity_id: '11',
                                          spent_on: '2008-03-14',
                                          work_package_id: '1',
                                          hours: '7.3' } }
    assert_redirected_to action: 'index', project_id: 'ecookbook'

    i = WorkPackage.find(1)
    t = TimeEntry.find_by(comments: 'Some work on TimelogControllerTest')
    refute_nil t
    assert_equal 11, t.activity_id
    assert_equal 7.3, t.hours
    assert_equal 3, t.user_id
    assert_equal i, t.work_package
    assert_equal i.project, t.project
  end

  it 'should post create with blank issue' do
    # TODO: should POST to issues’ time log instead of project. change form
    # and routing
    session[:user_id] = 3
    post :create, params: { project_id: 1,
                            time_entry: { comments: 'Some work on TimelogControllerTest',
                                          # Not the default activity
                                          activity_id: '11',
                                          work_package_id: '',
                                          spent_on: '2008-03-14',
                                          hours: '7.3' } }
    assert_redirected_to action: 'index', project_id: 'ecookbook'

    t = TimeEntry.find_by(comments: 'Some work on TimelogControllerTest')
    refute_nil t
    assert_equal 11, t.activity_id
    assert_equal 7.3, t.hours
    assert_equal 3, t.user_id
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

  it 'should destroy' do
    session[:user_id] = 2
    delete :destroy, params: { id: 1 }
    assert_redirected_to action: 'index', project_id: 'ecookbook'
    assert_equal I18n.t(:notice_successful_delete), flash[:notice]
    assert_nil TimeEntry.find_by(id: 1)
  end

  it 'should destroy should fail' do
    # simulate that this fails (e.g. due to a plugin), see #5700
    TimeEntry.class_eval do
      before_destroy :stop_callback_chain
      def stop_callback_chain; false; end
    end

    session[:user_id] = 2
    delete :destroy, params: { id: 1 }
    assert_redirected_to action: 'index', project_id: 'ecookbook'
    assert_equal I18n.t(:notice_unable_delete_time_entry), flash[:error]
    refute_nil TimeEntry.find_by(id: 1)

    # remove the simulation
    TimeEntry._destroy_callbacks.reject { |callback| callback.filter == :stop_callback_chain }
  end

  it 'should index all projects' do
    get :index
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:total_hours)
    assert_equal '162.90', '%.2f' % assigns(:total_hours)
    assert_select 'form',
               attributes: { action: '/time_entries', id: 'query_form' }
  end

  it 'should index at project level' do
    get :index, params: { project_id: 'ecookbook' }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:entries)
    assert_equal 4, assigns(:entries).size
    # project and subproject
    assert_equal [1, 3], assigns(:entries).map(&:project_id).uniq.sort
    refute_nil assigns(:total_hours)
    assert_equal '162.90', '%.2f' % assigns(:total_hours)
    # display all time by default
    assert_equal '2007-03-12'.to_date, assigns(:from)
    assert_equal '2007-04-22'.to_date, assigns(:to)
    assert_select 'form',
               attributes: { action: '/projects/ecookbook/time_entries', id: 'query_form' }
  end

  it 'should index at project level with date range' do
    get :index, params: { project_id: 'ecookbook', from: '2007-03-20', to: '2007-04-30' }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:entries)
    assert_equal 3, assigns(:entries).size
    refute_nil assigns(:total_hours)
    assert_equal '12.90', '%.2f' % assigns(:total_hours)
    assert_equal '2007-03-20'.to_date, assigns(:from)
    assert_equal '2007-04-30'.to_date, assigns(:to)
    assert_select 'form',
               attributes: { action: '/projects/ecookbook/time_entries', id: 'query_form' }
  end

  it 'should index at project level with period' do
    get :index, params: { project_id: 'ecookbook', period: '7_days' }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:entries)
    refute_nil assigns(:total_hours)
    assert_equal Date.today - 7, assigns(:from)
    assert_equal Date.today, assigns(:to)
    assert_select 'form',
               attributes: { action: '/projects/ecookbook/time_entries', id: 'query_form' }
  end

  it 'should index one day' do
    get :index, params: { project_id: 'ecookbook', from: '2007-03-23', to: '2007-03-23' }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:total_hours)
    assert_equal '4.25', '%.2f' % assigns(:total_hours)
    assert_select 'form',
               attributes: { action: '/projects/ecookbook/time_entries', id: 'query_form' }
  end

  it 'should index at issue level' do
    get :index, params: { work_package_id: 1 }
    assert_response :success
    assert_template 'index'
    refute_nil assigns(:entries)
    assert_equal 2, assigns(:entries).size
    refute_nil assigns(:total_hours)
    assert_equal 154.25, assigns(:total_hours)
    # display all time based on what's been logged
    assert_equal '2007-03-12'.to_date, assigns(:from)
    assert_equal '2007-04-22'.to_date, assigns(:to)
    assert_select 'form',
               attributes: { action: work_package_time_entries_path(1), id: 'query_form' }
  end

  it 'should index atom feed' do
    TimeEntry.all.each(&:recreate_initial_journal!)

    get :index, params: { project_id: 1, format: 'atom' }
    assert_response :success
    assert_equal 'application/atom+xml', response.content_type
    refute_nil assigns(:items)
    assert assigns(:items).first.is_a?(TimeEntry)
  end
end
