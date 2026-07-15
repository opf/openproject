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

RSpec.describe "Work package timeline feeds", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  # Public so allocators other than the owner can reach it (edit-url scenarios).
  shared_let(:planner) { create(:resource_planner, project:, principal: user, public: true) }
  shared_let(:wp) { create(:work_package, project:, subject: "Develop route optimization") }
  shared_let(:view) do
    ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project:, principal: user).tap do |v|
      v.update!(query: v.build_default_query.tap { |q| q.name = "Timeline" })
    end
  end

  before { login_as user }

  describe "resources" do
    it "returns the view's work packages as FullCalendar resources with rendered html" do
      get project_resource_planner_view_work_package_timeline_resources_path(project, planner, view, format: :json)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      ids = body["resources"].map { |r| r["id"].to_i }
      expect(ids).to include(wp.id)
      cell = body["resources"].find { |r| r["id"].to_i == wp.id }
      expect(cell.dig("extendedProps", "html")).to include("Develop route optimization")
    end

    it "tags each resource with its position so FullCalendar keeps the query order" do
      create(:work_package, project:, subject: "Second work package")
      get project_resource_planner_view_work_package_timeline_resources_path(project, planner, view, format: :json)

      orders = response.parsed_body["resources"].pluck("order")
      expect(orders).to eq((0...orders.size).to_a)
    end

    it "denies users without access" do
      login_as create(:user)
      get project_resource_planner_view_work_package_timeline_resources_path(project, planner, view, format: :json)

      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end

  describe "events" do
    shared_let(:assignee) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] }).tap do |u|
        create(:user_working_hours, user: u, valid_from: Date.new(2026, 1, 1))
      end
    end
    shared_let(:allocation_a) do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
    end
    shared_let(:allocation_b) do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
    end

    it "returns allocations as FullCalendar events flagged overbooked" do
      get project_resource_planner_view_work_package_timeline_events_path(project, planner, view,
                                                                          start: "2026-05-25", end: "2026-07-01", format: :json)

      expect(response).to have_http_status(:ok)
      block_events = response.parsed_body["events"].reject { |e| e["display"] == "background" }
      expect(block_events.map { |e| e["resourceId"].to_i }).to all(eq(wp.id))
      expect(block_events).to all(include("start", "end"))
      expect(block_events.map { |e| e.dig("extendedProps", "overbooked") }).to include(true)
    end

    def block_events
      response.parsed_body["events"].reject { |e| e["display"] == "background" }
    end

    def get_events(start: "2026-05-25", finish: "2026-07-01")
      get project_resource_planner_view_work_package_timeline_events_path(
        project, planner, view, start:, end: finish, format: :json
      )
    end

    it "carries an edit url on each allocation event for a user who may allocate" do
      login_as create(:user, member_with_permissions: {
                        project => %i[view_resource_planners view_work_packages allocate_user_resources]
                      })
      get_events

      expect(block_events.map { |e| e.dig("extendedProps", "editUrl") })
        .to include(edit_project_resource_allocation_path(project, allocation_a),
                    edit_project_resource_allocation_path(project, allocation_b))
    end

    it "omits the edit url for a user who may only view" do
      # the shared `user` has view permissions but not allocate_user_resources
      get_events

      expect(block_events).to all(satisfy { |e| e.dig("extendedProps", "editUrl").nil? })
    end

    it "never carries an edit url on the background span events" do
      login_as create(:user, member_with_permissions: {
                        project => %i[view_resource_planners view_work_packages allocate_user_resources]
                      })
      get_events

      background = response.parsed_body["events"].select { |e| e["display"] == "background" }
      expect(background).not_to be_empty
      expect(background).to all(satisfy { |e| e.dig("extendedProps", "editUrl").nil? })
    end
  end

  describe "active-span background events" do
    shared_let(:dated_wp) do
      create(:work_package, project:, subject: "Dated",
                            start_date: Date.new(2026, 6, 10), due_date: Date.new(2026, 6, 12))
    end
    shared_let(:open_start_wp) do
      create(:work_package, project:, subject: "Open start", start_date: nil, due_date: Date.new(2026, 6, 12))
    end
    shared_let(:open_due_wp) do
      create(:work_package, project:, subject: "Open due", start_date: Date.new(2026, 6, 10), due_date: nil)
    end
    shared_let(:undated_wp) do
      create(:work_package, project:, subject: "Undated", start_date: nil, due_date: nil)
    end
    shared_let(:outside_wp) do
      create(:work_package, project:, subject: "Outside",
                            start_date: Date.new(2026, 8, 1), due_date: Date.new(2026, 8, 5))
    end

    def background_event_for(work_package, granularity:)
      get project_resource_planner_view_work_package_timeline_events_path(
        project, planner, view,
        start: "2026-06-01", end: "2026-07-01", granularity:, format: :json
      )
      expect(response).to have_http_status(:ok)
      response.parsed_body["events"]
        .select { |e| e["display"] == "background" }
        .find { |e| e["resourceId"].to_i == work_package.id }
    end

    it "snaps a dated work package to the exact days at day granularity" do
      event = background_event_for(dated_wp, granularity: "day")
      expect(event).to include("start" => "2026-06-10", "end" => "2026-06-13",
                               "display" => "background", "classNames" => ["op-rm-timeline-active"])
    end

    it "expands to whole weeks at week granularity" do
      event = background_event_for(dated_wp, granularity: "week")
      expect(event).to include("start" => "2026-06-08", "end" => "2026-06-15")
    end

    it "expands to the whole month at month granularity" do
      event = background_event_for(dated_wp, granularity: "month")
      expect(event).to include("start" => "2026-06-01", "end" => "2026-07-01")
    end

    it "extends a missing start to the visible range start" do
      event = background_event_for(open_start_wp, granularity: "day")
      expect(event).to include("start" => "2026-06-01", "end" => "2026-06-13")
    end

    it "extends a missing due to the visible range end" do
      event = background_event_for(open_due_wp, granularity: "day")
      expect(event).to include("start" => "2026-06-10", "end" => "2026-07-01")
    end

    it "spans the whole visible row when both dates are missing" do
      event = background_event_for(undated_wp, granularity: "day")
      expect(event).to include("start" => "2026-06-01", "end" => "2026-07-01")
    end

    it "omits a band for a work package entirely outside the visible range" do
      expect(background_event_for(outside_wp, granularity: "day")).to be_nil
    end
  end
end
