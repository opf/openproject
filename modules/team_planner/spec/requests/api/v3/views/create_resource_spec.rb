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

require "spec_helper"

RSpec.describe API::V3::Views::ViewsAPI,
               "create",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:permitted_user) { create(:user) }
  shared_let(:role) do
    create(:project_role,
           permissions: %w[view_work_packages
                           save_queries
                           manage_public_queries
                           manage_team_planner])
  end
  shared_let(:project) do
    create(:project,
           members: { permitted_user => role })
  end
  shared_let(:public_query) do
    create(:query,
           project:,
           public: true)
  end

  let(:additional_setup) do
    # to be overwritten by some specs
  end

  let(:body) do
    {
      _links: {
        query: {
          href: api_v3_paths.query(public_query.id)
        }
      }
    }.to_json
  end

  let(:send_request) do
    post api_v3_paths.views_type("team_planner"), body
  end

  current_user { permitted_user }

  subject(:response) { last_response }

  before do
    additional_setup

    send_request
  end

  describe "POST /api/v3/views/team_planner" do
    context "with a user allowed to save the query" do
      it "returns 201 CREATED" do
        expect(response.status)
          .to eq(201)
      end

      it "returns the view" do
        expect(response.body)
          .to be_json_eql("Views::TeamPlanner".to_json)
                .at_path("_type")

        expect(response.body)
          .to be_json_eql(View.last.id.to_json)
                .at_path("id")
      end
    end

    context "with a user not allowed to manage team planners" do
      let(:additional_setup) do
        role.update_attribute(:permissions,
                              %w[view_work_packages
                                 save_queries
                                 manage_public_queries])
      end

      it_behaves_like "unauthorized access"
    end
  end
end
