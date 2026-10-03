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

RSpec.describe "API v3 work package form with type scheme" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:epic)  { create(:type) }
  shared_let(:story) { create(:type) }
  shared_let(:bug)   { create(:type) }
  shared_let(:project) { create(:project, types: [epic, story, bug]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end

  before do
    ProjectTypeScheme.create!(project:, scheme: create(:type_scheme, types: [story, epic]))
    login_as(user)
  end

  it "reports an error on type when the type is outside the scheme" do
    payload = { subject: "x",
                _links: { type: { href: api_v3_paths.type(bug.id) },
                          project: { href: api_v3_paths.project(project.id) } } }
    post api_v3_paths.create_work_package_form, payload.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response).to have_http_status(:ok)
    expect(JSON.parse(last_response.body).dig("_embedded", "validationErrors")).to have_key("type")
  end

  it "lists only scheme types, default first, in the schema type.allowedValues" do
    payload = { subject: "x",
                _links: { type: { href: api_v3_paths.type(story.id) },
                          project: { href: api_v3_paths.project(project.id) } } }
    post api_v3_paths.create_work_package_form, payload.to_json, "CONTENT_TYPE" => "application/json"

    allowed = JSON.parse(last_response.body).dig("_embedded", "schema", "type", "_links", "allowedValues")
    expect(allowed).not_to be_nil, last_response.body[0, 2000]
    hrefs = allowed.pluck("href")
    expect(hrefs).to eq([api_v3_paths.type(story.id), api_v3_paths.type(epic.id)])
  end
end
