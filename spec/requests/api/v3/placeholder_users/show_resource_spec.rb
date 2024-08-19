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
require_relative "show_resource_examples"

RSpec.describe API::V3::PlaceholderUsers::PlaceholderUsersAPI,
               "show" do
  include API::V3::Utilities::PathHelper

  shared_let(:placeholder) { create(:placeholder_user, name: "foo") }

  let(:send_request) do
    header "Content-Type", "application/json"
    get api_v3_paths.placeholder_user(placeholder.id)
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  current_user { user }

  before do
    send_request
  end

  describe "admin user" do
    let(:user) { build(:admin) }

    it_behaves_like "represents the placeholder"
  end

  describe "user with manage_placeholder_user permission" do
    let(:user) { create(:user, global_permissions: %i[manage_placeholder_user]) }

    it_behaves_like "represents the placeholder"
  end

  describe "user with manage_members permission" do
    let(:role) { create(:project_role, permissions: %i[manage_members]) }
    let(:project) { create(:project, members: { placeholder => role }) }
    let(:user) { create(:user, member_with_roles: { project => role }) }

    it_behaves_like "represents the placeholder"
  end

  describe "unauthorized user" do
    let(:user) { build(:user) }

    it "returns a 403 response" do
      expect(last_response).to have_http_status(:forbidden)
    end
  end
end
