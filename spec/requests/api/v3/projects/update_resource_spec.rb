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

RSpec.describe "API v3 Project resource update", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:admin) { create(:admin) }
  let(:project) do
    create(:project,
           :with_status,
           public: false,
           active: project_active)
  end
  let(:project_active) { true }
  let(:custom_field) do
    create(:text_project_custom_field)
  end
  let(:invisible_custom_field) do
    create(:text_project_custom_field, admin_only: true)
  end
  let(:permissions) { %i[edit_project view_project_attributes edit_project_attributes] }
  let(:path) { api_v3_paths.project(project.id) }
  let(:body) do
    {
      identifier: "new_project_identifier",
      name: "Project name"
    }
  end

  current_user do
    create(:user, member_with_permissions: { project => permissions })
  end

  before do
    patch path, body.to_json
  end

  it "responds with 200 OK" do
    expect(last_response).to have_http_status(:ok)
  end

  it "alters the project" do
    project.reload

    expect(project.name)
      .to eql(body[:name])

    expect(project.identifier)
      .to eql(body[:identifier])
  end

  it "returns the updated project" do
    expect(last_response.body)
      .to be_json_eql("Project".to_json)
            .at_path("_type")
    expect(last_response.body)
      .to be_json_eql(body[:name].to_json)
            .at_path("name")
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
      expect(project.reload.send(custom_field.attribute_getter))
        .to eql("CF text")
    end

    it "automatically activates the cf for project if the value was provided" do
      expect(project.project_custom_fields)
        .to contain_exactly(custom_field)
    end
  end

  context "with an invisible custom field" do
    let(:body) do
      {
        invisible_custom_field.attribute_name(:camel_case) => {
          raw: "CF text"
        }
      }
    end

    context "with admin permissions" do
      let(:current_user) { create(:admin) }

      it "responds with 200 OK" do
        expect(last_response).to have_http_status(:ok)
      end

      it "sets the cf value" do
        expect(project.reload.send(invisible_custom_field.attribute_getter))
          .to eql("CF text")
      end

      it "automatically activates the cf for project if the value was provided" do
        expect(project.reload.project_custom_fields)
          .to contain_exactly(invisible_custom_field)
      end
    end

    context "with non-admin permissions" do
      it "responds with 200 OK" do
        # TBD: trying to set a not accessible custom field is silently ignored
        expect(last_response).to have_http_status(:ok)
      end

      it "does not set the cf value" do
        expect(project.reload.custom_values)
          .to be_empty
      end

      context "when the hidden field has a value already" do
        it "does not change the cf value" do
          project.custom_field_values = { invisible_custom_field.id => "1234" }
          project.save
          patch path, body.to_json

          expect(project.reload.custom_values.find_by(custom_field: invisible_custom_field).value)
            .to eq "1234"
        end
      end

      it "does not activate the cf for project" do
        expect(project.reload.project_custom_fields)
          .to be_empty
      end
    end
  end

  describe "permissions" do
    context "without permission to patch projects" do
      let(:permissions) { [] }

      it "responds with 403" do
        expect(last_response).to have_http_status(:forbidden)
      end

      it "does not change the project" do
        attributes_before = project.attributes

        expect(project.reload.name)
          .to eql(attributes_before["name"])
      end

      context "and with edit_project_attributes permission" do
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

        it "does not change the project" do
          attributes_before = project.attributes
          custom_field_value_before = project.send(custom_field.attribute_getter)

          expect(project.reload.name)
            .to eql(attributes_before["name"])
          expect(project.send(custom_field.attribute_getter))
            .to eq custom_field_value_before
        end
      end
    end

    context "with edit_project permission" do
      let(:permissions) { [:edit_project] }

      it "responds with 200 OK" do
        expect(last_response).to have_http_status(:ok)
      end

      it "alters the project" do
        project.reload

        expect(project.name)
          .to eql(body[:name])

        expect(project.identifier)
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

        it "does not change the project" do
          attributes_before = project.attributes
          custom_field_value_before = project.send(custom_field.attribute_getter)

          expect(project.reload.name)
            .to eql(attributes_before["name"])
          expect(project.send(custom_field.attribute_getter))
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

      project.reload
      expect(project.status_code).to be_nil
      expect(project.status_explanation).to eq "Some explanation."

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
      project.reload

      expect(project.status_code)
        .to eql("off_track")

      expect(project.status_explanation)
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

    it "does not change the project" do
      attributes_before = project.attributes

      expect(project.reload.name)
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
      code_before = project.status_code

      expect(project.reload.status_code)
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

  context "when archiving the project (change active from true to false)" do
    let(:body) do
      {
        active: false
      }
    end

    context "for an admin" do
      let(:current_user) do
        create(:admin)
      end
      let(:project) do
        create(:project).tap do |p|
          p.children << child_project
        end
      end
      let(:child_project) do
        create(:project)
      end

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "archives the project" do
        expect(project.reload.active)
          .to be_falsey
      end

      it "archives the child project" do
        expect(child_project.reload.active)
          .to be_falsey
      end
    end

    context "for a user with only edit_project permission" do
      let(:permissions) { [:edit_project] }

      it "responds with 403" do
        expect(last_response)
          .to have_http_status(403)
      end

      it "does not alter the project" do
        expect(project.reload.active)
          .to be_truthy
      end
    end

    context "for a user with only archive_project permission" do
      let(:permissions) { [:archive_project] }

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "archives the project" do
        expect(project.reload.active)
          .to be_falsey
      end
    end

    context "for a user missing archive_project permission on child project" do
      let(:permissions) { [:archive_project] }
      let(:project) do
        create(:project).tap do |p|
          p.children << child_project
        end
      end
      let(:child_project) { create(:project) }

      it "responds with 422 (and not 403?)" do
        expect(last_response)
          .to have_http_status(422)
      end

      it "does not alter the project" do
        expect(project.reload.active)
          .to be_truthy
      end
    end
  end

  context "when setting a custom field and archiving the project" do
    let(:body) do
      {
        active: false,
        custom_field.attribute_name(:camel_case) => {
          raw: "CF text"
        }
      }
    end

    context "for an admin" do
      let(:current_user) do
        create(:admin)
      end
      let(:project) do
        create(:project).tap do |p|
          p.children << child_project
        end
      end
      let(:child_project) do
        create(:project)
      end

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "sets the cf value" do
        expect(project.reload.send(custom_field.attribute_getter))
          .to eql("CF text")
      end

      it "archives the project" do
        expect(project.reload.active)
          .to be_falsey
      end

      it "archives the child project" do
        expect(child_project.reload.active)
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

  context "when unarchiving the project (change active from false to true)" do
    let(:project_active) { false }
    let(:body) do
      {
        active: true
      }
    end

    context "for an admin" do
      let(:current_user) do
        create(:admin)
      end
      let(:project) do
        create(:project).tap do |p|
          p.children << child_project
        end
      end
      let(:child_project) do
        create(:project)
      end

      it "responds with 200 OK" do
        expect(last_response)
          .to have_http_status(200)
      end

      it "unarchives the project" do
        expect(project.reload)
          .to be_active
      end

      it "unarchives the child project" do
        expect(child_project.reload)
          .to be_active
      end
    end

    context "for a non-admin user, even with both archive_project and edit_project permissions" do
      let(:permissions) { %i[archive_project edit_project] }

      it "responds with 404" do
        expect(last_response)
          .to have_http_status(404)
      end

      it "does not alter the project" do
        expect(project.reload)
          .not_to be_active
      end
    end
  end
end
