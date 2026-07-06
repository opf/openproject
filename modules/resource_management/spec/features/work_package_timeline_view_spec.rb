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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package timeline view", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:wp) { create(:work_package, project:, subject: "Develop route optimization") }
  shared_let(:view) do
    ResourceWorkPackageTimeline.create!(name: "Epic Planning", parent: planner, project:, principal: user).tap do |v|
      v.update!(query: v.build_default_query.tap { |q| q.name = "Epic Planning" })
    end
  end

  before { login_as user }

  it "renders the work package as a timeline row" do
    visit project_resource_planner_view_path(project, planner, view)

    expect(page).to have_css("[data-test-selector='resource-work-package-timeline']")
    expect(page).to have_text("Develop route optimization", wait: 15)
  end

  it "shades each work package's active span" do
    visit project_resource_planner_view_path(project, planner, view)

    expect(page).to have_css("[data-test-selector='resource-work-package-timeline']")
    expect(page).to have_css(".op-rm-timeline-view .fc-bg-event.op-rm-timeline-active", wait: 15)
  end

  it "marks header columns that have an active work package" do
    visit project_resource_planner_view_path(project, planner, view)

    expect(page).to have_css(
      ".op-rm-timeline-view .fc-timeline-header .fc-timeline-slot-label.op-rm-active-col",
      wait: 15
    )
  end
end
