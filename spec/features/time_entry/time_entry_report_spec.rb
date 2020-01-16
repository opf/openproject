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

require 'spec_helper'

describe 'time entry report', type: :feature, js: true do
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w(time_tracking)) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_time_entries]) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let!(:project_time_entry) {
    FactoryBot.create_list(:time_entry,
                           2,
                           project: project,
                           work_package: work_package,
                           hours: 2.5)
  }
  let(:project2) { FactoryBot.create(:project) }
  let(:work_package2) { FactoryBot.create(:work_package, project: project2) }
  let!(:project_time_entry2) {
    FactoryBot.create(:time_entry,
                      project: project2,
                      spent_on: 1.year.ago,
                      work_package: work_package2,
                      hours: 5.0)
  }
  let(:user) { FactoryBot.create(:admin) }

  before do
    login_as(user)
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

  describe 'with more precise values' do
    let!(:project_time_entry) {
      FactoryBot.create_list(:time_entry,
                             2,
                             project: project,
                             work_package: work_package,
                             hours: 2.249999999)
    }

    it 'rounds them to two decimals precision (Regression #30743)' do
      visit time_entries_report_path

      select 'Project', from: 'criterias'
      select 'Month', from: 'columns'
      find('.timelog-report-selection').click_button('Apply')

      expect(page).to have_selector('.total-hours', text: 'Total: 9.50 hours')
      expect(page).to have_selector('tr.total .hours', text: '4.50')
      select 'Year', from: 'columns'

      find('.timelog-report-selection').click_button('Apply')
      expect(page).to have_selector('.total-hours', text: 'Total: 9.50 hours')
    end
  end
end
