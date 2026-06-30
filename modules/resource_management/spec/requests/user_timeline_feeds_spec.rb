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

RSpec.describe "User timeline feeds", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, firstname: "Olivia", lastname: "Owner",
                  member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  # Public so allocators other than the owner can reach it (edit-url scenarios).
  shared_let(:planner) { create(:resource_planner, project:, principal: user, public: true) }
  shared_let(:assignee) do
    create(:user, firstname: "Adam", lastname: "Assignee",
                  member_with_permissions: { project => %i[view_resource_planners view_work_packages] }).tap do |u|
      create(:user_working_hours, user: u, valid_from: Date.new(2026, 1, 1))
    end
  end
  shared_let(:wp) { create(:work_package, project:, subject: "Develop route optimization") }
  shared_let(:view) do
    ResourceUserTimeline.create!(name: "Timeline", parent: planner, project:, principal: user).tap do |v|
      v.update!(query: v.build_default_query.tap { |q| q.name = "Timeline" })
    end
  end

  before { login_as user }

  describe "resources" do
    it "returns the view's users as FullCalendar resources with rendered html" do
      get project_resource_planner_view_user_timeline_resources_path(project, planner, view, format: :json)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      ids = body["resources"].map { |r| r["id"].to_i }
      expect(ids).to include(user.id, assignee.id)
      cell = body["resources"].find { |r| r["id"].to_i == assignee.id }
      expect(cell.dig("extendedProps", "html")).to include("Adam Assignee")
    end

    it "tags each resource with its position so FullCalendar keeps the query order" do
      get project_resource_planner_view_user_timeline_resources_path(project, planner, view, format: :json)

      orders = response.parsed_body["resources"].pluck("order")
      expect(orders).to eq((0...orders.size).to_a)
    end

    it "flags an over-allocated user's row" do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)

      get project_resource_planner_view_user_timeline_resources_path(project, planner, view, format: :json)

      cell = response.parsed_body["resources"].find { |r| r["id"].to_i == assignee.id }
      expect(cell.dig("extendedProps", "html")).to include(I18n.t("resource_management.user_timeline.overbooked"))
    end

    it "flags a user with no work schedule, but not one who has one" do
      get project_resource_planner_view_user_timeline_resources_path(project, planner, view, format: :json)

      warning = I18n.t("resource_management.user_timeline.no_work_schedule")
      # `user` (Olivia) has no working hours; `assignee` (Adam) has the factory default.
      no_schedule = response.parsed_body["resources"].find { |r| r["id"].to_i == user.id }
      scheduled = response.parsed_body["resources"].find { |r| r["id"].to_i == assignee.id }

      expect(no_schedule.dig("extendedProps", "html")).to include(warning)
      expect(scheduled.dig("extendedProps", "html")).not_to include(warning)
    end

    it "shows the user's department (bold) and job title" do
      create(:department, lastname: "Product Team", members: [assignee])
      job_title = create(:user_custom_field, :string, name: "Position", semantic_key: :job_title)
      assignee.custom_values.create!(custom_field: job_title, value: "UX Designer")

      get project_resource_planner_view_user_timeline_resources_path(project, planner, view, format: :json)

      html = response.parsed_body["resources"].find { |r| r["id"].to_i == assignee.id }.dig("extendedProps", "html")
      expect(html).to include("<b>Product Team</b>") # department bold
      expect(html).to include("UX Designer")
    end

    it "denies users without access" do
      login_as create(:user)
      get project_resource_planner_view_user_timeline_resources_path(project, planner, view, format: :json)

      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end

  describe "events" do
    shared_let(:allocation) do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
    end

    def block_events
      response.parsed_body["events"]
    end

    def get_events
      get project_resource_planner_view_user_timeline_events_path(
        project, planner, view, start: "2026-05-25", end: "2026-07-01", format: :json
      )
    end

    it "places each allocation on its assigned user's row with the work package html" do
      get_events

      expect(response).to have_http_status(:ok)
      event = block_events.find { |e| e["id"] == allocation.id }
      expect(event["resourceId"]).to eq(assignee.id)
      expect(event).to include("start" => "2026-06-01", "end" => "2026-06-06")
      expect(event.dig("extendedProps", "html")).to include("Develop route optimization")
      # Carries its work package's status colour on the bar's top edge.
      expect(event.dig("extendedProps", "html")).to include("op-rm-timeline-bar_status")
    end

    it "carries an edit url on each allocation event for a user who may allocate" do
      login_as create(:user, member_with_permissions: {
                        project => %i[view_resource_planners view_work_packages allocate_user_resources]
                      })
      get_events

      expect(block_events.map { |e| e.dig("extendedProps", "editUrl") })
        .to include(edit_project_resource_allocation_path(project, allocation))
    end

    it "omits the edit url for a user who may only view" do
      # the shared `user` has view permissions but not allocate_user_resources
      get_events

      expect(block_events).to all(satisfy { |e| e.dig("extendedProps", "editUrl").nil? })
    end

    it "paints a red background over the days a user is over-allocated" do
      # A second full week on the same Mon-Fri days exceeds the assignee's schedule.
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
      get_events

      overbooked_bg = block_events.select do |e|
        e["display"] == "background" && (e["classNames"] || []).include?("op-rm-timeline-overbooked")
      end
      expect(overbooked_bg).not_to be_empty
      expect(overbooked_bg.pluck("resourceId")).to all(eq(assignee.id))
    end

    it "flags the overbooked allocation bar and explains it in a tooltip" do
      create(:resource_allocation, entity: wp, principal: assignee, requested_by: user,
                                   start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 6, 5),
                                   allocated_time: 5 * 8 * 60)
      get_events

      bar = block_events.find { |e| e["id"] == allocation.id }
      expect(bar.dig("extendedProps", "overbooked")).to be(true)
      html = bar.dig("extendedProps", "html")
      # The tooltip names the period and contrasts scheduled vs available capacity.
      expect(html).to include("scheduled", "available")
      expect(html).to include("tool-tip")
    end
  end

  describe "working-day background events" do
    # `assignee` already has the factory's Mon-Fri working week; weekends are
    # zero-capacity. `user` has no configured working hours.
    def background_events_for(user)
      get project_resource_planner_view_user_timeline_events_path(
        project, planner, view, start: "2026-06-22", end: "2026-06-29", format: :json
      )
      response.parsed_body["events"]
        .select { |e| e["display"] == "background" }
        .select { |e| e["resourceId"] == user.id }
    end

    it "paints a background run over the user's working days, broken by the weekend" do
      # 2026-06-22 (Mon) .. 2026-06-28 (Sun): one run Mon-Fri, Sat/Sun unpainted.
      events = background_events_for(assignee)

      expect(events).to contain_exactly(
        hash_including("start" => "2026-06-22", "end" => "2026-06-27", # exclusive end => through Fri 06-26
                       "display" => "background", "classNames" => ["op-rm-timeline-active"])
      )
    end

    it "paints nothing for a user without configured working hours" do
      expect(background_events_for(user)).to be_empty
    end
  end

  describe "non-working day events" do
    def non_working_events_for(user)
      get project_resource_planner_view_user_timeline_events_path(
        project, planner, view, start: "2026-06-22", end: "2026-07-13", format: :json
      )
      response.parsed_body["events"]
        .select { |e| (e["classNames"] || []).include?("op-rm-timeline-non-working") }
        .select { |e| e["resourceId"] == user.id }
    end

    it "emits a blue normal event for a user's time off, labelled with the working days lost" do
      create(:user_non_working_time, user: assignee,
                                     start_date: Date.new(2026, 6, 29), end_date: Date.new(2026, 7, 3))

      events = non_working_events_for(assignee)
      expect(events).to contain_exactly(hash_including("start" => "2026-06-29", "end" => "2026-07-04"))
      expect(events.first).not_to have_key("display") # a normal event, not a background span
      expect(events.first.dig("extendedProps", "html"))
        .to include(I18n.t("label_x_working_days_time_off", count: 5))
    end

    it "emits a global holiday on every user's row" do
      create(:non_working_day, date: Date.new(2026, 7, 1), name: "Republic Day")

      [user, assignee].each do |u|
        events = non_working_events_for(u)
        expect(events).to include(
          hash_including("start" => "2026-07-01", "end" => "2026-07-02")
        )
        expect(events.find { |e| e["start"] == "2026-07-01" }.dig("extendedProps", "html"))
          .to include("Republic Day")
      end
    end
  end
end
