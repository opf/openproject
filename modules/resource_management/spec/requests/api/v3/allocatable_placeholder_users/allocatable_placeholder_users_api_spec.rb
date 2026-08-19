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

RSpec.describe API::V3::AllocatablePlaceholderUsers::AllocatablePlaceholderUsersAPI,
               "index",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }

  shared_let(:with_criteria) do
    filters = UserQuery.new.tap { |query| query.where("name", "~", ["dev"]) }.filters
    create(:placeholder_user, name: "Senior Developer", user_filter: filters)
  end

  shared_let(:without_criteria) { create(:placeholder_user, name: "Just a seat") }

  let(:parsed_response) { JSON.parse(last_response.body) }
  let(:send_request) { get api_v3_paths.allocatable_placeholder_users }

  current_user { user }

  before { send_request }

  context "for a user who may allocate" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
    end

    it "returns only the placeholders describing who they stand for" do
      expect(parsed_response["_embedded"]["elements"].pluck("id")).to contain_exactly(with_criteria.id)
    end

    # The point of the endpoint: allocating must not require the permissions
    # that administering placeholder users does.
    it "does so without the permissions /placeholder_users demands" do
      expect(user.allowed_globally?(:manage_placeholder_user)).to be(false)
      expect(PlaceholderUser.visible(user)).to be_empty
    end
  end

  context "when searching by name" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners allocate_user_resources] })
    end

    let(:send_request) do
      get api_v3_paths.path_for(:allocatable_placeholder_users,
                                filters: [{ any_name_attribute: { operator: "**", values: ["senior"] } }])
    end

    it "returns the matching placeholder" do
      expect(parsed_response["_embedded"]["elements"].pluck("id")).to contain_exactly(with_criteria.id)
    end
  end

  context "for a user who may not allocate" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    it "returns nothing" do
      expect(parsed_response["_embedded"]["elements"]).to be_empty
    end
  end
end
