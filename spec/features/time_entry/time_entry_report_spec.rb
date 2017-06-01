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

require 'spec_helper'

describe 'time entry report', type: :feature, js: true do
  let(:project) { FactoryGirl.create(:project, enabled_module_names: %w(time_tracking)) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_time_entries]) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let!(:project_time_entry) {
    FactoryGirl.create_list(:time_entry,
                            2,
                            project: project,
                            work_package: work_package,
                            hours: 2.5)
  }
  let(:project2) { FactoryGirl.create(:project) }
  let(:work_package2) { FactoryGirl.create(:work_package, project: project2) }
  let!(:project_time_entry2) {
    FactoryGirl.create(:time_entry,
                       project: project2,
                       spent_on: 1.year.ago,
                       work_package: work_package2,
                       hours: 5.0)
  }
  let(:user) { FactoryGirl.create(:admin) }

  before do
    login_as(user)
  end

  describe 'details' do
    context 'for a single project' do
      before do
        visit project_time_entries_path(project.identifier)
      end

      it 'should list the time entries' do
        expect(page).to have_selector('tr.time-entry', count: 2)
        expect(page).to have_selector('.time-entry .hours', text: 2.5, count: 2)
      end
    end

    context 'for all projects' do
      before do
        visit time_entries_path
      end

      it 'should list the time entries' do
        expect(page).to have_selector('tr.time-entry', count: 3)
        expect(page).to have_selector('.time-entry .hours', text: 2.5, count: 2)
        expect(page).to have_selector('.time-entry .hours', text: 5.0)
      end
    end
  end

  describe 'reports' do
    before do
      visit time_entries_report_path
    end

    it 'should add columns' do
      select 'Project', from: 'criterias'
      select 'Month', from: 'columns'
      find('.timelog-report-selection').click_button('Apply')

      expect(page).to have_selector('.total-hours', text: 'Total: 10.00 hours')
      expect(page).to have_selector('tr.total .hours', text: '5.00')
      select 'Year', from: 'columns'

      find('.timelog-report-selection').click_button('Apply')
      expect(page).to have_selector('.total-hours', text: 'Total: 10.00 hours')
    end
  end
end
