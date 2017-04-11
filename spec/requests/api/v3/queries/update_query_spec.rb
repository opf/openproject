#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe "PATCH /api/v3/queries/:id", type: :request do
  let(:user) { FactoryGirl.create :admin }
  let(:status) { FactoryGirl.create :status }
  let(:project) { FactoryGirl.create :project }

  def json
    JSON.parse response.body
  end

  let!(:query) do
    FactoryGirl.create(
      :global_query,
      name: "A Query",
      user: user,
      is_public: false,
      show_hierarchies: false,
      display_sums: false
    )
  end

  let(:params) do
    {
      name: "Dummy Query",
      public: true,
      showHierarchies: false,
      filters: [
        {
          name: "Status",
          _links: {
            filter: {
              href: "/api/v3/queries/filters/status"
            },
            operator: {
              "href": "/api/v3/queries/operators/="
            },
            schema: {
              "href": "/api/v3/queries/filter_instance_schemas/status"
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

  before do
    login_as user
  end

  describe "updating a query" do
    before do
      patch "/api/v3/queries/#{query.id}",
            params: params.to_json,
            headers: { "Content-Type": "application/json" }
    end

    it 'should return 200 (ok)' do
      expect(response.status).to eq(200)
    end

    it 'should render the updated query' do
      json = JSON.parse(response.body)

      expect(json["_type"]).to eq "Query"
      expect(json["name"]).to eq "Dummy Query"
    end

    it 'should update the query correctly' do
      query = Query.first

      expect(query.group_by_column.name).to eq :assigned_to
      expect(query.sort_criteria).to eq [["id", "desc"], ["assigned_to", "asc"]]
      expect(query.columns.map(&:name)).to eq [:id, :subject, :status, :assigned_to]
      expect(query.project).to eq project
      expect(query.is_public).to eq true
      expect(query.display_sums).to eq false

      expect(query.filters.size).to eq 1
      filter = query.filters.first

      expect(filter.name).to eq :status_id
      expect(filter.operator).to eq "="
      expect(filter.values).to eq [status.id.to_s]
    end

    describe "with empty params" do
      let(:params) { {} }

      it "should not change anything" do
        json = JSON.parse(response.body)

        expect(json["_type"]).to eq "Query"
        expect(json["name"]).to eq "A Query"
      end
    end
  end

  context "with invalid parameters" do
    def post!
      patch "/api/v3/queries/#{query.id}",
            params: params.to_json,
            headers: { "Content-Type": "application/json" }
    end

    it "yields a 422 error given an unknown project" do
      params[:_links][:project][:href] = "/api/v3/projects/#{project.id}42"

      post!

      expect(response.status).to eq 422
      expect(json["message"]).to eq "Project not found"
    end

    it "yields a 422 error given an unknown operator" do
      params[:filters][0][:_links][:operator][:href] = "/api/v3/queries/operators/wut"

      post!

      expect(response.status).to eq 422
      expect(json["message"]).to eq "Status Operator is not included in the list"
    end

    it "yields a 422 error given an unknown filter" do
      params[:filters][0][:_links][:filter][:href] = "/api/v3/queries/filters/statuz"

      post!

      expect(response.status).to eq 422
      expect(json["message"]).to eq "Statuz does not exist."
    end
  end
end
