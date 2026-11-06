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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Endpoints" do
  # rubocop:disable-next RSpec/LeakyLocalVariable
  specification_routes = API::OpenAPI.assemble_spec(Rails.root.join("docs/api/apiv3/openapi-spec.yml"))
                                     .fetch("paths")
                                     .map { |path, methods| methods.keys.map { |method| { method:, path: } } }
                                     .flatten

  # rubocop:disable-next RSpec/LeakyLocalVariable
  implementation_routes = API::V3::Root.routes
                                       .reject { |route| route.request_method == "*" }
                                       .map do |route|
    { method: route.request_method, path: "/api/v3#{route.origin}" }
  end

  describe "implementation of specified routes" do
    specification_routes.each do |route|
      it "must implement #{route[:method].upcase} #{route[:path]}" do
        expect(implementation_routes).to include_route_definition(route)
      end
    end
  end

  describe "specification of implemented routes" do
    implementation_routes.each do |route|
      it "must specify #{route[:method].upcase} #{route[:path]}" do
        if skipped_routes.include?([route[:method], route[:path]])
          skip("specification missing from before test introduction")
        end

        expect(specification_routes).to include_route_definition(route)
      end
    end
  end

  # TODO: Reduce ... at all costs
  def skipped_routes
    @skipped_routes ||= [
      %w[GET /api/v3/allocatable_principals],
      %w[GET /api/v3/allocatable_work_packages],
      %w[GET /api/v3/attachments/:id/content],
      %w[POST /api/v3/backups],
      %w[GET /api/v3/backlog_buckets],
      %w[GET /api/v3/backlog_buckets/:id],
      %w[GET /api/v3/budgets/:id/attachments],
      %w[POST /api/v3/budgets/:id/attachments],
      %w[POST /api/v3/budgets/:id/attachments/prepare],
      %w[GET /api/v3/cost_entries/:id],
      %w[GET /api/v3/cost_types/:id],
      %w[GET /api/v3/documents/:id/attachments],
      %w[POST /api/v3/documents/:id/attachments],
      %w[POST /api/v3/documents/:id/attachments/prepare],
      %w[POST /api/v3/file_links],
      %w[GET /api/v3/github_pull_requests/:id],
      %w[DELETE /api/v3/grids/:id],
      %w[GET /api/v3/grids/:id/attachments],
      %w[POST /api/v3/grids/:id/attachments],
      %w[POST /api/v3/grids/:id/attachments/prepare],
      %w[GET /api/v3/grids/schema],
      %w[GET /api/v3/groups/:id/avatar],
      %w[GET /api/v3/help_texts/:id/attachments],
      %w[POST /api/v3/help_texts/:id/attachments],
      %w[POST /api/v3/help_texts/:id/attachments/prepare],
      %w[GET /api/v3/job_statuses/:job_id],
      %w[GET /api/v3/principals/:id],
      %w[GET /api/v3/projects/:id/labels],
      %w[GET /api/v3/projects/:id/backlog_buckets],
      %w[GET /api/v3/queries/:id/order],
      %w[PATCH /api/v3/queries/:id/order],
      %w[POST /api/v3/queries/:id/ical_url],
      %w[GET /api/v3/queries/group_bys/:id],
      %w[POST /api/v3/render/:render_format],
      %w[GET /api/v3/shares],
      %w[GET /api/v3/shares/:id],
      %w[GET /api/v3/string_objects],
      %w[GET /api/v3/time_entries/:id/available_work_packages],
      %w[GET /api/v3/time_entries/available_work_packages],
      %w[GET /api/v3/users/:id/avatar],
      %w[GET /api/v3/users/:id/preferences],
      %w[PATCH /api/v3/users/:id/preferences],
      %w[POST /api/v3/users/form],
      %w[GET /api/v3/wiki_page_links],
      %w[POST /api/v3/wiki_page_links],
      %w[DELETE /api/v3/wiki_page_links/:wiki_page_link_id],
      %w[GET /api/v3/work_packages/:id/cost_entries],
      %w[GET /api/v3/work_packages/:id/gitlab_issues],
      %w[GET /api/v3/work_packages/:id/gitlab_merge_requests],
      %w[GET /api/v3/work_packages/:id/github_pull_requests],
      %w[GET /api/v3/work_packages/:id/meeting_agenda_items],
      %w[GET /api/v3/work_packages/:id/summarized_costs_by_type],
      %w[GET /api/v3/work_packages/:id/wiki_page_links],
      %w[POST /api/v3/work_packages/:id/wiki_page_links],
      %w[GET /api/v3/work_packages/:id/relations],
      %w[GET /api/v3/work_packages/available_projects],
      %w[GET /api/v3/work_packages/schemas/sums],
      %w[POST /api/v3/workspaces/:id/form]
    ]
  end
end
