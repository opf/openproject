#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe "API v3 Project resource index", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }

  let(:project) do
    create(:project, public: false, active: project_active)
  end
  let(:project_active) { true }
  let(:other_project) do
    create(:project, public: false)
  end
  let(:parent_project) do
    # Adding two roles in here to guard against regression where projects were returned twice if a user
    # had multiple roles in the same project.
    create(:project, public: false, members: { current_user => [role, second_role] }).tap do |parent|
      project.parent = parent
      project.save
    end
  end
  let(:permissions) { [] }
  let(:role) { create(:project_role, permissions:) }
  let(:second_role) { create(:project_role) }
  let(:filters) { [] }
  let(:get_path) do
    api_v3_paths.path_for :projects, filters:
  end
  let(:response) { last_response }
  let(:projects) { [project, other_project] }

  current_user { create(:user, member_with_roles: { project => role }) }

  before do
    projects

    get get_path
  end

  it_behaves_like "API V3 collection response", 1, 1, "Project"

  context "with a pageSize and offset" do
    let(:projects) { [project, project2, project3] }
    let(:project2) do
      create(:project,
             members: { current_user => [role] })
    end
    let(:project3) do
      create(:project,
             members: { current_user => [role] })
    end

    let(:get_path) do
      api_v3_paths.path_for :projects, sort_by: { id: :asc }, page_size: 2, offset: 2
    end

    it_behaves_like "API V3 collection response", 3, 1, "Project" do
      let(:elements) { [project3] }
    end
  end

  context "when filtering for project by ancestor" do
    let(:projects) { [project, other_project, parent_project] }

    let(:filters) do
      [{ ancestor: { operator: "=", values: [parent_project.id.to_s] } }]
    end

    it_behaves_like "API V3 collection response", 1, 1, "Project" do
      let(:elements) { [project] }
    end
  end

  context "with filtering by capability action" do
    let(:other_project) { create(:project) }
    let(:another_project) { create(:project) }
    let(:projects) { [project, other_project, another_project] }
    let(:role) { create(:project_role, permissions: %i[copy_projects view_work_packages]) }
    let(:other_role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:another_role) { create(:project_role, permissions: []) }
    let(:current_user) do
      create(:user, member_with_roles: { project => role,
                                         other_project => other_role,
                                         another_project => another_role })
    end

    let(:filters) do
      [{ user_action: { operator:, values: %w[projects/copy work_packages/read] } }]
    end

    context "if using the equals operator" do
      let(:operator) { "=" }

      it_behaves_like "API V3 collection response", 2, 2, "Project" do
        let(:elements) { [other_project, project] }
      end
    end

    context "if using the all operator" do
      let(:operator) { "&=" }

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end
  end

  context "when filtering by available project attributes" do
    shared_let(:other_project) { create(:project) }
    shared_let(:project) { create(:project) }
    shared_let(:project_custom_field_mapping1) { create(:project_custom_field_project_mapping, project:) }
    shared_let(:project_custom_field_mapping2) { create(:project_custom_field_project_mapping, project:) }

    let(:current_user) do
      create(:user, member_with_roles: { project => role,
                                         other_project => role })
    end

    let(:valid_values) do
      [project_custom_field_mapping1.custom_field_id.to_s, project_custom_field_mapping2.custom_field_id.to_s]
    end

    let(:filters) do
      [{ available_project_attributes: { operator:, values: valid_values } }]
    end

    context "if using the equals operator" do
      let(:operator) { "=" }

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end

    context "if using the not equals operator" do
      let(:operator) { "!" }

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [other_project] }
      end
    end
  end

  context "when filtering for principals (members)" do
    let(:other_project) do
      ProjectRole.non_member
      create(:public_project)
    end
    let(:projects) { [project, other_project] }
    # Just here to make sure that work package members do not interfere
    let!(:share) do
      create(:work_package_member,
             entity: create(:work_package, project: other_project),
             roles: [create(:work_package_role)])
    end

    context "if filtering for a value" do
      let(:filters) do
        [{ principal: { operator: "=", values: [current_user.id.to_s] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end

    context "if filtering for a negative value" do
      let(:filters) do
        [{ principal: { operator: "!", values: [current_user.id.to_s] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [other_project] }
      end
    end

    context "if filtering for all" do
      let(:filters) do
        [{ principal: { operator: "*", values: [] } }]
      end

      # Does not contain the other project as that does not have members
      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end

    context "if filtering for none" do
      let(:filters) do
        [{ principal: { operator: "!*", values: [] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [other_project] }
      end
    end
  end

  context "when filtering for favored" do
    let(:favored_project) { create(:project) }
    let(:unfavored_project) { create(:project) }

    let(:projects) { [favored_project, unfavored_project] }

    current_user do
      create(:user, member_with_roles: { favored_project => role,
                                         unfavored_project => role }) do |user|
        favored_project.set_favored(user)
      end
    end

    context "when filtering for favorite projects" do
      let(:filters) do
        [{ favored: { operator: "=", values: ["t"] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [favored_project] }
      end
    end

    context "when filtering for nonfavorite projects" do
      let(:filters) do
        [{ favored: { operator: "=", values: ["f"] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [unfavored_project] }
      end
    end

    context "when not filtering for favorite projects" do
      let(:filters) do
        [{ favored: { operator: "!", values: ["t"] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [unfavored_project] }
      end
    end

    context "when not filtering for nonfavorite projects" do
      let(:filters) do
        [{ favored: { operator: "!", values: ["f"] } }]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [favored_project] }
      end
    end
  end

  context "with filtering by visibility" do
    let(:public_project) do
      # Otherwise, the public project is invisible
      create(:non_member)

      create(:public_project)
    end
    let(:member_project) do
      create(:project, members: { other_user => role })
    end
    let(:non_member_project) do
      create(:project)
    end
    let(:archived_member_project) do
      create(:project, members: { other_user => role }, active: false)
    end
    let(:projects) { [member_project, public_project, non_member_project, archived_member_project] }
    let(:role) { create(:project_role, permissions: []) }
    let(:other_user) do
      create(:user)
    end
    let(:filters) do
      [{ visible: { operator: "=", values: [other_user.id.to_s] } }]
    end

    current_user { admin }

    it_behaves_like "API V3 collection response", 2, 2, "Project" do
      let(:elements) { [public_project, member_project] }
    end
  end

  context "with the project being archived/inactive" do
    let(:project_active) { false }
    let(:projects) { [project] }

    context "with the user being admin" do
      current_user { admin }

      it "responds with 200 OK" do
        expect(last_response).to have_http_status(:ok)
      end

      it_behaves_like "API V3 collection response", 1, 1, "Project" do
        let(:elements) { [project] }
      end
    end

    context "with the user being no admin" do
      it_behaves_like "API V3 collection response", 0, 0, "Project"

      it "responds with 200" do
        expect(last_response).to have_http_status(:ok)
      end
    end
  end

  context "when signaling the properties to include" do
    let(:projects) { [project, parent_project] }
    let(:select) { "elements/id,elements/name,elements/ancestors,total" }
    let(:get_path) do
      api_v3_paths.path_for :projects, select:
    end
    let(:expected) do
      {
        total: 2,
        _embedded: {
          elements: [
            {
              id: parent_project.id,
              name: parent_project.name,
              _links: {
                ancestors: []
              }
            },
            {
              id: project.id,
              name: project.name,
              _links: {
                ancestors: [
                  href: api_v3_paths.project(parent_project.id),
                  title: parent_project.name
                ]
              }
            }
          ]
        }
      }
    end

    it "is the reduced set of properties of the embedded elements" do
      expect(last_response.body)
        .to be_json_eql(expected.to_json)
    end
  end

  context "as project collection" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:projects) { [project] }
    let(:expected) do
      "#{api_v3_paths.project(project.id)}/work_packages"
    end

    it "has projects with links to their work packages" do
      expect(last_response.body)
        .to be_json_eql(expected.to_json).at_path("_embedded/elements/0/_links/workPackages/href")
    end
  end

  describe "permissions" do
    context "when a project without view project permission is present" do
      shared_let(:other_project) { create(:project) }
      shared_let(:project) { create(:project) }
      shared_let(:project_custom_field) do
        create(:project_custom_field_project_mapping, project:).project_custom_field
      end
      shared_let(:other_project_custom_field) do
        create(:project_custom_field_project_mapping, project: other_project).project_custom_field
      end

      let(:permissions) { [] }
      let(:other_permissions) { %i(view_project_attributes) }
      let(:other_role) { create(:project_role, permissions: other_permissions) }
      let(:current_user) do
        create(:user, member_with_roles: { project => role,
                                           other_project => other_role })
      end

      it_behaves_like "API V3 collection response", 2, 2, "Project" do
        let(:elements) { [project, other_project] }

        it "does not return the project attributes for the project" do
          expect(subject).not_to have_json_path(
            "_embedded/elements/0/#{project_custom_field.attribute_name(:camel_case)}"
          )
        end

        it "returns project attributes for other project with the view project permissions" do
          expect(subject).to have_json_path(
            "_embedded/elements/1/#{other_project_custom_field.attribute_name(:camel_case)}"
          )
        end
      end
    end
  end
end
