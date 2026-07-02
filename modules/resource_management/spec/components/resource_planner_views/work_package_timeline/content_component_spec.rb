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

RSpec.describe ResourcePlannerViews::WorkPackageTimeline::ContentComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }
  shared_let(:view) { ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project:, principal: user) }
  shared_let(:work_package) { create(:work_package, project:) }

  before { login_as(user) }

  it "renders the calendar container with feed urls and the initial view" do
    render_inline(described_class.new(view:, project:, resource_planner: planner, work_packages: [work_package]))

    el = page.find("[data-controller='resource-management--work-package-timeline']")
    prefix = "data-resource-management--work-package-timeline"
    expect(el["#{prefix}-resources-url-value"]).to be_present
    expect(el["#{prefix}-events-url-value"]).to be_present
    expect(el["#{prefix}-initial-view-value"]).to eq("resourceTimelineDays")
    expect(el["#{prefix}-reload-event-name-value"]).to eq("op-dispatched:resource-allocations:changed")
  end

  context "with no work packages" do
    it "mounts no calendar controller, showing a blankslate instead" do
      render_inline(described_class.new(view:, project:, resource_planner: planner, work_packages: []))

      expect(page).to have_no_css("[data-controller='resource-management--work-package-timeline']")
      expect(page).to have_css(".blankslate")
      expect(page).to have_text("No work packages to display")
    end

    context "with an automatically filtered view" do
      it "explains that nothing matches the filters and offers no add button" do
        render_inline(described_class.new(view:, project:, resource_planner: planner, work_packages: []))

        expect(page).to have_text("There are no work packages matching this view's filters yet.")
        expect(page).to have_no_css("a[href='#{new_work_package_project_resource_planner_view_path(project, planner, view)}']")
      end

      it "offers a configure-view button opening the edit dialog" do
        render_inline(described_class.new(view:, project:, resource_planner: planner, work_packages: []))

        expect(page).to have_css(
          "a[data-controller='async-dialog']" \
          "[href='#{edit_project_resource_planner_view_path(project, planner, view)}']",
          text: "Configure view"
        )
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

      it "invites adding a work package through the add dialog" do
        render_inline(described_class.new(view: manual_view, project:, resource_planner: planner, work_packages: []))

        expect(page).to have_text("Add work packages to this view to plan their allocation over time.")
        expect(page).to have_css(
          "a[data-controller='async-dialog']" \
          "[href='#{new_work_package_project_resource_planner_view_path(project, planner, manual_view)}']",
          text: "Add work package"
        )
      end
    end
  end
end
