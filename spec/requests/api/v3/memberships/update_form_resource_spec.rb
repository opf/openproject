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

RSpec.describe API::V3::Memberships::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:member) { create(:member, project:, roles: [role, another_role]) }
  let(:project) { create(:project) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:other_role) { create(:project_role) }
  let(:another_role) { create(:project_role) }
  let(:other_user) { create(:user) }
  let(:permissions) { [:manage_members] }
  let(:path) { api_v3_paths.membership_form(member.id) }
  let(:parameters) do
    {
      _links: {
        roles: [
          {
            href: api_v3_paths.role(role.id)
          },
          {
            href: api_v3_paths.role(other_role.id)
          }
        ]
      },
      _meta: {
        notificationMessage: {
          raw: "Join the **dark** side."
        }
      }
    }
  end

  current_user { user }

  before do
    post path, parameters.to_json
  end

  subject(:response) { last_response }

  describe "#POST /api/v3/memberships/:id/form" do
    it "returns 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "returns a form" do
      expect(response.body)
        .to be_json_eql("Form".to_json)
        .at_path("_type")
    end

    it "does not update the member (no new roles)" do
      expect(member.roles.reload)
        .to contain_exactly(role, another_role)
    end

    it "contains the update roles in the payload" do
      expect(response.body)
        .to have_json_size(2)
        .at_path("_embedded/payload/_links/roles")

      expect(response.body)
        .to be_json_eql(api_v3_paths.role(role.id).to_json)
        .at_path("_embedded/payload/_links/roles/0/href")

      expect(response.body)
        .to be_json_eql(api_v3_paths.role(other_role.id).to_json)
        .at_path("_embedded/payload/_links/roles/1/href")
    end

    it "contains the notification message" do
      expect(response.body)
        .to be_json_eql("Join the **dark** side.".to_json)
              .at_path("_embedded/payload/_meta/notificationMessage/raw")
    end

    it "does not contain the project in the payload" do
      expect(response.body)
        .not_to have_json_path("_embedded/payload/_links/project")
    end

    it "does not contain the principal in the payload" do
      expect(response.body)
        .not_to have_json_path("_embedded/payload/_links/principal")
    end

    context "with wanting to remove all roles" do
      let(:parameters) do
        {
          _links: {
            roles: []
          }
        }
      end

      it "has 1 validation errors" do
        expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
      end

      it "notes roles cannot be empty" do
        expect(subject.body)
          .to be_json_eql("Roles need to be assigned.".to_json)
          .at_path("_embedded/validationErrors/roles/message")
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
            project: {
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

      it "notes project to not be writable" do
        expect(subject.body)
          .to be_json_eql(false)
          .at_path("_embedded/schema/project/writable")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    context "with wanting to alter the principal" do
      let(:other_principal) do
        create(:user)
      end
      let(:parameters) do
        {
          _links: {
            principal: {
              href: api_v3_paths.user(other_principal.id)
            }
          }
        }
      end

      it "has 1 validation errors" do
        expect(subject.body).to have_json_size(1).at_path("_embedded/validationErrors")
      end

      it "has a validation error on principal" do
        expect(subject.body).to have_json_path("_embedded/validationErrors/user")
      end

      it "notes principal to not be writable" do
        expect(subject.body)
          .to be_json_eql(false)
          .at_path("_embedded/schema/principal/writable")
      end

      it "has no commit link" do
        expect(subject.body)
          .not_to have_json_path("_links/commit")
      end
    end

    context "without the necessary edit permission" do
      let(:permissions) { [:view_members] }

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
