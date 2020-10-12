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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'Work Package table cost entries', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }

  let(:parent) { FactoryBot.create :work_package, project: project }
  let(:work_package) { FactoryBot.create :work_package, project: project, parent: parent }
  let(:hourly_rate) { FactoryBot.create :default_hourly_rate, user: user, rate: 1.00 }

  let!(:time_entry1) do
    FactoryBot.create :time_entry,
                      user: user,
                      work_package: parent,
                      project: project,
                      hours: 10
  end

  let!(:time_entry2) do
    FactoryBot.create :time_entry,
                      user: user,
                      work_package: work_package,
                      project: project,
                      hours: 2.50
  end

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = %w(id subject spent_hours)

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(parent)
    wp_table.expect_work_package_listed(work_package)
  end

  it 'shows the correct sum of the time entries' do
    parent_row = wp_table.row(parent)
    wp_row = wp_table.row(work_package)

    expect(parent_row).to have_selector('.inline-edit--container.spentTime', text: '12.5 h')
    expect(wp_row).to have_selector('.inline-edit--container.spentTime', text: '2.5 h')
  end

  it 'creates an activity' do
    visit project_activities_path project

    # Activate budget filter
    check('Spent time')
    check('Budgets')
    click_on 'Apply'

    expect(page).to have_selector('.time-entry a', text: '10.00 h')
    expect(page).to have_selector('.time-entry a', text: '2.50 h')
  end
end
