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

RSpec.describe API::V3::Projects::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  subject(:response) { last_response }

  current_user do
    create(:user).tap do |u|
      create(:global_member,
             principal: u,
             roles: [global_role])
    end
  end

  let(:global_role) do
    create(:global_role, permissions:)
  end
  let(:text_custom_field) do
    create(:text_project_custom_field)
  end
  let(:list_custom_field) do
    create(:list_project_custom_field)
  end
  let(:permissions) { [:add_project] }
  let(:path) { api_v3_paths.create_project_form }
  let(:params) do
    {}
  end

  before do
    post path, params.to_json
  end

  describe "#POST /api/v3/projects/form" do
    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a form" do
      expect(response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    it "does not create a project" do
      expect(Project.count)
        .to be 0
    end

    context "with empty parameters" do
      it "has one validation error for name", :aggregate_failures do
        expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
        expect(subject.body).to have_json_path("_embedded/validationErrors/name")
        expect(subject.body).not_to have_json_path("_links/commit")
      end
    end

    context "with all parameters" do
      let(:params) do
        {
          identifier: "new_project_identifier",
          name: "Project name",
          text_custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          },
          statusExplanation: { raw: "A magic dwells in each beginning." },
          _links: {
            list_custom_field.attribute_name(:camel_case) => {
              href: api_v3_paths.custom_option(list_custom_field.custom_options.first.id)
            },
            status: {
              href: api_v3_paths.project_status("on_track")
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
          .to be_json_eql("CF text".to_json)
          .at_path("_embedded/payload/customField#{text_custom_field.id}/raw")

        expect(body)
          .to be_json_eql(api_v3_paths.custom_option(list_custom_field.custom_options.first.id).to_json)
          .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/href")

        expect(body)
          .to be_json_eql(api_v3_paths.project_status("on_track").to_json)
          .at_path("_embedded/payload/_links/status/href")

        expect(body)
          .to be_json_eql(
            {
              format: "markdown",
              html: "<p class=\"op-uc-p\">A magic dwells in each beginning.</p>",
              raw: "A magic dwells in each beginning."
            }.to_json
          ).at_path("_embedded/payload/statusExplanation")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.projects.to_json)
          .at_path("_links/commit/href")
      end
    end

    context "with faulty status parameters" do
      let(:params) do
        {
          identifier: "new_project_identifier",
          name: "Project name",
          _links: {
            status: {
              href: api_v3_paths.project_status("bogus")
            }
          }
        }
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

    context "with only add_subprojects permission" do
      current_user do
        create(:user,
               member_with_permissions: { parent_project => %i[add_subprojects] })
      end

      let(:parent_project) { create(:project) }

      let(:params) do
        {
          _links: {
            parent: {
              href: api_v3_paths.project(parent_project.id)
            }
          }
        }
      end

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the schema with a required parent field" do
        expect(response.body)
          .to be_json_eql(true)
                .at_path("_embedded/schema/parent/required")
      end
    end

    context "without the necessary permission" do
      let(:permissions) { [] }

      it "returns 403 Not Authorized" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
