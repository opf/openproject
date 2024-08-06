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
require "rack/test"

RSpec.describe API::V3::PlaceholderUsers::PlaceholderUsersAPI,
               "index",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:placeholder1) { create(:placeholder_user, name: "foo") }
  shared_let(:placeholder2) { create(:placeholder_user, name: "bar") }

  let(:send_request) do
    get api_v3_paths.placeholder_users
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  current_user { user }

  before do
    send_request
  end

  context "for an admin user" do
    let(:user) { build(:admin) }

    it_behaves_like "API V3 collection response", 2, 2, "PlaceholderUser"
  end

  context "when signaling for the desired properties" do
    let(:user) { build(:admin) }
    let(:send_request) do
      get api_v3_paths.path_for :placeholder_users, select: "total,count,elements/*"
    end

    let(:expected) do
      {
        total: 2,
        count: 2,
        _embedded: {
          elements: [
            {
              _type: "PlaceholderUser",
              id: placeholder2.id,
              name: placeholder2.name,
              _links: {
                self: {
                  href: api_v3_paths.placeholder_user(placeholder2.id),
                  title: placeholder2.name
                }
              }
            },
            {
              _type: "PlaceholderUser",
              id: placeholder1.id,
              name: placeholder1.name,
              _links: {
                self: {
                  href: api_v3_paths.placeholder_user(placeholder1.id),
                  title: placeholder1.name
                }
              }
            }
          ]
        }
      }
    end

    it "is the reduced set of properties of the embedded elements" do
      expect(last_response.body)
        .to be_json_eql(expected.to_json)
    end
  end

  context "for a user with manage_placeholder_user permission" do
    let(:user) { create(:user, global_permissions: %i[manage_placeholder_user]) }

    it_behaves_like "API V3 collection response", 2, 2, "PlaceholderUser"
  end

  context "for a user with manage_members permission" do
    let(:project) { create(:project) }
    let(:user) { create(:user, member_with_permissions: { project => %i[manage_members] }) }

    it_behaves_like "API V3 collection response", 2, 2, "PlaceholderUser"
  end

  context "for an unauthorized user" do
    let(:user) { build(:user) }

    it_behaves_like "API V3 collection response", 0, 0, "PlaceholderUser"
  end
end
