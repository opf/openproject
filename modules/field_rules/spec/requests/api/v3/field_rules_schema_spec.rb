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

RSpec.describe "API v3 work package schema and writes with field rules" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:project) { create(:project, types: [bug]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end

  let(:rule_set) do
    create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true },
                                              { field_key: "estimated_time", read_only: true },
                                              { field_key: "category", hidden: true }])
  end
  let(:json) { JSON.parse(last_response.body) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  before do
    ProjectFieldRuleScheme.create!(project:, scheme: create(:field_rule_scheme, mapping: { bug => rule_set }))
    login_as(user)
  end

  it "marks required, read-only and hidden fields in the schema" do
    get api_v3_paths.work_package_schema(project.id, bug.id)

    expect(last_response).to have_http_status(:ok)
    expect(json["description"]["required"]).to be(true)
    expect(json["estimatedTime"]["writable"]).to be(false)
    expect(json).not_to have_key("category")
  end

  it "rejects creating a work package without the required field" do
    payload = { subject: "x", _links: { type: { href: api_v3_paths.type(bug.id) },
                                        project: { href: api_v3_paths.project(project.id) } } }
    post api_v3_paths.work_packages, payload.to_json, headers

    expect(last_response).to have_http_status(:unprocessable_entity)
    expect(last_response.body).to include("description")
  end

  it "creates the work package once the required field is given" do
    payload = { subject: "x", description: { raw: "Details" },
                _links: { type: { href: api_v3_paths.type(bug.id) },
                          project: { href: api_v3_paths.project(project.id) } } }
    post api_v3_paths.work_packages, payload.to_json, headers

    expect(last_response).to have_http_status(:created)
  end

  it "rejects writes to a read-only field through the API" do
    work_package = create(:work_package, project:, type: bug, description: "x")
    patch api_v3_paths.work_package(work_package.id), { lockVersion: work_package.lock_version, estimatedTime: "PT2H" }.to_json, headers

    expect(last_response).to have_http_status(:unprocessable_entity)
  end

  it "leaves the schema untouched for projects without a scheme" do
    other = create(:project, types: [bug])
    create(:member, project: other, principal: user, roles: [create(:project_role, permissions: %i[view_work_packages])])
    get api_v3_paths.work_package_schema(other.id, bug.id)

    expect(json).to have_key("category")
  end
end
