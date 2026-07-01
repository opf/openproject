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

RSpec.describe ResourcePlannerViews::WorkPackageTimeline::SubHeaderComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:view) { ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project:, principal: user) }

  before { login_as(user) }

  it "renders navigation and granularity controls wired to the timeline controller" do
    render_inline(described_class.new(project:, resource_planner: planner, view:))

    html = page.native.to_html
    expect(html).to include("resource-management--work-package-timeline#today")
    expect(html).to include("resource-management--work-package-timeline#prev")
    expect(html).to include("resource-management--work-package-timeline#next")
    expect(html).to include("resource-management--work-package-timeline#setView")
    expect(html).to include("resourceTimelineWeeks")
    expect(html).to include("resourceTimelineMonths")
  end

  it "offers a configure-view button opening the edit dialog" do
    render_inline(described_class.new(project:, resource_planner: planner, view:))

    expect(page).to have_css(
      "a[data-controller='async-dialog']" \
      "[href='#{edit_project_resource_planner_view_path(project, planner, view)}']"
    )
  end

  context "with an automatically filtered view" do
    it "shows no add-work-package option" do
      render_inline(described_class.new(project:, resource_planner: planner, view:))

      expect(page).to have_no_text("Add work package")
    end
  end

  context "with a manually hand-picked view" do
    let(:manual_query) do
      Query.new_default(project:, user:).tap do |q|
        q.name = "q"
        q.add_filter("manual_sort", "ow", [])
        q.sort_criteria = [%w[manual_sorting asc]]
        q.save!
      end
    end
    let(:manual_view) do
      ResourceWorkPackageTimeline.create!(name: "Manual", parent: planner, project:, principal: user, query: manual_query)
    end

    it "links an add-work-package option to the search dialog" do
      render_inline(described_class.new(project:, resource_planner: planner, view: manual_view))

      expect(page).to have_text("Add work package")
      expect(page).to have_link(
        href: new_work_package_project_resource_planner_view_path(project, planner, manual_view)
      )
    end
  end
end
