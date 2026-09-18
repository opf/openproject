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

RSpec.describe "Global timeline feeds", :skip_csrf, type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:visible_project) do
    create(:project, name: "Visible", enabled_module_names: %w[resource_management work_package_tracking])
  end
  shared_let(:secret_project) do
    create(:project, name: "Secret", enabled_module_names: %w[resource_management work_package_tracking])
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: { visible_project => %i[view_resource_planners view_work_packages] },
           global_permissions: %i[view_global_resource_planners])
  end

  # Allocated in both projects, so their bars span work the viewer may and may not see.
  shared_let(:resource) do
    create(:user, firstname: "Rita", lastname: "Resource",
                  member_with_permissions: { visible_project => %i[view_work_packages] })
  end

  shared_let(:visible_wp) { create(:work_package, project: visible_project, subject: "Visible work") }
  shared_let(:secret_wp) { create(:work_package, project: secret_project, subject: "Confidential rocket plans") }

  shared_let(:planner) { create(:resource_planner, :global, principal: user, name: "Capacity") }
  shared_let(:view) do
    ResourceUserTimeline.create!(name: "People", parent: planner, project: nil, principal: user).tap do |v|
      v.update!(query: v.build_default_query.tap { |q| q.name = "People" })
    end
  end

  shared_let(:visible_allocation) do
    create(:resource_allocation, entity: visible_wp, principal: resource, state: :allocated,
                                 start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9),
                                 allocated_time: 600)
  end
  shared_let(:secret_allocation) do
    create(:resource_allocation, entity: secret_wp, principal: resource, state: :allocated,
                                 start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 16),
                                 allocated_time: 600)
  end

  before { login_as(user) }

  def get_events
    get resource_planner_view_user_timeline_events_path(resource_planner_id: planner, view_id: view, format: :json)
    response.parsed_body.fetch("events")
  end

  it "serves the feed on the global route" do
    get resource_planner_view_user_timeline_resources_path(resource_planner_id: planner, view_id: view, format: :json)

    expect(response).to have_http_status(:ok)
  end

  it "renders a bar for an allocation in a project the viewer cannot see" do
    events = get_events

    expect(events.pluck("id")).to include(visible_allocation.id, secret_allocation.id)
  end

  it "never discloses the subject of an invisible work package" do
    body = get_events.to_s

    expect(body).to include("Visible work")
    expect(body).not_to include("Confidential rocket plans")
    expect(body).to include(I18n.t("resource_management.timeline.undisclosed.work_package"))
  end

  it "keeps the allocated hours of invisible work so the load stays accurate" do
    secret_event = get_events.find { |e| e["id"] == secret_allocation.id }

    expect(secret_event.dig("extendedProps", "html")).to include("10h")
  end

  it "names the project on each bar" do
    visible_event = get_events.find { |e| e["id"] == visible_allocation.id }

    expect(visible_event.dig("extendedProps", "html")).to include("Visible")
  end

  it "carries the full project and subject in a tooltip, since the bar truncates" do
    visible_event = get_events.find { |e| e["id"] == visible_allocation.id }

    expect(visible_event.dig("extendedProps", "html")).to include("Visible - Visible work")
  end

  it "does not name a project the viewer cannot see" do
    secret_event = get_events.find { |e| e["id"] == secret_allocation.id }

    expect(secret_event.dig("extendedProps", "html")).not_to include("Secret")
  end

  it "offers no edit url for an allocation the viewer may not change" do
    events = get_events

    expect(events.filter_map { |e| e.dig("extendedProps", "editUrl") }).to be_empty
  end

  context "without the global permission" do
    before { login_as(create(:user, member_with_permissions: { visible_project => %i[view_resource_planners] })) }

    it "is not found" do
      get resource_planner_view_user_timeline_events_path(resource_planner_id: planner, view_id: view, format: :json)

      expect(response).to have_http_status(:not_found)
    end
  end
end
