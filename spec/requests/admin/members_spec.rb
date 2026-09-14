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

RSpec.describe "GET /admin/members", :aggregate_failures, :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  shared_let(:project) { create(:project, name: "Apollo") }
  shared_let(:archived_project) { create(:project, name: "Gemini", active: false) }
  shared_let(:role) { create(:project_role, name: "Reviewer") }
  shared_let(:other_role) { create(:project_role, name: "Approver") }

  shared_let(:user) do
    create(:user, firstname: "Jo", lastname: "Barnes", member_with_roles: { project => [role, other_role] })
  end
  shared_let(:archived_member) do
    create(:user, firstname: "Ada", lastname: "Stone", member_with_roles: { archived_project => [role] })
  end
  shared_let(:global_user) do
    create(:user, firstname: "Kim", lastname: "Novak", global_roles: [create(:global_role, name: "Creator")])
  end

  context "with an admin" do
    before { login_as(admin) }

    it "lists every membership with its user, project and roles" do
      get admin_members_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jo Barnes")
      expect(response.body).to include("Apollo")
      expect(response.body).to include("Approver")
      expect(response.body).to include("Reviewer")
    end

    it "includes memberships of archived projects" do
      get admin_members_path

      expect(response.body).to include("Ada Stone")
      expect(response.body).to include("Gemini")
    end

    it "marks global memberships as such" do
      get admin_members_path

      expect(response.body).to include("Kim Novak")
      expect(response.body).to include("Creator")
    end

    it "filters by role" do
      get admin_members_path(filters: [{ role_id: { operator: "=", values: [other_role.id.to_s] } }].to_json)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jo Barnes")
      expect(response.body).not_to include("Ada Stone")
      expect(response.body).not_to include("Kim Novak")
    end

    it "offers quick filters for member type, project and role without an all filters section" do
      get admin_members_path

      expect(response.body).to include(Member.human_attribute_name(:principal_type))
      expect(response.body).to include(Project.model_name.human)
      expect(response.body).to include(Role.model_name.human)
      expect(response.body).not_to include(I18n.t(:button_all_filters))
    end

    it "keeps every column, the roles included, visible on mobile" do
      get admin_members_path

      cells = response.parsed_body.css(".op-border-box-grid__row-item")

      expect(cells).not_to be_empty
      expect(cells.css(".op-border-box-grid__row-item--no-mobile")).to be_empty
      expect(Admin::Members::TableComponent.mobile_columns)
        .to match_array(Admin::Members::TableComponent.columns)
    end

    it "names the member types after their models" do
      get admin_members_path

      [User, Group, PlaceholderUser].each do |principal_class|
        expect(response.body).to include(principal_class.model_name.human(count: 2))
      end
    end

    it "labels the search input for users" do
      get admin_members_path

      expect(response.body).to include("Search users")
    end

    it "links the project and the roles of a row" do
      get admin_members_path

      expect(response.body).to include(project_path(project))
      expect(response.body).to include(edit_role_path(role))
      expect(response.body).to include(edit_role_path(other_role))
    end

    it "does not link archived projects" do
      get admin_members_path

      expect(response.body).to include("Gemini")
      expect(response.body).not_to include(project_path(archived_project))
    end

    it "does not mark directly assigned memberships as inherited" do
      get admin_members_path

      expect(response.body).not_to include("op-admin-members--inherited")
    end

    context "with a membership inherited from a group" do
      shared_let(:group_project) { create(:project, name: "Mercury") }
      shared_let(:group_role) { create(:project_role, name: "Contributor") }
      shared_let(:own_role) { create(:project_role, name: "Auditor") }
      shared_let(:group_user) { create(:user, firstname: "Lee", lastname: "Park") }
      shared_let(:group) do
        create(:group, members: [group_user], member_with_roles: { group_project => [group_role] }) do |group|
          Groups::CreateInheritedRolesService
            .new(group, current_user: User.system, contract_class: EmptyContract)
            .call(user_ids: [group_user.id])
        end
      end

      it "names the group the roles come from" do
        get admin_members_path

        expect(response.body).to include("(via: #{Group.model_name.human} #{group.name})")
      end

      it "leaves the group's own membership unmarked" do
        get admin_members_path

        inherited_notes = response.parsed_body
                            .css("[data-test-selector='op-admin-members--inherited']")

        expect(inherited_notes.size).to eq(1)
      end

      context "and a role of the user's own alongside it" do
        before do
          Member.find_by(principal: group_user, project: group_project).roles << own_role
        end

        it "still names the group for the inherited part" do
          get admin_members_path

          expect(response.body).to include("(via: #{Group.model_name.human} #{group.name})")
          expect(response.body).to include("Auditor")
        end
      end
    end

    it "filters by project" do
      get admin_members_path(filters: [{ project_id: { operator: "=", values: [archived_project.id.to_s] } }].to_json)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Stone")
      expect(response.body).not_to include("Jo Barnes")
    end

    it "filters by principal type" do
      get admin_members_path(filters: [{ principal_type: { operator: "=", values: [Group.name] } }].to_json)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Jo Barnes")
      expect(response.body).not_to include("Ada Stone")
    end

    it "filters by principal name" do
      get admin_members_path(filters: [{ any_name_attribute: { operator: "~", values: ["Stone"] } }].to_json)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ada Stone")
      expect(response.body).not_to include("Jo Barnes")
    end
  end

  context "with a non-admin user" do
    before { login_as(create(:user)) }

    it "is forbidden" do
      get admin_members_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with a user holding a global role" do
    before do
      global_role = create(:global_role, permissions: %i[add_project])
      login_as(create(:user, global_roles: [global_role]))
    end

    it "is forbidden" do
      get admin_members_path

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when anonymous" do
    it "redirects to the login form" do
      get admin_members_path

      expect(response).to have_http_status(:found)
    end
  end
end
