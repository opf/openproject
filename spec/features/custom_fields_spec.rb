#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe 'Custom fields reporting', type: :feature, js: true do
  let(:type) { FactoryGirl.create :type }
  let(:project) { FactoryGirl.create :project, types: [type] }

  let(:user) { FactoryGirl.create :admin }

  let(:work_package) {
    FactoryGirl.create :work_package,
                       project: project,
                       custom_values: initial_custom_values
  }

  let!(:time_entry1) {
    FactoryGirl.create :time_entry,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }

  let!(:time_entry2) {
    FactoryGirl.create :time_entry,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 2.50
  }

  before do
    login_as(user)
    visit '/cost_reports'
  end

  context 'with multi value cf' do
    let!(:custom_field) do
      FactoryGirl.create(
          :list_wp_custom_field,
          name: "List CF",
          multi_value: true,
          types: [type],
          projects: [project],
          possible_values: ['First option', 'Second option']
      )
    end

    let(:initial_custom_values) { { custom_field.id => 1 } }

    it 'groups by the multi CF (Regression #26050)' do
      expect(page).to have_selector('#group-by--add-columns')
      expect(page).to have_selector('#group-by--add-rows')

      select 'List CF', from: 'group-by--add-columns'
      select 'Work package', from: 'group-by--add-rows'

      find('#query-icon-apply-button').click

      # Expect row of work package
      within('#result-table') do
        expect(page).to have_selector('a.issue', text: "#{work_package.type.to_s} ##{work_package.id}")
        expect(page).to have_selector('th.inner', text: 'First option')
        expect(page).to have_no_selector('th.inner', text: 'Second option')

        # Only first option should have content for the work package
        expect(page).to have_selector('table.report tbody tr', count: 1)
        row_elements = page.all('table.report tr.odd th')

        expect(row_elements[0].text).to eq(project.name)
        expect(row_elements[1].text).to eq(work_package.to_s)

        row_elements = page.all('table.report tr.odd td')
        expect(row_elements[0].text).to eq('12.50 hours')
      end
    end
  end

  context 'with text CF' do
    let(:custom_field) do
      FactoryGirl.create(
          :text_wp_custom_field,
          name: 'Text CF',
          types: [type],
          projects: [project]
      )
    end
    let(:initial_custom_values) { { custom_field.id => 'foo' } }

    it 'groups by a text CF' do
      expect(page).to have_selector('#group-by--add-columns')
      expect(page).to have_selector('#group-by--add-rows')

      select 'Text CF', from: 'group-by--add-columns'
      select 'Work package', from: 'group-by--add-rows'

      find('#query-icon-apply-button').click

      # Expect row of work package
      within('#result-table') do
        expect(page).to have_selector('a.issue', text: "#{work_package.type.to_s} ##{work_package.id}")
        expect(page).to have_selector('th.inner', text: 'foo')
        expect(page).to have_no_selector('th.inner', text: 'None')

        # Only first option should have content for the work package
        expect(page).to have_selector('table.report tbody tr', count: 1)
        row_elements = page.all('table.report tr.odd th')

        expect(row_elements[0].text).to eq(project.name)
        expect(row_elements[1].text).to eq(work_package.to_s)

        row_elements = page.all('table.report tr.odd td')
        expect(row_elements[0].text).to eq('12.50 hours')
      end
    end
  end
end
