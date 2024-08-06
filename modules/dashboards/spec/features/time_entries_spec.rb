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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

require_relative "../support/pages/dashboard"

RSpec.describe "Time entries widget on dashboard", :js do
  let!(:type) { create(:type) }
  let!(:project) { create(:project, types: [type]) }
  let!(:other_project) { create(:project, types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           author: user)
  end
  let!(:visible_time_entry) do
    create(:time_entry,
           work_package:,
           project:,
           user:,
           spent_on: Date.today,
           hours: 6,
           comments: "My comment")
  end
  let!(:other_visible_time_entry) do
    create(:time_entry,
           work_package:,
           project:,
           user: other_user,
           spent_on: Date.today - 1.day,
           hours: 5,
           comments: "Another`s comment")
  end
  let!(:invisible_time_entry) do
    create(:time_entry,
           work_package:,
           project: other_project,
           user:,
           hours: 4)
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_time_entries
                           view_work_packages
                           edit_time_entries
                           view_dashboards
                           manage_dashboards])
  end
  let(:other_user) do
    create(:user)
  end
  let(:user) do
    create(:user).tap do |u|
      create(:member, project:, roles: [role], user: u)
      create(:member, project: other_project, roles: [role], user: u)
    end
  end

  let(:time_logging_modal) { Components::TimeLoggingModal.new }

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  it "adds the widget and checks the displayed entries" do
    # within top-right area, add an additional widget
    dashboard.add_widget(1, 1, :within, 'Spent time \(last 7 days\)')

    spent_time_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

    within spent_time_widget.area do
      expect(page)
        .to have_content "Total: 11 h"

      expect(page)
        .to have_content Date.today.strftime("%m/%d/%Y")
      expect(page)
        .to have_css(".activity", text: visible_time_entry.activity.name)
      expect(page)
        .to have_css(".subject", text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")
      expect(page)
        .to have_css(".comments", text: visible_time_entry.comments)
      expect(page)
        .to have_css(".hours", text: visible_time_entry.hours)

      expect(page)
        .to have_content((Date.today - 1.day).strftime("%m/%d/%Y"))
      expect(page)
        .to have_css(".activity", text: other_visible_time_entry.activity.name)
      expect(page)
        .to have_css(".subject", text: "#{project.name} - ##{work_package.id}: #{work_package.subject}")
      expect(page)
        .to have_css(".comments", text: other_visible_time_entry.comments)
      expect(page)
        .to have_css(".hours", text: other_visible_time_entry.hours)

      # Allows to edit
      page.find_test_selector("edit-time-entry-#{visible_time_entry.id}").click
    end

    time_logging_modal.is_visible true

    time_logging_modal.expect_work_package work_package.subject

    time_logging_modal.update_field "hours", 4

    sleep(0.1)

    time_logging_modal.perform_action "Save"
    time_logging_modal.is_visible false

    within spent_time_widget.area do
      expect(page).to have_css(".hours", text: 4)
    end

    visible_time_entry.reload
    expect(visible_time_entry.hours).to eq 4.0
  end
end
