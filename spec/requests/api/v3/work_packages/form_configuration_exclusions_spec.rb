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

# The exclusions carried by a form configuration link have to reach every endpoint that
# reports what a work package's type offers: the schema (attribute groups and writable
# fields), the work package itself, and the update form.
RSpec.describe "API v3 form configuration exclusions", content_type: :json,
                                                       with_flag: { type_variants: true } do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:kept_field) { create(:issue_custom_field, :integer, name: "Kept", is_for_all: true) }
  shared_let(:excluded_field) { create(:issue_custom_field, :integer, name: "Excluded", is_for_all: true) }
  shared_let(:solo_field) { create(:issue_custom_field, :integer, name: "Solo", is_for_all: true) }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }
  let(:current_user) { create(:admin) }

  let(:owner_type) { create(:type) }
  let(:owner) do
    owner_type.default_variant.tap do |variant|
      variant.attribute_groups = [
        ["Numbers", [kept_field.attribute_name, excluded_field.attribute_name]],
        ["Solo", [solo_field.attribute_name]]
      ]
      variant.custom_field_ids = [kept_field.id, excluded_field.id, solo_field.id]
      variant.save!
    end
  end

  let(:leaf) { create(:type) }
  let(:project) { create(:project, types: [owner_type, leaf]) }

  let(:work_package) do
    create(:work_package, project:, type: leaf,
                          custom_values: {
                            kept_field.id => 1,
                            excluded_field.id => 2,
                            solo_field.id => 3
                          })
  end

  let!(:link) do
    link_configuration(leaf, source: owner, aspect: aspect, excluded: [excluded_field.attribute_name,
                                                         solo_field.attribute_name])
  end

  let(:json) { JSON.parse(last_response.body) }

  def group_names
    json.dig("_embedded", "schema", "_attributeGroups")&.map { |group| group["name"] } ||
      json["_attributeGroups"].map { |group| group["name"] }
  end

  def group_attribute_names(name)
    groups = json["_attributeGroups"] || json.dig("_embedded", "schema", "_attributeGroups")
    group = groups.detect { |candidate| candidate["name"] == name }

    group["attributes"]
  end

  before { login_as(current_user) }

  describe "GET /api/v3/work_packages/schemas/:project_id-:type_id" do
    before { get api_v3_paths.work_package_schema(project.id, leaf.id) }

    it "returns HTTP 200" do
      expect(last_response).to have_http_status(:ok)
    end

    it "reports the owner's groups without the excluded field, dropping the emptied group" do
      expect(group_names).to contain_exactly("Numbers")
      expect(group_attribute_names("Numbers")).to eq([kept_field.attribute_name(:camel_case)])
    end

    it "does not offer the excluded fields as writable attributes" do
      expect(json).to have_key(kept_field.attribute_name(:camel_case))
      expect(json).not_to have_key(excluded_field.attribute_name(:camel_case))
      expect(json).not_to have_key(solo_field.attribute_name(:camel_case))
    end
  end

  describe "GET /api/v3/work_packages/:id" do
    before { get api_v3_paths.work_package(work_package.id) }

    it "returns HTTP 200" do
      expect(last_response).to have_http_status(:ok)
    end

    it "renders the kept custom field value" do
      expect(json[kept_field.attribute_name(:camel_case)]).to eq(1)
    end

    it "does not render the excluded custom field values" do
      expect(json).not_to have_key(excluded_field.attribute_name(:camel_case))
      expect(json).not_to have_key(solo_field.attribute_name(:camel_case))
    end
  end

  describe "POST /api/v3/work_packages/:id/form" do
    before do
      post api_v3_paths.work_package_form(work_package.id),
           { lockVersion: work_package.lock_version }.to_json
    end

    it "returns HTTP 200" do
      expect(last_response).to have_http_status(:ok)
    end

    it "reports the narrowed groups in the embedded schema" do
      expect(group_names).to contain_exactly("Numbers")
    end

    it "does not offer the excluded fields for writing" do
      schema = json.dig("_embedded", "schema")

      expect(schema).to have_key(kept_field.attribute_name(:camel_case))
      expect(schema).not_to have_key(excluded_field.attribute_name(:camel_case))
      expect(schema).not_to have_key(solo_field.attribute_name(:camel_case))
    end
  end

  describe "GET /api/v3/work_packages (collection)" do
    before do
      work_package
      get api_v3_paths.work_packages
    end

    it "returns HTTP 200" do
      expect(last_response).to have_http_status(:ok)
    end

    it "does not render the excluded custom fields on the embedded elements" do
      element = json.dig("_embedded", "elements").detect { |wp| wp["id"] == work_package.id }

      expect(element).to have_key(kept_field.attribute_name(:camel_case))
      expect(element).not_to have_key(excluded_field.attribute_name(:camel_case))
    end
  end

  describe "the owning type itself" do
    let(:owner_work_package) do
      create(:work_package, project:, type: owner_type,
                            custom_values: { kept_field.id => 1, excluded_field.id => 2 })
    end

    before { get api_v3_paths.work_package(owner_work_package.id) }

    it "still renders every field" do
      expect(json[kept_field.attribute_name(:camel_case)]).to eq(1)
      expect(json[excluded_field.attribute_name(:camel_case)]).to eq(2)
    end
  end
end
