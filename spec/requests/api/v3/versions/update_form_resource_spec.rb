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

RSpec.describe API::V3::Versions::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:version) { create(:version, project:) }
  let(:project) { create(:project) }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) { [:manage_versions] }

  let(:path) { api_v3_paths.version_form(version.id) }
  let(:parameters) do
    {
      name: "A new version name"
    }
  end

  before do
    login_as(user)
    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe "#POST /api/v3/versions/:id/form" do
    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a form" do
      expect(response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    it "does not update the version" do
      expect(version.reload.name)
        .not_to eql "A new version name"
    end

    context "with nulling parameters" do
      let(:parameters) do
        {
          name: nil,
          _links: {
            definingProject: {
              href: nil
            }
          }
        }
      end

      it "has 2 validation errors" do
        expect(subject.body).to have_json_size(2).at_path("_embedded/validationErrors")
      end

      it "has a validation error on name" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/name")
      end

      it "has a validation error on project" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/project")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    context "with wanting to alter the project" do
      let(:other_project) do
        role = create(:project_role, permissions:)

        create(:project,
               members: { user => role })
      end
      let(:parameters) do
        {
          _links: {
            definingProject: {
              href: api_v3_paths.project(other_project.id)
            }
          }
        }
      end

      it "has 1 validation errors" do
        expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
      end

      it "has a validation error on project" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/project")
      end

      it "notes definingProject to not be writable" do
        expect(subject.body)
          .to be_json_eql(false)
          .at_path("_embedded/schema/definingProject/writable")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    context "with all parameters" do
      let!(:int_cf) { create(:version_custom_field, :integer) }
      let!(:list_cf) { create(:version_custom_field, :list) }
      let(:parameters) do
        {
          name: "New version",
          description: {
            raw: "A new description"
          },
          int_cf.attribute_name(:camel_case) => 5,
          startDate: "2018-01-01",
          endDate: "2018-01-09",
          status: "closed",
          sharing: "descendants",
          _links: {
            list_cf.attribute_name(:camel_case) => {
              href: api_v3_paths.custom_option(list_cf.custom_options.first.id)
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
          .to be_json_eql("New version".to_json)
          .at_path("_embedded/payload/name")

        expect(last_response.body)
          .to be_json_eql("<p>A new description</p>".to_json)
          .at_path("_embedded/payload/description/html")

        expect(last_response.body)
          .to be_json_eql("2018-01-01".to_json)
          .at_path("_embedded/payload/startDate")

        expect(last_response.body)
          .to be_json_eql("2018-01-09".to_json)
          .at_path("_embedded/payload/endDate")

        expect(last_response.body)
          .to be_json_eql("closed".to_json)
          .at_path("_embedded/payload/status")

        expect(last_response.body)
          .to be_json_eql("descendants".to_json)
          .at_path("_embedded/payload/sharing")

        expect(last_response.body)
          .to be_json_eql(api_v3_paths.custom_option(list_cf.custom_options.first.id).to_json)
          .at_path("_embedded/payload/_links/customField#{list_cf.id}/href")

        expect(last_response.body)
          .to be_json_eql(5.to_json)
          .at_path("_embedded/payload/customField#{int_cf.id}")
      end

      it "has no definingProject path" do
        # As the definingProject is not writable
        expect(body)
          .not_to have_json_path("_embedded/payload/_links/definingProject")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.version(version.id).to_json)
          .at_path("_links/commit/href")
      end
    end

    context "without the necessary edit permission" do
      let(:permissions) { [:view_work_packages] }

      it "returns 403 Not Authorized" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without the necessary view permission" do
      let(:permissions) { [] }

      it "returns 404 Not Found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
