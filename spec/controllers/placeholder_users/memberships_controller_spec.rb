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
require "work_package"

RSpec.describe PlaceholderUsers::MembershipsController do
  shared_let(:placeholder_user) { create(:placeholder_user) }
  shared_let(:anonymous) { create(:anonymous) }
  shared_let(:project) { create(:project) }
  shared_let(:role) { create(:project_role) }

  shared_examples "update memberships flow" do
    it "works" do
      # i.e. it should successfully add a placeholder user to a project's members
      post :create,
           params: {
             placeholder_user_id: placeholder_user.id,
             membership: {
               project_id: project.id,
               role_ids: [role.id]
             }
           }

      expect(response).to redirect_to(controller: "/placeholder_users",
                                      action: "edit",
                                      id: placeholder_user.id,
                                      tab: "memberships")

      is_member = placeholder_user.reload.memberships.any? do |m|
        m.project_id == project.id && m.role_ids.include?(role.id)
      end
      expect(is_member).to be(true)
    end
  end

  shared_examples "update memberships forbidden flow" do
    describe "POST create" do
      it "returns an error" do
        post :create, params: {
          placeholder_user_id: placeholder_user.id,
          membership: {
            project_id: project.id,
            role_ids: [role.id]
          }
        }

        expect(response).to have_http_status :forbidden
      end
    end

    describe "PUT update" do
      it "returns an error" do
        put :update, params: {
          placeholder_user_id: placeholder_user.id,
          id: 1234
        }

        expect(response).to have_http_status :not_found
      end
    end

    describe "DELETE destroy" do
      it "returns an error" do
        delete :destroy, params: {
          placeholder_user_id: placeholder_user.id,
          id: 1234
        }

        expect(response).to have_http_status :not_found
      end
    end
  end

  context "as admin" do
    current_user { create(:admin) }

    it_behaves_like "update memberships flow"
  end

  context "as user with global permission and manage_members" do
    current_user do
      create(:user,
             member_with_permissions: { project => %i[manage_members] },
             global_permissions: %i[manage_placeholder_user])
    end

    it_behaves_like "update memberships flow"
  end

  context "as user with global permission but not project permission" do
    current_user { create(:user, global_permissions: %i[manage_placeholder_user]) }

    describe "POST create" do
      it "redirects but fails to create" do
        post :create, params: {
          placeholder_user_id: placeholder_user.id,
          membership: {
            project_id: project.id,
            role_ids: [role.id]
          }
        }

        expect(response).to have_http_status :found
        expect(placeholder_user.reload.memberships).to be_empty
      end
    end

    context "with a membership in another project that is invisible" do
      shared_let(:project2) { create(:project) }
      shared_let(:membership) { create(:member, principal: placeholder_user, project: project2, roles: [role]) }

      describe "PUT update" do
        it "returns an error" do
          put :update, params: {
            placeholder_user_id: placeholder_user.id,
            id: membership.id
          }

          expect(response).to have_http_status :not_found
        end
      end

      describe "DELETE destroy" do
        it "returns an error" do
          delete :destroy, params: {
            placeholder_user_id: placeholder_user.id,
            id: membership.id
          }

          expect(response).to have_http_status :not_found
        end
      end
    end
  end

  context "as user without global permission" do
    current_user { create(:user) }

    it_behaves_like "update memberships forbidden flow"
  end
end
