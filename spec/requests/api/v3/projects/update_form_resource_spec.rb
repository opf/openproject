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

RSpec.describe API::V3::Projects::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) do
    create(:project,
           text_custom_field.attribute_name => "CF text",
           list_custom_field.attribute_name => list_custom_field.custom_options.first)
  end
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:text_custom_field) do
    create(:text_project_custom_field)
  end
  let(:list_custom_field) do
    create(:list_project_custom_field)
  end
  let(:viable_parent_project) do
    create(:project).tap do |p|
      create(:member,
             project: p,
             principal: current_user,
             roles: [parent_project_role])
    end
  end
  let(:parent_project_role) do
    create(:project_role, permissions: parent_project_permissions)
  end
  let(:permissions) { %i[edit_project view_project_attributes edit_project_attributes] }
  let(:parent_project_permissions) { [:add_subprojects] }
  let(:path) { api_v3_paths.project_form(project.id) }
  let(:params) do
    {}
  end

  before do
    login_as(current_user)

    post path, params.to_json
  end

  subject(:response) { last_response }

  describe "#POST /api/v3/projects/:id/form" do
    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a form" do
      expect(response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    context "with empty parameters" do
      it "has no validation errors" do
        expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
      end

      it "returns the current project value`s in the payload" do
        expect(subject.body)
          .to be_json_eql(project.name.to_json)
          .at_path("_embedded/payload/name")
      end

      it "has a commit link" do
        expect(subject.body)
          .to have_json_path("_links/commit")
      end
    end

    context "with faulty parameters" do
      let(:params) do
        {
          name: nil
        }
      end

      it "has one validation errors" do
        expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
      end

      it "has a validation error on name" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/name")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end

      it "does not alter the project" do
        name_before = project.name

        expect(project.reload.name)
          .to eql name_before
      end
    end

    context "with a viable parent project" do
      context "with a correct parameter" do
        let(:params) do
          {
            _links: {
              parent: {
                href: api_v3_paths.project(viable_parent_project.id)
              }
            }
          }
        end

        it "sets the project in the payload" do
          expect(subject.body)
            .to be_json_eql(api_v3_paths.project(viable_parent_project.id).to_json)
            .at_path("_embedded/payload/_links/parent/href")
        end

        it "links to the allowed parents in the schema" do
          expect(subject.body)
            .to be_json_eql((api_v3_paths.projects_available_parents + "?of=#{project.id}").to_json)
            .at_path("_embedded/schema/parent/_links/allowedValues/href")
        end
      end
    end

    context "with valid parameters" do
      let(:params) do
        {
          identifier: "new_project_identifier",
          name: "Project name",
          text_custom_field.attribute_name(:camel_case) => {
            raw: "new CF text"
          },
          statusExplanation: { raw: "Something goes awry." },
          _links: {
            list_custom_field.attribute_name(:camel_case) => {
              href: api_v3_paths.custom_option(list_custom_field.custom_options.last.id)
            },
            status: {
              href: api_v3_paths.project_status("off_track")
            }
          }
        }
      end

      it "has 0 validation errors" do
        expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
      end

      it "has the values prefilled in the payload" do
        body = subject.body

        expect(body)
          .to be_json_eql("new_project_identifier".to_json)
          .at_path("_embedded/payload/identifier")

        expect(body)
          .to be_json_eql("Project name".to_json)
          .at_path("_embedded/payload/name")

        expect(body)
          .to be_json_eql("new CF text".to_json)
          .at_path("_embedded/payload/customField#{text_custom_field.id}/raw")

        expect(body)
          .to be_json_eql(api_v3_paths.custom_option(list_custom_field.custom_options.last.id).to_json)
          .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/href")

        expect(body)
          .to be_json_eql(api_v3_paths.project_status("off_track").to_json)
          .at_path("_embedded/payload/_links/status/href")

        expect(body)
          .to be_json_eql("Something goes awry.".to_json)
          .at_path("_embedded/payload/statusExplanation/raw")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.project(project.id).to_json)
          .at_path("_links/commit/href")
      end

      it "does not alter the project" do
        attributes_before = project.attributes

        expect(project.reload.name)
          .to eql attributes_before["name"]

        expect(project.identifier)
          .to eql attributes_before["identifier"]

        expect(project.send(text_custom_field.attribute_getter))
          .to eql "CF text"

        expect(project.send(list_custom_field.attribute_getter))
          .to eql list_custom_field.custom_options.first.value
      end
    end

    context "with faulty status parameters" do
      let(:params) do
        {
          status: {
            href: api_v3_paths.project_status("bogus")
          }
        }
      end

      it "displays the faulty status in the payload" do
        expect(subject.body)
          .to be_json_eql({ href: api_v3_paths.project_status("bogus") }.to_json)
          .at_path("_embedded/payload/_links/status")
      end

      it "has 1 validation errors" do
        expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
      end

      it "has a validation error on status" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/status")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    describe "permissions" do
      context "without the necessary Edit permission" do
        let(:permissions) { [] }

        it "returns 403 Not Authorized" do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "without View project attributes permission" do
        let(:permissions) { %i(edit_project) }

        context "when custom fields are not provided" do
          let(:params) { { name: "Project name" } }

          it "has 0 validation errors" do
            expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
          end

          it "does not set the custom field in the payload" do
            expect(subject.body)
              .not_to have_json_path("_embedded/payload/customField#{text_custom_field.id}/raw")
          end
        end

        context "when custom fields are provided" do
          let(:params) do
            {
              name: "Project name",
              text_custom_field.attribute_name(:camel_case) => {
                raw: "new CF text"
              }
            }
          end

          it "has one validation errors" do
            expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
          end

          it "has a validation error on the custom field" do
            expect(subject.body).to have_json_path(
              "_embedded/validationErrors/#{text_custom_field.attribute_name(:camel_case)}"
            )
          end

          it "does not prefill the custom field in the payload" do
            expect(subject.body)
              .not_to have_json_path("_embedded/payload/customField#{text_custom_field.id}/raw")
          end
        end
      end

      context "with View project attributes permission and
               without Edit project attributes permission" do
        let(:permissions) { %i(edit_project view_project_attributes) }

        context "when custom fields are not provided" do
          let(:params) { { name: "Project name" } }

          it "has 0 validation errors" do
            expect(subject.body).to have_json_size(0).at_path("_embedded/validationErrors")
          end

          it "does not prefill the custom field in the payload" do
            expect(subject.body)
              .not_to have_json_path("_embedded/payload/customField#{text_custom_field.id}/raw")
          end
        end

        context "when custom fields are provided" do
          let(:params) do
            {
              name: "Project name",
              text_custom_field.attribute_name(:camel_case) => {
                raw: "new CF text"
              }
            }
          end

          it "has one validation errors" do
            expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
          end

          it "does not prefill the custom field in the payload" do
            expect(subject.body)
              .not_to have_json_path("_embedded/payload/customField#{text_custom_field.id}/raw")
          end

          it "has a validation error on name" do
            expect(subject.body).to have_json_path(
              "_embedded/validationErrors/#{text_custom_field.attribute_name(:camel_case)}"
            )
          end

          it "has no commit link" do
            expect(subject.body)
              .not_to have_json_path("_links/commit")
          end

          it "does not alter the project" do
            cf_value_before = project.send(text_custom_field.attribute_getter)

            expect(project.send(text_custom_field.attribute_getter))
              .to eql cf_value_before
          end
        end
      end
    end

    context "with a non existing id" do
      let(:path) { api_v3_paths.project_form(1) }

      it "returns 404 Not found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
