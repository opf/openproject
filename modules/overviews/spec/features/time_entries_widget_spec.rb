# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

require_relative "../support/pages/dashboard"

RSpec.describe "Spent time widget on the dashboard", :js do
  include_context "with axe on Cuprite"

  shared_let(:project) { create(:project_with_types) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages view_time_entries edit_time_entries log_time]
           })
  end
  shared_let(:time_entry) do
    create(:time_entry, entity: work_package, project:, user:, spent_on: Time.zone.today, hours: 6)
  end
  shared_let(:overview) do
    create(:overview,
           project:,
           widgets: [
             build(:grid_widget,
                   identifier: "time_entries_list",
                   start_row: 1,
                   end_row: 2,
                   start_column: 1,
                   end_column: 2,
                   options: { name: "Spent time (last 7 days)" })
           ])
  end

  let(:dashboard_page) { Pages::Dashboard.new(project) }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }

  before do
    login_as user
    dashboard_page.visit!
  end

  it "names the row actions and opens them from the keyboard", :selenium do
    within("table.time-entries") do
      expect(page).to have_button(accessible_name: "Edit")
      expect(page).to have_button(accessible_name: "Delete")
    end
    expect(page).to be_axe_clean.within("table.time-entries tbody")

    find(:button, accessible_name: "Edit").send_keys(:enter)
    time_logging_modal.is_visible(true)
  end

  it "asks for confirmation before deleting from the keyboard" do
    find(:button, accessible_name: "Delete").send_keys(:space)

    expect(page).to have_dialog
  end
end
