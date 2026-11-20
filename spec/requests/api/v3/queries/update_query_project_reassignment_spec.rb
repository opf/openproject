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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 Query update project reassignment", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:source_project) { create(:project) }
  shared_let(:target_project) { create(:project) }
  shared_let(:query) { create(:public_query, project: source_project, name: "Board list query") }

  let(:current_user) do
    create(:user, member_with_permissions: {
             source_project => %i[view_work_packages],
             target_project => %i[view_work_packages manage_public_queries]
           })
  end

  let(:path) { api_v3_paths.query(query.id) }
  let(:body) do
    {
      name: "Renamed by attacker",
      _links: {
        project: {
          href: api_v3_paths.project(target_project.id)
        }
      }
    }.to_json
  end

  before do
    login_as current_user
    header "Content-Type", "application/hal+json"
  end

  subject(:response) { patch path, body }

  it "rejects the update at the API layer without manage_public_queries in the source project" do
    expect(response).to have_http_status(:forbidden)
    expect(query.reload).to have_attributes(
      project_id: source_project.id,
      name: "Board list query"
    )
  end
end
