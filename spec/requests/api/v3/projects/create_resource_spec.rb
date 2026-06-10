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

RSpec.describe "API v3 Project resource create", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:custom_field) do
    create(:text_project_custom_field)
  end
  let(:admin_only_custom_field) do
    create(:text_project_custom_field, admin_only: true)
  end
  let(:custom_value) do
    CustomValue.create(custom_field:,
                       value: "1234",
                       customized: project)
  end
  let(:global_role) do
    create(:global_role, permissions:)
  end
  let(:permissions) { [:add_project] }
  let(:path) { api_v3_paths.projects }
  let(:body) do
    {
      identifier: "new_project_identifier",
      name: "Project name"
    }.to_json
  end

  current_user { create(:user, global_permissions: permissions) }

  before do
    post path, body
  end

  it "responds with 201 CREATED" do
    expect(last_response).to have_http_status(:created)
  end

  it "creates a project" do
    expect(Project.count)
      .to be(1)
  end

  it "returns the created project" do
    expect(last_response.body)
      .to be_json_eql("Project".to_json)
      .at_path("_type")
    expect(last_response.body)
      .to be_json_eql("Project name".to_json)
      .at_path("name")
  end

  context "with an all-numeric name and no identifier",
          with_settings: { work_packages_identifier: "classic" } do
    let(:body) { { name: "12345" }.to_json }

    it "responds with 201 CREATED" do
      expect(last_response).to have_http_status(:created)
    end

    it "creates the project with a valid non-all-numeric identifier" do
      expect(Project.last.identifier).to match(Projects::Identifier::CLASSIC_FORMAT)
    end
  end

  context "with a status" do
    let(:body) do
      {
        identifier: "new_project_identifier",
        name: "Project name",
        statusExplanation: { raw: "Some explanation." },
        _links: {
          status: {
            href: api_v3_paths.project_status("off_track")
          }
        }
      }.to_json
    end

    it "sets the status" do
      expect(last_response.body)
        .to be_json_eql(api_v3_paths.project_status("off_track").to_json)
              .at_path("_links/status/href")

      expect(last_response.body)
        .to be_json_eql(
          {
            format: "markdown",
            html: "<p class=\"op-uc-p\">Some explanation.</p>",
            raw: "Some explanation."
          }.to_json
        )
        .at_path("statusExplanation")
    end

    it "creates a project" do
      expect(Project.count)
        .to be(1)
    end
  end

  describe "custom fields" do
    shared_examples "creates a project with a custom value" do |custom_value|
      it "responds with 201" do
        expect(last_response).to have_http_status(:created)
      end

      it "returns the newly created project" do
        expect(last_response.body)
          .to be_json_eql("Project".to_json)
                .at_path("_type")

        expect(last_response.body)
          .to be_json_eql("Project name".to_json)
                .at_path("name")
      end

      it "creates a project with an empty custom field value" do
        project = Project.last
        expect(project.typed_custom_value_for(shared_custom_field))
          .to eq(custom_value)
      end

      it "automatically activates the cf for project" do
        expect(Project.last.project_custom_fields)
          .to contain_exactly(shared_custom_field)
      end
    end

    context "with an optional custom field" do
      shared_let(:shared_custom_field) do
        create(:text_project_custom_field,
               name: "Department",
               is_for_all: true)
      end

      context "when no custom field value is provided" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name"
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", ""
      end

      context "when the custom field is provided but empty" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: ""
            }
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", ""
      end

      context "when the custom field value is provided and valid" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: "Engineering"
            }
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", "Engineering"
      end
    end

    context "when a custom field has a default value" do
      shared_let(:shared_custom_field) do
        create(:text_project_custom_field,
               name: "Location",
               is_for_all: false,
               default_value: "Default Location")
      end

      context "when the custom field value is provided and valid" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: "Custom Location"
            }
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", "Custom Location"
      end

      context "when the custom field value is identical to the default" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: "Default Location"
            }
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", "Default Location"
      end

      context "when the custom field value is blank" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: ""
            }
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", ""
      end
    end

    context "with a required for_all custom field" do
      shared_let(:shared_custom_field) do
        create(:text_project_custom_field,
               name: "Department",
               is_required: true,
               is_for_all: true)
      end

      context "when no custom field value is provided" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name"
          }.to_json
        end

        it "responds with 422 and explains the custom field error" do
          expect(last_response).to have_http_status(:unprocessable_entity)

          expect(last_response.body)
            .to be_json_eql("Department can't be blank.".to_json)
            .at_path("message")
        end
      end

      context "when the custom field is provided but empty" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: ""
            }
          }.to_json
        end

        it "responds with 422 and explains the custom field error" do
          expect(last_response).to have_http_status(:unprocessable_entity)

          expect(last_response.body)
            .to be_json_eql("Department can't be blank.".to_json)
            .at_path("message")
        end
      end

      context "when the custom field value is provided and valid" do
        let(:body) do
          {
            identifier: "new_project_identifier",
            name: "Project name",
            shared_custom_field.attribute_name(:camel_case) => {
              raw: "Engineering"
            }
          }.to_json
        end

        it_behaves_like "creates a project with a custom value", "Engineering"
      end

      context "with another custom field present" do
        shared_let(:other_custom_field) do
          create(:text_project_custom_field,
                 name: "Other CF")
        end

        context "when a value for the other cf is provided but the required one is missing (regression #70107)" do
          let(:body) do
            {
              identifier: "new_project_identifier",
              name: "Project name",
              other_custom_field.attribute_name(:camel_case) => {
                raw: "Other value"
              }
            }.to_json
          end

          it "responds with 422 and explains the custom field error" do
            expect(last_response).to have_http_status(:unprocessable_entity)

            expect(last_response.body)
              .to be_json_eql("Department can't be blank.".to_json)
                    .at_path("message")
          end
        end
      end

      context "with another custom field present that is required but not for_all" do
        shared_let(:required_not_for_all_custom_field) do
          create(:text_project_custom_field,
                 name: "Not for all CF",
                 is_required: true,
                 is_for_all: false)
        end

        context "when a value for the required field is provided, but no value for the required not for_all custom_field" do
          let(:body) do
            {
              identifier: "new_project_identifier",
              name: "Project name",
              shared_custom_field.attribute_name(:camel_case) => {
                raw: "Engineering"
              }
            }.to_json
          end

          it "responds with 201 and does not validate the required not for_all custom_field" do
            expect(last_response).to have_http_status(:created)
          end
        end
      end
    end

    context "with a visible custom field" do
      let(:body) do
        {
          identifier: "new_project_identifier",
          name: "Project name",
          custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          }
        }.to_json
      end

      it "sets the cf value" do
        expect(last_response.body)
          .to be_json_eql("CF text".to_json)
          .at_path("customField#{custom_field.id}/raw")
      end

      it "automatically activates the cf for project if the value was provided" do
        expect(Project.last.project_custom_fields)
          .to contain_exactly(custom_field)
      end
    end

    context "with an admin only custom field" do
      let(:body) do
        {
          identifier: "new_project_identifier",
          name: "Project name",
          admin_only_custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          }
        }.to_json
      end

      context "with admin permissions" do
        current_user { create(:admin) }

        it "sets the cf value" do
          expect(last_response.body)
            .to be_json_eql("CF text".to_json)
            .at_path("customField#{admin_only_custom_field.id}/raw")
        end

        it "automatically activates the cf for project if the value was provided" do
          expect(Project.last.project_custom_fields)
            .to contain_exactly(admin_only_custom_field)
        end
      end

      context "with non-admin permissions" do
        it "does not set the cf value" do
          expect(last_response.body)
            .not_to have_json_path("customField#{admin_only_custom_field.id}/raw")
        end

        it "does not activate the cf for project" do
          expect(Project.last.project_custom_fields)
            .to be_empty
        end

        context "and when the custom field is required" do
          let(:admin_only_custom_field) do
            create(:text_project_custom_field, admin_only: true, is_required: true)
          end
          let(:body) do
            {
              identifier: "new_project_identifier",
              name: "Project name"
            }.to_json
          end

          it "responds with 201" do
            expect(last_response).to have_http_status(:created)
          end

          it "does not set the cf value" do
            expect(last_response.body)
              .not_to have_json_path("customField#{admin_only_custom_field.id}/raw")
          end

          it "does not activate the cf for project" do
            expect(Project.last.project_custom_fields)
              .to be_empty
          end
        end
      end
    end
  end

  context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
    context "when identifier is not provided" do
      let(:body) do
        { name: "Flight Planning Algorithm" }.to_json
      end

      it "responds with 201 CREATED" do
        expect(last_response).to have_http_status(:created)
      end

      it "auto-generates a semantic identifier from the name" do
        expect(last_response.body)
          .to be_json_eql("FPA".to_json)
          .at_path("identifier")
      end
    end

    context "when auto-generated identifier already exists" do
      # The outer before already created a project with identifier "FPA".
      # A second request with the same name must resolve the collision automatically.
      let(:body) do
        { name: "Flight Planning Algorithm" }.to_json
      end

      it "responds with 201 and generates the next unique identifier" do
        post path, body
        expect(last_response).to have_http_status(:created)
        expect(last_response.body)
          .to be_json_eql("FLPA".to_json)
          .at_path("identifier")
      end
    end

    context "when an invalid identifier is provided" do
      let(:body) do
        {
          name: "Flight Planning Algorithm",
          identifier: "1ABC"
        }.to_json
      end

      it "responds with 422" do
        expect(last_response).to have_http_status(:unprocessable_entity)
      end

      it "explains the identifier format error" do
        expect(last_response.body)
          .to be_json_eql("Identifier must start with a letter".to_json)
          .at_path("message")
      end
    end
  end

  context "without permission to create projects" do
    let(:permissions) { [] }

    it "responds with 403" do
      expect(last_response).to have_http_status(:forbidden)
    end

    it "creates no project" do
      expect(Project.count)
        .to be(0)
    end
  end

  context "with missing name" do
    let(:body) do
      {
        identifier: "some_identifier"
      }.to_json
    end

    it "responds with 422" do
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "creates no project" do
      expect(Project.count)
        .to be(0)
    end

    it "denotes the error" do
      expect(last_response.body)
        .to be_json_eql("Error".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql("Name can't be blank.".to_json)
        .at_path("message")
    end
  end

  context "with a faulty status" do
    let(:body) do
      {
        identifier: "new_project_identifier",
        name: "Project name",
        statusExplanation: "Some explanation.",
        _links: {
          status: {
            href: api_v3_paths.project_status("faulty")
          }
        }
      }.to_json
    end

    it "responds with 422" do
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "creates no project" do
      expect(Project.count)
        .to be(0)
    end

    it "denotes the error" do
      expect(last_response.body)
        .to be_json_eql("Error".to_json)
        .at_path("_type")

      expect(last_response.body)
        .to be_json_eql("Status is not set to one of the allowed values.".to_json)
        .at_path("message")
    end
  end
end
