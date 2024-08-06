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

RSpec.describe "Work package calendar widget on dashboard", :js do
  let!(:type) { create(:type) }
  let!(:priority) { create(:default_priority) }
  let!(:project) { create(:project, types: [type]) }
  let!(:other_project) { create(:project, types: [type]) }
  let!(:open_status) { create(:default_status) }
  let!(:spanning_work_package) do
    create(:work_package,
           subject: "Spanning work package",
           project:,
           start_date: Date.today - 8.days,
           due_date: Date.today + 8.days,
           type:,
           author: user,
           responsible: user)
  end
  let!(:starting_work_package) do
    create(:work_package,
           subject: "Starting work package",
           project:,
           start_date: Date.today,
           due_date: Date.today + 8.days,
           type:,
           author: user,
           responsible: user)
  end
  let!(:ending_work_package) do
    create(:work_package,
           subject: "Ending work package",
           project:,
           start_date: Date.today - 8.days,
           due_date: Date.today,
           type:,
           author: user,
           responsible: user)
  end
  let!(:outdated_work_package) do
    create(:work_package,
           subject: "Outdated work package",
           project:,
           start_date: Date.today - 9.days,
           due_date: Date.today - 7.days,
           type:,
           author: user,
           responsible: user)
  end
  let!(:other_project_work_package) do
    create(:work_package,
           subject: "Other project work package",
           project: other_project,
           start_date: Date.today - 9.days,
           due_date: Date.today + 7.days,
           type:,
           author: user,
           responsible: user)
  end

  let(:permissions) do
    %i[view_work_packages
       view_dashboards
       manage_dashboards]
  end

  let(:role) do
    create(:project_role, permissions:)
  end

  let(:user) do
    create(:user).tap do |u|
      create(:member, project:, user: u, roles: [role])
      create(:member, project: other_project, user: u, roles: [role])
    end
  end

  let(:dashboard) do
    Pages::Dashboard.new(project)
  end

  before do
    login_as user

    dashboard.visit!
  end

  it "can add the widget and see the work packages of the project" do
    dashboard.add_widget(1, 1, :within, "Calendar")

    sleep(0.1)

    # As the user lacks the necessary permissions, no widget is preconfigured
    calendar_widget = Components::Grids::GridArea.new(".grid--area.-widgeted:nth-of-type(1)")

    within(calendar_widget.area) do
      expect(page)
        .to have_css(".fc-event-title", text: spanning_work_package.subject)

      expect(page)
        .to have_css(".fc-event-title", text: starting_work_package.subject)

      expect(page)
        .to have_css(".fc-event-title", text: ending_work_package.subject)

      expect(page)
        .to have_no_css(".fc-event-title", text: outdated_work_package.subject)

      expect(page)
        .to have_no_css(".fc-event-title", text: other_project_work_package.subject)
    end
  end
end
