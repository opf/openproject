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
require_relative 'support/pages/cost_report_page'
require_relative 'support/components/cost_reports_base_table'

describe 'Updating entries within the cost report', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }
  let(:work_package) { FactoryBot.create :work_package, project: project }

  let!(:time_entry_user) do
    FactoryBot.create :time_entry,
                      user: user,
                      work_package: work_package,
                      project: project,
                      hours: 5
  end

  let(:cost_type) do
    type = FactoryBot.create :cost_type, name: 'My cool type'
    FactoryBot.create :cost_rate, cost_type: type, rate: 7.00
    type
  end

  let!(:cost_entry_user) do
    FactoryBot.create :cost_entry,
                      work_package: work_package,
                      project: project,
                      units: 3.00,
                      cost_type: cost_type,
                      user: user
  end

  let(:report_page) { ::Pages::CostReportPage.new project }
  let(:table) { ::Components::CostReportsBaseTable.new }

  before do
    login_as(user)
    visit cost_reports_path(project)
    report_page.clear
    report_page.apply
    report_page.show_loading_indicator present: false
  end

  it 'can edit and delete time entries' do
    table.rows_count 1

    table.expect_action_icon 'edit', 1
    table.expect_action_icon 'delete', 1

    table.edit_time_entry 2, 1

    table.delete_entry 1
    table.rows_count 0
  end

  it 'can edit and delete cost entries' do
    table.rows_count 1

    report_page.switch_to_type 'My cool type'
    report_page.show_loading_indicator present: false

    table.rows_count 1

    table.expect_action_icon 'edit', 1
    table.expect_action_icon 'delete', 1

    table.edit_cost_entry 2, 1, cost_entry_user.id.to_s
    visit cost_reports_path(project)
    table.rows_count 1

    table.delete_entry 1
    table.rows_count 0
  end

  it 'shows the action icons after a table refresh' do
    table.rows_count 1

    table.expect_action_icon 'edit', 1
    table.expect_action_icon 'delete', 1

    # Force a reload of the table (although nothing has changed)
    report_page.apply
    sleep(1)
    report_page.show_loading_indicator present: false

    table.rows_count 1

    table.expect_action_icon 'edit', 1
    table.expect_action_icon 'delete', 1
  end

  context 'as user without permissions' do
    let(:role) { FactoryBot.create :role, permissions: %i(view_time_entries) }
    let!(:user) do
      FactoryBot.create :user,
                        member_in_project: project,
                        member_through_role: role
    end

    it 'cannot edit or delete' do
      table.rows_count 1

      table.expect_action_icon 'edit', 1, present: false
      table.expect_action_icon 'delete', 1, present: false
    end
  end
end
