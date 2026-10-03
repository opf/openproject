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

RSpec.describe "API v3 field rule sets, schemes and project assignment" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, types: [bug]) }
  shared_let(:admin) { create(:admin) }
  shared_let(:assigner) { create(:user, member_with_permissions: { project => %i[view_work_packages assign_field_rule_scheme] }) }
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:rule_set) { create(:field_rule_set, name: "Bug rules", rule_attributes: [{ field_key: "description", required: true }]) }
  shared_let(:scheme) { create(:field_rule_scheme, name: "Dev", mapping: { bug => rule_set }) }

  let(:json) { JSON.parse(last_response.body) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "rule sets" do
    it "lets any logged in user read them" do
      login_as(viewer)
      get api_v3_paths.field_rule_sets
      expect(last_response).to have_http_status(:ok)
      expect(json["_embedded"]["elements"].pluck("name")).to include("Bug rules")

      get api_v3_paths.field_rule_set(rule_set.id)
      expect(json["rules"].first).to include("fieldKey" => "description", "required" => true)
    end

    it "forbids writes for non administrators" do
      login_as(viewer)
      post api_v3_paths.field_rule_sets, { name: "X", rules: [] }.to_json, headers
      expect(last_response).to have_http_status(:forbidden)
    end

    it "creates and updates as administrator and offers no deletion" do
      login_as(admin)
      body = { name: "Story rules", rules: [{ fieldKey: "priority", hidden: true }] }
      post api_v3_paths.field_rule_sets, body.to_json, headers
      expect(last_response).to have_http_status(:created)
      id = json["id"]

      patch api_v3_paths.field_rule_set(id), { rules: [{ fieldKey: "description", required: true }], active: false }.to_json, headers
      expect(last_response).to have_http_status(:ok)
      expect(FieldRuleSet.find(id)).to have_attributes(active: false)

      delete api_v3_paths.field_rule_set(id)
      expect(last_response.status).to be_in([404, 405])
      expect(FieldRuleSet.exists?(id)).to be true
    end

    it "rejects invalid rules and malformed bodies" do
      login_as(admin)
      post api_v3_paths.field_rule_sets, { name: "Bad", rules: [{ fieldKey: "description", hidden: true, required: true }] }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)

      post api_v3_paths.field_rule_sets, { name: "Bad2", rules: "nope" }.to_json, headers
      expect(last_response).to have_http_status(:bad_request)

      post api_v3_paths.field_rule_sets, { name: "Bad3", rules: [{ fieldKey: { a: 1 } }] }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "hostile input" do
    before { login_as(admin) }

    it "answers 400 for a non-object body" do
      post api_v3_paths.field_rule_sets, [1, 2].to_json, headers
      expect(last_response).to have_http_status(:bad_request)

      put api_v3_paths.project_field_rule_scheme(project.id), "[]", headers
      expect(last_response).to have_http_status(:bad_request)
    end

    it "answers 400 for non-string names and non-boolean flags" do
      post api_v3_paths.field_rule_sets, { name: { a: 1 } }.to_json, headers
      expect(last_response).to have_http_status(:bad_request)

      post api_v3_paths.field_rule_sets, { name: "Flags", rules: [{ fieldKey: "priority", hidden: [1] }] }.to_json, headers
      expect(last_response).to have_http_status(:bad_request)

      patch api_v3_paths.field_rule_set(rule_set.id), { active: "maybe" }.to_json, headers
      expect(last_response).to have_http_status(:bad_request)
    end

    it "answers 400 for oversized lists and 404 for unknown ids" do
      rules = Array.new(API::V3::FieldRules::InputHelpers::MAX_LIST_SIZE + 1) { { fieldKey: "priority" } }
      post api_v3_paths.field_rule_sets, { name: "Huge", rules: }.to_json, headers
      expect(last_response).to have_http_status(:bad_request)

      get api_v3_paths.field_rule_set(2_147_483_647)
      expect(last_response).to have_http_status(:not_found)
    end

    it "does not let a viewer write anything" do
      login_as(viewer)
      patch api_v3_paths.field_rule_scheme(scheme.id), { active: false }.to_json, headers
      expect(last_response).to have_http_status(:forbidden)
      expect(scheme.reload).to be_active
    end
  end

  describe "schemes" do
    it "creates a scheme from links" do
      login_as(admin)
      body = { name: "New scheme", typeItems: [{ _links: { type: { href: api_v3_paths.type(bug.id) },
                                                           ruleSet: { href: api_v3_paths.field_rule_set(rule_set.id) } } }] }
      post api_v3_paths.field_rule_schemes, body.to_json, headers

      expect(last_response).to have_http_status(:created)
      expect(FieldRuleScheme.find(json["id"]).rule_set_for(bug.id)).to eq rule_set
    end

    it "rejects a type twice with 422 and offers no deletion" do
      login_as(admin)
      item = { typeId: bug.id, ruleSetId: rule_set.id }
      post api_v3_paths.field_rule_schemes, { name: "Dup", typeItems: [item, item] }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)

      delete api_v3_paths.field_rule_scheme(scheme.id)
      expect(last_response.status).to be_in([404, 405])
    end
  end

  describe "project assignment and effective rules" do
    it "requires assign_field_rule_scheme" do
      login_as(viewer)
      put api_v3_paths.project_field_rule_scheme(project.id), { scheme_id: scheme.id }.to_json, headers
      expect(last_response).to have_http_status(:forbidden)
    end

    it "assigns, unassigns and refuses unknown or inactive schemes" do
      login_as(assigner)
      put api_v3_paths.project_field_rule_scheme(project.id), { scheme_id: scheme.id }.to_json, headers
      expect(last_response).to have_http_status(:no_content)
      expect(ProjectFieldRuleScheme.find_by(project_id: project.id).scheme).to eq scheme

      put api_v3_paths.project_field_rule_scheme(project.id), { scheme_id: 0 }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)

      put api_v3_paths.project_field_rule_scheme(project.id), { scheme_id: { a: 1 } }.to_json, headers
      expect(last_response).to have_http_status(:unprocessable_entity)

      put api_v3_paths.project_field_rule_scheme(project.id), { scheme_id: nil }.to_json, headers
      expect(last_response).to have_http_status(:no_content)
      expect(ProjectFieldRuleScheme.where(project_id: project.id)).to be_empty
    end

    it "describes the effective rules for a project and type" do
      FieldRules::SchemeService.assign(project, scheme)
      login_as(viewer)
      get api_v3_paths.project_type_field_rules(project.id, bug.id)

      expect(last_response).to have_http_status(:ok)
      expect(json["fields"]).to contain_exactly(include("key" => "description", "required" => true,
                                                         "visibility" => "visible", "source" => "rule_set"))
    end

    it "hides the project from users who cannot see it" do
      login_as(create(:user))
      get api_v3_paths.project_type_field_rules(project.id, bug.id)
      expect(last_response).to have_http_status(:not_found)
    end
  end
end
