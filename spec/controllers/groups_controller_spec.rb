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

RSpec.describe GroupsController do
  let(:group) { create(:group, members: group_members) }
  let(:group_members) { [] }

  before do
    login_as current_user
  end

  context "as admin" do
    shared_let(:admin) { create(:admin) }
    let(:current_user) { admin }

    it "indexes" do
      get :index
      expect(response).to be_successful
      expect(response).to render_template "index"
    end

    it "shows" do
      get :show, params: { id: group.id }
      expect(response).to be_successful
      expect(response).to render_template "show"
    end

    it "shows new" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template "new"
    end

    it "creates" do
      expect do
        post :create, params: { group: { lastname: "New group" } }
      end.to change(Group, :count).by(1)
      expect(response).to redirect_to groups_path
    end

    it "edits" do
      get :edit, params: { id: group.id }

      expect(response).to be_successful
      expect(response).to render_template "edit"
    end

    it "updates" do
      expect do
        put :update, params: { id: group.id, group: { lastname: "new name" } }
      end.to change { group.reload.name }.to("new name")

      expect(response).to redirect_to groups_path
    end

    it "destroys" do
      perform_enqueued_jobs do
        delete :destroy, params: { id: group.id }
      end

      expect { group.reload }.to raise_error ActiveRecord::RecordNotFound

      expect(response).to redirect_to groups_path
    end

    context "with two existing users" do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }

      it "adds users" do
        post :add_users, params: { id: group.id, user_ids: [user1.id, user2.id] }
        expect(group.reload.users.count).to eq 2
      end
    end

    context "with a group member" do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:group_members) { [user1] }

      it "adds users" do
        post :add_users, params: { id: group.id, user_ids: [user2.id] }
        expect(group.reload.users.count).to eq 2
      end
    end

    context "with a global role membership" do
      render_views

      let!(:member_group) do
        create(:global_member,
               principal: group,
               roles: [create(:global_role)])
      end

      it "displays edit memberships" do
        get :edit, params: { id: group.id, tab: "memberships" }

        expect(response).to be_successful
        expect(response).to render_template "edit"
      end
    end

    context "with project and role" do
      let(:project) { create(:project) }
      let(:role1) { create(:project_role) }
      let(:role2) { create(:project_role) }

      it "creates membership" do
        post :create_memberships,
             params: { id: group.id, membership: { project_id: project.id, role_ids: [role1.id, role2.id] } }

        expect(group.reload.members.count).to eq 1
        expect(group.members.first.roles.count).to eq 2
      end

      context "with an existing membership" do
        let!(:member_group) do
          create(:member,
                 project:,
                 principal: group,
                 roles: [role1])
        end

        it "edits a membership" do
          expect(group.members.count).to eq 1
          expect(group.members.first.roles.count).to eq 1

          put :edit_membership,
              params: {
                id: group.id,
                membership_id: group.members.first.id,
                membership: { project_id: project.id, role_ids: [role1.id, role2.id] }
              }

          group.reload
          expect(group.members.count).to eq 1
          expect(group.members.first.roles.count).to eq 2
        end

        it "can destroy the membership" do
          delete :destroy_membership, params: { id: group.id, membership_id: group.members.first.id }
          expect(group.reload.members.count).to eq 0
        end
      end
    end
  end

  context "as regular user" do
    let(:user) { create(:user) }
    let(:current_user) { user }

    it "forbids index" do
      get :index
      expect(response).not_to be_successful
      expect(response).to have_http_status :forbidden
    end

    it "shows" do
      get :show, params: { id: group.id }
      expect(response).to be_successful
      expect(response).to render_template "show"
    end

    it "forbids new" do
      get :new
      expect(response).not_to be_successful
      expect(response).to have_http_status :forbidden
    end

    it "forbids create" do
      expect do
        post :create, params: { group: { lastname: "New group" } }
      end.not_to(change(Group, :count))

      expect(response).not_to be_successful
      expect(response).to have_http_status :forbidden
    end

    it "forbids edit" do
      get :edit, params: { id: group.id }

      expect(response).not_to be_successful
      expect(response).to have_http_status :forbidden
    end
  end
end
