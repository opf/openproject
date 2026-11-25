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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.shared_examples_for "APIv3 workspace update" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }

  let(:workspace) do
    create(workspace_factory_key,
           :with_status,
           public: false,
           active: workspace_active)
  end
  let(:workspace_active) { true }
  let(:custom_field) do
    create(:text_project_custom_field)
  end
  let(:admin_only_custom_field) do
    create(:text_project_custom_field, admin_only: true)
  end
  let(:permissions) { %i[edit_project view_project_attributes edit_project_attributes] }
  let(:body) do
    {
      identifier: "new_workspace_identifier",
      name: "Project name"
    }
  end

  current_user do
    create(:user, member_with_permissions: { workspace => permissions })
  end

  before do
    patch path, body.to_json
  end

  it "responds with 200 OK" do
    expect(last_response).to have_http_status(:ok)
  end

  it "alters the workspace" do
    workspace.reload

    expect(workspace.name)
      .to eql(body[:name])

    expect(workspace.identifier)
      .to eql(body[:identifier])
  end

  it "returns the updated workspace" do
    expect(last_response.body)
      .to be_json_eql(workspace_api_type.to_json)
            .at_path("_type")
    expect(last_response.body)
      .to be_json_eql(body[:name].to_json)
            .at_path("name")
  end

  describe "custom fields" do
    context "with a required for_all custom field" do
      let!(:required_custom_field) do
        create(:text_project_custom_field,
               name: "Department",
               is_for_all: true,
               is_required: true)
      end

      context "when no custom field value is provided" do
        let(:body) do
          {
            name: "Updated workspace name"
          }
        end

        it "responds with 200" do
          expect(last_response).to have_http_status(:ok)

          expect(last_response.body)
            .to be_json_eql("Updated workspace name".to_json)
                  .at_path("name")
        end

        it "keeps the custom field value empty" do
          expect(workspace.reload.typed_custom_value_for(required_custom_field))
            .to be_empty
        end
      end

      context "when the custom field is provided but empty" do
        let(:body) do
          {
            name: "Updated workspace name",
            required_custom_field.attribute_name(:camel_case) => {
              raw: ""
            }
          }
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
            name: "Updated workspace name",
            required_custom_field.attribute_name(:camel_case) => {
              raw: "Engineering"
            }
          }
        end

        it "responds with 200" do
          expect(last_response).to have_http_status(:ok)
        end

        it "returns the updated workspace" do
          expect(last_response.body)
            .to be_json_eql(workspace_api_type.to_json)
                  .at_path("_type")

          expect(last_response.body)
            .to be_json_eql("Updated workspace name".to_json)
                  .at_path("name")
        end

        it "updates the workspace with the custom field value" do
          expect(workspace.reload.typed_custom_value_for(required_custom_field))
            .to eq("Engineering")
        end

        it "keeps the cf activated for the workspace" do
          expect(workspace.reload.project_custom_fields)
            .to include(required_custom_field)
        end
      end
    end

    context "with a visible custom field" do
      let(:body) do
        {
          custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          }
        }
      end

      it "responds with 200 OK" do
        expect(last_response).to have_http_status(:ok)
      end

      it "sets the cf value" do
        expect(workspace.reload.send(custom_field.attribute_getter))
          .to eql("CF text")
      end

      it "automatically activates the cf for workspace if the value was provided" do
        expect(workspace.project_custom_fields)
          .to contain_exactly(custom_field)
      end

      context "when the field is for_all, but not required" do
        let!(:for_all_custom_field) do
          create(:text_project_custom_field,
                 name: "Department",
                 is_for_all: true)
        end

        it "automatically activates the cf for workspace even if no value was provided" do
          expect(workspace.project_custom_fields)
            .to contain_exactly(for_all_custom_field, custom_field)
        end
      end
    end

    context "with an admin only custom field" do
      let(:body) do
        {
          admin_only_custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          }
        }
      end

      context "with admin permissions" do
        current_user { admin }

        it "responds with 200 OK" do
          expect(last_response).to have_http_status(:ok)
        end

        it "sets the cf value" do
          expect(workspace.reload.send(admin_only_custom_field.attribute_getter))
            .to eql("CF text")
        end

        it "automatically activates the cf for workspace if the value was provided" do
          expect(workspace.reload.project_custom_fields)
            .to contain_exactly(admin_only_custom_field)
        end
      end

      context "with non-admin permissions" do
        it "responds with 200 OK" do
          # TBD: trying to set a not accessible custom field is silently ignored
          expect(last_response).to have_http_status(:ok)
        end

        it "does not set the cf value" do
          expect(workspace.reload.custom_values.find_by(custom_field: admin_only_custom_field))
            .to have_attributes(value: nil)
        end

        context "when the hidden field has a value already" do
          before do
            workspace.update!(custom_field_values: { admin_only_custom_field.id => "1234" })

            patch path, body.to_json
          end

          it "does not change the cf value" do
            expect(workspace.reload.custom_values.find_by(custom_field: admin_only_custom_field))
              .to have_attributes(value: "1234")
          end
        end

        it "does not activate the cf for workspace" do
          expect(workspace.reload.project_custom_fields)
            .to be_empty
        end

        context "and when the custom field is required" do
          let(:admin_only_custom_field) do
            create(:text_project_custom_field, admin_only: true, is_required: true)
          end
          let(:body) do
            {
              name: "Updated workspace name"
            }
          end

          it "responds with 200 OK" do
            expect(last_response).to have_http_status(:ok)
          end

          it "does not set the cf value" do
            expect(workspace.reload.typed_custom_value_for(admin_only_custom_field))
              .to be_nil
          end

          it "does not activate the cf for workspace" do
            expect(workspace.reload.project_custom_fields)
              .to be_empty
          end
        end

        context "and when the custom field is forced active (is_for_all)" do
          let(:admin_only_custom_field) do
            create(:text_project_custom_field, admin_only: true, is_for_all: true)
          end
          let(:body) do
            {
              name: "Updated workspace name"
            }
          end

          it "responds with 200 OK" do
            expect(last_response).to have_http_status(:ok)
          end

          it "does not set the cf value" do
            expect(workspace.reload.typed_custom_value_for(admin_only_custom_field))
              .to be_nil
          end

          it "does activate the cf for workspace" do
            expect(workspace.reload.project_custom_fields)
              .to contain_exactly(admin_only_custom_field)
          end
        end
      end
    end
  end

  describe "permissions" do
    context "without permission to patch workspaces" do
      let(:permissions) { [] }

      it "responds with 403" do
        expect(last_response).to have_http_status(:forbidden)
      end

      it "does not change the workspace" do
        attributes_before = workspace.attributes

        expect(workspace.reload.name)
          .to eql(attributes_before["name"])
      end

      context "and with edit_workspace_attributes permission" do
        let(:permissions) { [:edit_project_attributes] }
        let(:body) do
          {
            custom_field.attribute_name(:camel_case) => {
              raw: "CF text"
            }
          }
        end

        it "responds with 403" do
          expect(last_response).to have_http_status(:forbidden)
        end

        it "does not change the workspace" do
          attributes_before = workspace.attributes
          custom_field_value_before = workspace.send(custom_field.attribute_getter)

          expect(workspace.reload.name)
            .to eql(attributes_before["name"])
          expect(workspace.send(custom_field.attribute_getter))
            .to eq custom_field_value_before
        end
      end
    end

    context "with edit_workspace permission" do
      let(:permissions) { [:edit_project] }

      it "responds with 200 OK" do
        expect(last_response).to have_http_status(:ok)
      end

      it "alters the workspace" do
        workspace.reload

        expect(workspace.name)
          .to eql(body[:name])

        expect(workspace.identifier)
          .to eql(body[:identifier])
      end

      context "when custom_field values are updated without edit_project_attributes" do
        let(:body) do
          {
            custom_field.attribute_name(:camel_case) => {
              raw: "CF text"
            }
          }
        end

        it "responds with 422" do
          expect(last_response).to have_http_status(:unprocessable_entity)
        end

        it "does not change the workspace" do
          attributes_before = workspace.attributes
          custom_field_value_before = workspace.send(custom_field.attribute_getter)

          expect(workspace.reload.name)
            .to eql(attributes_before["name"])
          expect(workspace.send(custom_field.attribute_getter))
            .to eq custom_field_value_before
        end
      end
    end
  end

  context "with a nil status" do
    let(:body) do
      {
        statusExplanation: {
          raw: "Some explanation."
        },
        _links: {
          status: {
            href: nil
          }
        }
      }
    end

    it "alters the status" do
      expect(last_response.body)
        .to be_json_eql(nil.to_json)
              .at_path("_links/status/href")

      workspace.reload
      expect(workspace.status_code).to be_nil
      expect(workspace.status_explanation).to eq "Some explanation."

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
  end

  context "with a status" do
    let(:body) do
      {
        statusExplanation: {
          raw: "Some explanation."
        },
        _links: {
          status: {
            href: api_v3_paths.project_status("off_track")
          }
        }
      }
    end

    it "alters the status" do
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

    it "persists the altered status" do
      workspace.reload

      expect(workspace.status_code)
        .to eql("off_track")

      expect(workspace.status_explanation)
        .to eql("Some explanation.")
    end
  end

  context "with faulty name" do
    let(:body) do
      {
        name: nil
      }
    end

    it "responds with 422" do
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "does not change the workspace" do
      attributes_before = workspace.attributes

      expect(workspace.reload.name)
        .to eql(attributes_before["name"])
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
        _links: {
          status: {
            href: api_v3_paths.project_status("bogus")
          }
        }
      }
    end

    it "responds with 422" do
      expect(last_response).to have_http_status(:unprocessable_entity)
    end

    it "does not change the project status" do
      code_before = workspace.status_code

      expect(workspace.reload.status_code)
        .to eql(code_before)
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

  context "when archiving the workspace (change active from true to false)" do
    let(:body) do
      {
        active: false
      }
    end

    context "for an admin" do
      let(:workspace) do
        create(workspace_factory_key).tap do |p|
          p.children << child_workspace
        end
      end
      let(:child_workspace) do
        create(workspace_factory_key)
      end

      current_user { admin }

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "archives the workspace" do
        expect(workspace.reload.active)
          .to be_falsey
      end

      it "archives the child workspace" do
        expect(child_workspace.reload.active)
          .to be_falsey
      end
    end

    context "for a user with only edit_project permission" do
      let(:permissions) { [:edit_project] }

      it "responds with 403" do
        expect(last_response)
          .to have_http_status(403)
      end

      it "does not alter the workspace" do
        expect(workspace.reload.active)
          .to be_truthy
      end
    end

    context "for a user with only archive_project permission" do
      let(:permissions) { [:archive_project] }

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "archives the workspace" do
        expect(workspace.reload.active)
          .to be_falsey
      end
    end

    context "for a user missing archive_workspace permission on child workspace" do
      let(:permissions) { [:archive_project] }
      let(:workspace) do
        create(workspace_factory_key).tap do |p|
          p.children << child_workspace
        end
      end
      let(:child_workspace) { create(:project) }

      it "responds with 422 (and not 403?)" do
        expect(last_response)
          .to have_http_status(422)
      end

      it "does not alter the workspace" do
        expect(workspace.reload.active)
          .to be_truthy
      end
    end
  end

  context "when setting a custom field and archiving the workspace" do
    let(:body) do
      {
        active: false,
        custom_field.attribute_name(:camel_case) => {
          raw: "CF text"
        }
      }
    end

    context "for an admin" do
      let(:workspace) do
        create(workspace_factory_key).tap do |p|
          p.children << child_workspace
        end
      end
      let(:child_workspace) do
        create(workspace_factory_key)
      end

      current_user { admin }

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "sets the cf value" do
        expect(workspace.reload.send(custom_field.attribute_getter))
          .to eql("CF text")
      end

      it "archives the workspace" do
        expect(workspace.reload.active)
          .to be_falsey
      end

      it "archives the child workspace" do
        expect(child_workspace.reload.active)
          .to be_falsey
      end
    end

    context "for a user with only edit_project permission" do
      let(:permissions) { [:edit_project] }

      it "responds with 403" do
        expect(last_response)
          .to have_http_status(403)
      end
    end

    context "for a user with only archive_project permission" do
      let(:permissions) { [:archive_project] }

      it "responds with 403" do
        expect(last_response)
          .to have_http_status(403)
      end
    end

    context "for a user with archive_project and edit_project permissions" do
      let(:permissions) { %i[archive_project edit_project] }

      it "responds with 422 unprocessable_entity" do
        expect(last_response)
          .to have_http_status(422)
      end
    end

    context "for a user with archive_project and edit_project and edit_project_attributes permissions" do
      let(:permissions) { %i[archive_project edit_project edit_project_attributes] }

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end
    end
  end

  context "when unarchiving the workspace (change active from false to true)" do
    let(:workspace_active) { false }
    let(:body) do
      {
        active: true
      }
    end

    context "for an admin" do
      let(:workspace) do
        create(workspace_factory_key).tap do |p|
          p.children << child_workspace
        end
      end
      let(:child_workspace) do
        create(workspace_factory_key)
      end

      current_user { admin }

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "unarchives the workspace" do
        expect(workspace.reload)
          .to be_active
      end

      it "unarchives the child workspace" do
        expect(child_workspace.reload)
          .to be_active
      end
    end

    context "for a non-admin user, even with both archive_project and edit_project permissions" do
      let(:permissions) { %i[archive_project edit_project] }

      it "responds with 404" do
        expect(last_response)
          .to have_http_status(404)
      end

      it "does not alter the workspace" do
        expect(workspace.reload)
          .not_to be_active
      end
    end
  end
end
