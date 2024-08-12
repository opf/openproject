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

RSpec.describe "PATCH /api/v3/queries/:id",
               with_ee: %i[baseline_comparison] do
  shared_let(:user) { create(:admin) }
  shared_let(:status) { create(:status) }
  shared_let(:project) { create(:project) }
  let(:timestamps) { [1.week.ago.iso8601, "lastWorkingDay@12:00+00:00", "P0D"] }

  let!(:query) do
    create(
      :global_query,
      name: "A Query",
      user:,
      public: false,
      show_hierarchies: false,
      display_sums: false
    )
  end
  let(:params) do
    {
      name: "Dummy Query",
      public: true,
      showHierarchies: false,
      timestamps:,
      filters: [
        {
          name: "Status",
          _links: {
            filter: {
              href: "/api/v3/queries/filters/status"
            },
            operator: {
              href: "/api/v3/queries/operators/="
            },
            schema: {
              href: "/api/v3/queries/filter_instance_schemas/status"
            },
            values: [
              {
                href: "/api/v3/statuses/#{status.id}"
              }
            ]
          }
        }
      ],
      _links: {
        project: {
          href: "/api/v3/projects/#{project.id}"
        },
        columns: [
          {
            href: "/api/v3/queries/columns/id"
          },
          {
            href: "/api/v3/queries/columns/subject"
          },
          {
            href: "/api/v3/queries/columns/status"
          },
          {
            href: "/api/v3/queries/columns/assignee"
          }
        ],
        sortBy: [
          {
            href: "/api/v3/queries/sort_bys/id-desc"
          },
          {
            href: "/api/v3/queries/sort_bys/assignee-asc"
          }
        ],
        groupBy: {
          href: "/api/v3/queries/group_bys/assignee"
        }
      }
    }
  end

  def json
    JSON.parse last_response.body
  end

  before do
    RequestStore.clear!
    login_as user
  end

  describe "updating a query" do
    before do
      header "Content-Type", "application/json"
      patch "/api/v3/queries/#{query.id}", params.to_json
    end

    it "returns 200 (ok)" do
      expect(last_response).to have_http_status(:ok)
    end

    it "renders the updated query" do
      expect(json["_type"]).to eq "Query"
      expect(json["name"]).to eq "Dummy Query"
    end

    it "updates the query correctly" do
      query = Query.first

      expect(query.group_by_column.name).to eq :assigned_to
      expect(query.sort_criteria).to eq [["id", "desc"], ["assigned_to", "asc"]]
      expect(query.columns.map(&:name)).to eq %i[id subject status assigned_to]
      expect(query.project).to eq project
      expect(query.public).to be true
      expect(query.display_sums).to be false

      expect(query.timestamps).to eq(timestamps.map { |t| Timestamp.new(t) })
      expect(query.filters.size).to eq 1
      filter = query.filters.first

      expect(filter.name).to eq :status_id
      expect(filter.operator).to eq "="
      expect(filter.values).to eq [status.id.to_s]
    end

    describe "with empty params" do
      let(:params) { {} }

      it "does not change anything" do
        expect(json["_type"]).to eq "Query"
        expect(json["name"]).to eq "A Query"
      end
    end

    context "without EE", with_ee: false do
      it "yields a 422 error given a timestamp older than 1 day" do
        expect(last_response).to have_http_status :unprocessable_entity
        expect(json["message"]).to eq "Timestamps contain forbidden values: #{timestamps.first}"
      end

      context "when timestamps are within 1 day" do
        let(:timestamps) { ["oneDayAgo@12:00+00:00"] }

        it "returns 200 (ok)" do
          expect(last_response).to have_http_status(:ok)
        end

        it "updates the query timestamps" do
          expect(Query.first.timestamps).to eq(timestamps.map { |t| Timestamp.new(t) })
        end
      end
    end
  end

  context "with invalid parameters" do
    def post!
      header "Content-Type", "application/json"
      patch "/api/v3/queries/#{query.id}", params.to_json
    end

    it "yields a 422 error given an unknown project" do
      params[:_links][:project][:href] = "/api/v3/projects/#{project.id}42"

      post!

      expect(last_response).to have_http_status :unprocessable_entity
      expect(json["message"]).to eq "Project not found"
    end

    it "yields a 422 error given an unknown operator" do
      params[:filters][0][:_links][:operator][:href] = "/api/v3/queries/operators/wut"

      post!

      expect(last_response).to have_http_status :unprocessable_entity
      expect(json["message"]).to eq "Status Operator is not set to one of the allowed values."
    end

    it "yields a 422 error given an unknown filter" do
      params[:filters][0][:_links][:filter][:href] = "/api/v3/queries/filters/statuz"

      post!

      expect(last_response).to have_http_status :unprocessable_entity
      expect(json["message"]).to eq "Statuz filter does not exist."
    end
  end
end
