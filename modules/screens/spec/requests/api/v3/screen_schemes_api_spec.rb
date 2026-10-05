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
# frozen_string_literal: true

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 screen schemes" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }
  shared_let(:user) { create(:user) }
  shared_let(:type) { create(:type) }
  shared_let(:scheme) { create(:screen_scheme, name: "Dev") }
  shared_let(:create_screen) { create(:create_screen) }

  let(:json) { JSON.parse(last_response.body) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  it "lets a logged in user read schemes" do
    login_as(user)
    get api_v3_paths.screen_schemes
    expect(last_response).to have_http_status(:ok)
    expect(json["_embedded"]["elements"].pluck("name")).to include("Dev")
  end

  it "forbids writes for non administrators" do
    login_as(user)
    post api_v3_paths.screen_schemes, { name: "X" }.to_json, headers
    expect(last_response).to have_http_status(:forbidden)
  end

  it "creates a scheme with type items as administrator" do
    login_as(admin)
    body = { name: "New", typeItems: [{ typeId: type.id, createScreen: create_screen.id }] }
    post api_v3_paths.screen_schemes, body.to_json, headers
    expect(last_response).to have_http_status(:created)
    expect(json["typeItems"].first.dig("_links", "createScreen", "href")).to be_present
  end
end
