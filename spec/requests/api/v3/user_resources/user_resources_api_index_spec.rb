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
require "rack/test"

RSpec.describe API::V3::UserResources::UserResourcesAPI,
               "index",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:developer) { create(:user_resource, name: "Senior Developer") }
  shared_let(:designer) { create(:user_resource, name: "Product Designer") }

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }

  let(:parsed_response) { JSON.parse(last_response.body) }
  let(:send_request) { get api_v3_paths.user_resources }

  current_user { user }

  before { send_request }

  context "for an admin user" do
    let(:user) { create(:admin) }

    it_behaves_like "API V3 collection response", 2, 2, "UserResource"

    it "renders the name" do
      element = parsed_response["_embedded"]["elements"].find { |e| e["id"] == developer.id }

      expect(element["name"]).to eq("Senior Developer")
    end
  end

  context "when searching by name" do
    let(:user) { create(:admin) }
    let(:send_request) do
      get api_v3_paths.path_for(:user_resources,
                                filters: [{ any_name_attribute: { operator: "**", values: ["design"] } }])
    end

    it "returns only the matching resource" do
      expect(parsed_response["_embedded"]["elements"].pluck("id")).to contain_exactly(designer.id)
    end
  end

  # Resources are a global catalogue rather than project members, so the
  # membership-based principal rules never apply to them.
  context "for a user without access to any resource planner" do
    let(:user) { create(:user) }

    it_behaves_like "API V3 collection response", 0, 0, "UserResource"
  end

  context "for a user who may view a resource planner" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    it_behaves_like "API V3 collection response", 2, 2, "UserResource"
  end
end
