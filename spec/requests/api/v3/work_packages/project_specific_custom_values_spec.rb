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

RSpec.describe "API v3 work packages with project-specific custom field values", content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }

  current_user { create(:admin) }

  let(:custom_field) do
    create(:list_wp_custom_field, :project_specific_allowlist,
           types: [type], possible_values: %w[A B C], multi_value:)
  end
  let(:multi_value) { false }
  let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
  let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
  let(:option_c) { custom_field.custom_options.find_by!(value: "C") }
  let(:work_package) do
    create(:work_package, project:, type:, custom_values: { custom_field.id => stored_values }).reload
  end
  let(:link_name) { custom_field.attribute_name(:camel_case) }
  let(:path) { api_v3_paths.work_package(work_package.id) }
  let(:value_after_patch) { work_package.reload.public_send(custom_field.attribute_getter) }

  before do
    create(:project_specific_value_restriction, project:, custom_option: option_a)
    create(:project_specific_value_restriction, project:, custom_option: option_c)
  end

  context "with a stored value that is no longer available" do
    let(:stored_values) { option_b.id.to_s }

    describe "GET" do
      subject(:response) { get path }

      it "renders the value as undisclosed" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql(API::V3::URN_UNDISCLOSED.to_json).at_path("_links/#{link_name}/href")
        expect(response.body)
          .to be_json_eql(I18n.t(:label_custom_value_no_longer_available).to_json).at_path("_links/#{link_name}/title")
      end
    end

    describe "PATCH" do
      subject(:response) do
        patch path, { lockVersion: work_package.lock_version, _links: { link_name => links } }.to_json
      end

      context "with the undisclosed link" do
        let(:links) { { href: API::V3::URN_UNDISCLOSED } }

        it "keeps the value" do
          expect(response).to have_http_status(:ok)
          expect(value_after_patch).to eq("B")
        end
      end

      context "with an available option" do
        let(:links) { { href: api_v3_paths.custom_option(option_a.id) } }

        it "replaces the value" do
          expect(response).to have_http_status(:ok)
          expect(value_after_patch).to eq("A")
        end
      end
    end
  end

  context "when the stored value is disabled after the work package was rendered",
          with_ee: %i[project_specific_list_values] do
    let(:stored_values) { option_a.id.to_s }

    it "renders the value as undisclosed instead of serving the cached representation" do
      get path
      expect(last_response.body)
        .to be_json_eql(api_v3_paths.custom_option(option_a.id).to_json).at_path("_links/#{link_name}/href")

      CustomFields::ProjectSpecificValues::SetService
        .new(user: current_user, model: custom_field)
        .call(project:, value: option_a, enabled: false)

      get path
      expect(last_response.body).to be_json_eql(API::V3::URN_UNDISCLOSED.to_json).at_path("_links/#{link_name}/href")
    end
  end

  # Restrictions configured while the plan included the feature keep being enforced, so that no
  # value becomes visible in projects that must not see it.
  context "when the enterprise plan no longer includes project-specific values", with_ee: false do
    let(:stored_values) { option_b.id.to_s }

    it "still renders the value that is no longer available as undisclosed" do
      get path

      expect(last_response.body).to be_json_eql(API::V3::URN_UNDISCLOSED.to_json).at_path("_links/#{link_name}/href")
    end

    it "still only allows the values enabled in the project" do
      post api_v3_paths.work_package_form(work_package.id), { lockVersion: work_package.lock_version }.to_json

      field_schema = JSON.parse(last_response.body).dig("_embedded", "schema", link_name)
      expect(field_schema.dig("_links", "allowedValues").pluck("href"))
        .to contain_exactly(api_v3_paths.custom_option(option_a.id), api_v3_paths.custom_option(option_c.id))
    end
  end

  context "for a multi-select field with stored values of which one is no longer available" do
    let(:multi_value) { true }
    let(:stored_values) { [option_a.id.to_s, option_b.id.to_s] }

    subject(:response) do
      patch path, { lockVersion: work_package.lock_version, _links: { link_name => links } }.to_json
    end

    context "when sending the undisclosed link with another option" do
      let(:links) { [{ href: API::V3::URN_UNDISCLOSED }, { href: api_v3_paths.custom_option(option_c.id) }] }

      it "keeps the undisclosed value next to the other option" do
        expect(response).to have_http_status(:ok)
        expect(value_after_patch).to contain_exactly("B", "C")
      end
    end

    context "when sending only another option" do
      let(:links) { [{ href: api_v3_paths.custom_option(option_c.id) }] }

      it "removes the undisclosed value" do
        expect(response).to have_http_status(:ok)
        expect(value_after_patch).to contain_exactly("C")
      end
    end
  end
end
