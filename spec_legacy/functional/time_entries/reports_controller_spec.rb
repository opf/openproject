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

require_relative '../../legacy_spec_helper'

describe TimeEntries::ReportsController, type: :controller do
  render_views

  fixtures :all

  it 'should report at project level' do
    get :show, params: { project_id: 'ecookbook' }
    assert_response :success
    assert_template 'time_entries/reports/show'
    assert_select 'form',
                  attributes: { action: '/projects/ecookbook/time_entries/report', id: 'query_form' }
  end

  it 'should report all projects' do
    get :show
    assert_response :success
    assert_template 'time_entries/reports/show'
    assert_select 'form',
                  attributes: { action: '/time_entries/report', id: 'query_form' }
  end

  it 'should report all projects denied' do
    r = Role.anonymous
    r.remove_permission!(:view_time_entries)
    r.save!
    get :show
    assert_redirected_to '/login?back_url=http%3A%2F%2Ftest.host%2Ftime_entries%2Freport'
  end

  it 'should report all projects one criteria' do
    get :show, params: { columns: 'week', from: '2007-04-01', to: '2007-04-30', criterias: ['project'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '8.65', '%.2f' % assigns(:total_hours)
  end

  it 'should report all time' do
    get :show, params: { project_id: 1, criterias: ['project', 'issue'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '162.90', '%.2f' % assigns(:total_hours)
  end

  it 'should report all time by day' do
    get :show, params: { project_id: 1, criterias: ['project', 'issue'], columns: 'day' }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '162.90', '%.2f' % assigns(:total_hours)
    assert_select 'th', descendant: { content: /\s*2007-03-12\s*/ }
  end

  it 'should report one criteria' do
    get :show, params: { project_id: 1, columns: 'week', from: '2007-04-01', to: '2007-04-30', criterias: ['project'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '8.65', '%.2f' % assigns(:total_hours)
  end

  it 'should report two criterias' do
    get :show, params: { project_id: 1,
                         columns: 'month',
                         from: '2007-01-01',
                         to: '2007-12-31',
                         criterias: ['member', 'activity'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '162.90', '%.2f' % assigns(:total_hours)
  end

  it 'should report one day' do
    get :show, params: { project_id: 1, columns: 'day', from: '2007-03-23', to: '2007-03-23', criterias: ['member', 'activity'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '4.25', '%.2f' % assigns(:total_hours)
  end

  it 'should report at issue level' do
    get :show, params: { project_id: 1,
                         work_package_id: 1,
                         columns: 'month',
                         from: '2007-01-01',
                         to: '2007-12-31',
                         criterias: ['member', 'activity'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '154.25', '%.2f' % assigns(:total_hours)
    assert_select 'form',
                  attributes: { action: work_package_time_entries_report_path(1), id: 'query_form' }
  end

  it 'should report custom field criteria' do
    get :show, params: { project_id: 1, criterias: ['project', 'cf_1', 'cf_7'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    refute_nil assigns(:criterias)
    assert_equal 3, assigns(:criterias).size
    assert_equal '162.90', '%.2f' % assigns(:total_hours)
    # Custom field column
    assert_select 'th', descendant: { content: /\s*Database\s*/ }
    # Custom field row
    assert_select 'td',
                  content: 'MySQL',
                  sibling: { tag: 'td', attributes: { class: 'hours' },
                             child: { tag: 'span', attributes: { class: 'hours hours-int' },
                                      content: '1' } }
    # Second custom field column
    assert_select 'th', descendant: { content: /\s*Billable\s*/ }
  end

  it 'should report one criteria no result' do
    get :show, params: { project_id: 1, columns: 'week', from: '1998-04-01', to: '1998-04-30', criterias: ['project'] }
    assert_response :success
    assert_template 'time_entries/reports/show'
    refute_nil assigns(:total_hours)
    assert_equal '0.00', '%.2f' % assigns(:total_hours)
  end

  it 'should report all projects csv export' do
    get :show, params: { columns: 'month',
                         from: '2007-01-01',
                         to: '2007-06-30',
                         criterias: ['project', 'member', 'activity'],
                         format: 'csv' }
    assert_response :success
    assert_match(/text\/csv/, response.content_type)
    lines = response.body.chomp.split("\n")
    # Headers
    assert_equal 'Project,Member,Activity,2007-1,2007-2,2007-3,2007-4,2007-5,2007-6,Total', lines.first
    # Total row
    assert_equal 'Total,"","","","",154.25,8.65,"","",162.90', lines.last
  end

  it 'should report csv export' do
    get :show, params: { project_id: 1,
                         columns: 'month',
                         from: '2007-01-01',
                         to: '2007-06-30',
                         criterias: ['project', 'member', 'activity'],
                         format: 'csv' }
    assert_response :success
    assert_match(/text\/csv/, response.content_type)
    lines = response.body.chomp.split("\n")
    # Headers
    assert_equal 'Project,Member,Activity,2007-1,2007-2,2007-3,2007-4,2007-5,2007-6,Total', lines.first
    # Total row
    assert_equal 'Total,"","","","",154.25,8.65,"","",162.90', lines.last
  end
end
