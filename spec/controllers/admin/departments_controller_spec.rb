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

RSpec.describe Admin::DepartmentsController do
  before do
    login_as current_user
  end

  context "as admin" do
    shared_let(:admin) { create(:admin) }
    let(:current_user) { admin }

    describe "#index" do
      it "is successful" do
        get :index
        expect(response).to be_successful
        expect(response).to render_template "index"
      end
    end

    describe "#show" do
      let(:department) { create(:department) }

      it "renders the index template" do
        get :show, params: { id: department.id }
        expect(response).to be_successful
        expect(response).to render_template "index"
      end
    end

    describe "#edit" do
      let(:department) { create(:department) }

      it "is successful" do
        get :edit, params: { id: department.id }
        expect(response).to be_successful
        expect(response).to render_template "edit"
      end
    end

    describe "#update" do
      let(:department) { create(:department) }

      it "updates the department name" do
        expect do
          patch :update, params: { id: department.id, group: { lastname: "New Name" } }
        end.to change { department.reload.name }.to("New Name")

        expect(response).to redirect_to edit_admin_department_path(department)
      end
    end

    describe "#new_user" do
      render_views

      let(:department) { create(:department) }

      it "renders the add user form" do
        get :new_user, params: { id: department.id }

        expect(response).to be_successful
        expect(response.body).to include(add_user_admin_department_path(department))
      end
    end

    describe "#add_user" do
      let(:department) { create(:department) }
      let(:user_to_add) { create(:user) }

      it "adds the user to the department" do
        post :add_user, params: { id: department.id, user_id: user_to_add.id }

        expect(department.reload.users).to include(user_to_add)
        expect(flash[:notice]).to eq I18n.t("departments.flash.user_added")
        expect(response).to redirect_to admin_department_path(department)
      end

      context "when user is already in another department" do
        let(:other_department) { create(:department, members: [user_to_add]) }

        before { other_department }

        render_views

        it "responds with a move user dialog" do
          post :add_user, params: { id: department.id, user_id: user_to_add.id }, format: :turbo_stream

          expect(response).to be_successful
          expect(response.media_type).to eq "text/vnd.turbo-stream.html"
          expect(response.body).to include(Admin::Departments::MoveUserDialogComponent::DIALOG_ID)
          expect(response.body).to include(other_department.name)
          expect(response.body).to include(user_to_add.name)
          expect(department.reload.users).not_to include(user_to_add)
          expect(other_department.reload.users).to include(user_to_add)
        end

        context "with remove_from_previous_department flag" do
          it "moves the user to the new department" do
            post :add_user, params: {
              id: department.id,
              user_id: user_to_add.id,
              remove_from_previous_department: "true"
            }

            expect(department.reload.users).to include(user_to_add)
            expect(other_department.reload.users).not_to include(user_to_add)
            expect(flash[:notice]).to eq I18n.t("departments.flash.user_added")
            expect(response).to redirect_to admin_department_path(department)
          end
        end
      end
    end

    describe "#remove_user" do
      let(:user_to_remove) { create(:user) }
      let(:department) { create(:department, members: [user_to_remove]) }

      it "removes the user from the department" do
        delete :remove_user, params: { id: department.id, user_id: user_to_remove.id }

        expect(department.reload.users).not_to include(user_to_remove)
        expect(flash[:notice]).to eq I18n.t("departments.flash.user_removed")
        expect(response).to redirect_to admin_department_path(department)
      end
    end

    describe "#change_parent_dialog" do
      render_views

      let(:department) { create(:department) }

      it "renders the change parent dialog with the department tree" do
        get :change_parent_dialog, params: { id: department.id }, format: :turbo_stream

        expect(response).to be_successful
        expect(response.media_type).to eq "text/vnd.turbo-stream.html"
        expect(response.body).to include(Admin::Departments::ChangeParentDialogComponent::DIALOG_ID)
        expect(response.body).to include(department.name)
      end
    end

    describe "#change_parent" do
      let(:department) { create(:department, parent: old_parent) }
      let(:old_parent) { create(:department) }
      let(:new_parent) { create(:department) }

      it "moves the department to a new parent" do
        post :change_parent, params: {
          id: department.id,
          new_parent_id: [{ value: new_parent.id }.to_json]
        }

        expect(department.reload.parent).to eq new_parent
        expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
        expect(response).to redirect_to admin_department_path(new_parent)
      end

      it "moves the department to root level" do
        post :change_parent, params: { id: department.id, new_parent_id: [] }

        expect(department.reload.parent_id).to be_nil
        expect(response).to redirect_to admin_department_path(department)
      end
    end

    describe "#new_department" do
      render_views

      it "renders the add department form" do
        get :new_department

        expect(response).to be_successful
        expect(response.body).to include(add_department_admin_departments_path)
      end

      context "with a parent department" do
        let(:parent) { create(:department) }

        it "renders the add department form with parent context" do
          get :new_department, params: { parent_id: parent.id }

          expect(response).to be_successful
          expect(response.body).to include(add_department_admin_departments_path)
          expect(response.body).to include(parent.name)
        end
      end
    end

    describe "#add_department" do
      it "creates a new department" do
        expect do
          post :add_department, params: { group: { lastname: "New Department" } }
        end.to change { Group.organizational_units.count }.by(1)

        expect(flash[:notice]).to eq I18n.t("departments.flash.department_created")
      end

      context "with a parent department" do
        let(:parent) { create(:department) }

        it "creates a child department and redirects to the parent" do
          post :add_department, params: { group: { lastname: "Child", parent_id: parent.id } }

          child = Group.find_by(lastname: "Child")
          expect(child.parent).to eq parent
          expect(response).to redirect_to admin_department_path(parent)
        end
      end

      context "with invalid params" do
        it "does not create a department" do
          expect do
            post :add_department, params: { group: { lastname: "" } }
          end.not_to change(Group, :count)
        end
      end
    end

    describe "#edit_organization_name" do
      render_views

      it "renders the organization name form" do
        get :edit_organization_name, format: :turbo_stream

        expect(response).to be_successful
        expect(response.media_type).to eq "text/vnd.turbo-stream.html"
        expect(response.body).to include(update_organization_name_admin_departments_path)
        expect(response.body).to include("organization_name")
      end
    end

    describe "#cancel_edit_organization_name" do
      render_views

      it "renders the organization name display" do
        patch :cancel_edit_organization_name, format: :turbo_stream

        expect(response).to be_successful
        expect(response.media_type).to eq "text/vnd.turbo-stream.html"
        expect(response.body).to include(edit_organization_name_admin_departments_path)
      end
    end

    describe "#update_organization_name" do
      render_views

      it "updates the setting and renders the updated name" do
        patch :update_organization_name, params: { organization_name: "Acme Corp" }, format: :turbo_stream

        expect(response).to be_successful
        expect(response.media_type).to eq "text/vnd.turbo-stream.html"
        expect(Setting.organization_name).to eq "Acme Corp"
        expect(response.body).to include("Acme Corp")
      end
    end

    describe "#create_memberships" do
      let(:department) { create(:department) }
      let(:project) { create(:project) }
      let(:role) { create(:project_role) }

      it "creates a membership for the department" do
        post :create_memberships,
             params: { id: department.id, membership: { project_id: project.id, role_ids: [role.id] } }

        expect(department.reload.members.count).to eq 1
        expect(department.members.first.roles).to include(role)
      end
    end

    describe "#edit_membership" do
      let(:department) { create(:department) }
      let(:project) { create(:project) }
      let(:role1) { create(:project_role) }
      let(:role2) { create(:project_role) }
      let!(:member) { create(:member, project:, principal: department, roles: [role1]) }

      it "updates the membership roles" do
        patch :edit_membership,
              params: {
                id: department.id,
                membership_id: member.id,
                membership: { project_id: project.id, role_ids: [role1.id, role2.id] }
              }

        expect(member.reload.roles).to contain_exactly(role1, role2)
      end
    end

    describe "#destroy" do
      let!(:department) { create(:department) }

      it "schedules deletion and redirects to index" do
        perform_enqueued_jobs do
          delete :destroy, params: { id: department.id }
        end

        expect { department.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(flash[:info]).to eq I18n.t(:notice_deletion_scheduled)
        expect(response).to redirect_to admin_departments_path
      end

      context "with a parent department" do
        let(:parent) { create(:department) }
        let!(:department) { create(:department, parent:) }

        it "redirects to the parent department" do
          perform_enqueued_jobs do
            delete :destroy, params: { id: department.id }
          end

          expect { department.reload }.to raise_error ActiveRecord::RecordNotFound
          expect(response).to redirect_to admin_department_path(parent)
        end
      end
    end

    describe "#destroy_membership" do
      let(:department) { create(:department) }
      let(:project) { create(:project) }
      let(:role) { create(:project_role) }
      let!(:member) { create(:member, project:, principal: department, roles: [role]) }

      it "destroys the membership" do
        expect do
          delete :destroy_membership, params: { id: department.id, membership_id: member.id }
        end.to change(Member, :count).by(-1)

        expect(flash[:notice]).to eq I18n.t(:notice_successful_delete)
        expect(response).to redirect_to edit_admin_department_path(department, tab: "memberships")
      end
    end
  end

  context "as regular user" do
    let(:current_user) { create(:user) }
    let(:department) { create(:department) }

    it "forbids index" do
      get :index
      expect(response).to have_http_status :forbidden
    end

    it "forbids show" do
      get :show, params: { id: department.id }
      expect(response).to have_http_status :forbidden
    end

    it "forbids edit" do
      get :edit, params: { id: department.id }
      expect(response).to have_http_status :forbidden
    end

    it "forbids update" do
      patch :update, params: { id: department.id, group: { lastname: "Hacked" } }
      expect(response).to have_http_status :forbidden
    end

    it "forbids new_user" do
      get :new_user, params: { id: department.id }
      expect(response).to have_http_status :forbidden
    end

    it "forbids add_user" do
      post :add_user, params: { id: department.id, user_id: 0 }
      expect(response).to have_http_status :forbidden
    end

    it "forbids remove_user" do
      delete :remove_user, params: { id: department.id, user_id: 0 }
      expect(response).to have_http_status :forbidden
    end

    it "forbids destroy" do
      delete :destroy, params: { id: department.id }
      expect(response).to have_http_status :forbidden
    end

    it "forbids change_parent_dialog" do
      get :change_parent_dialog, params: { id: department.id }, format: :turbo_stream
      expect(response).to have_http_status :forbidden
    end

    it "forbids change_parent" do
      post :change_parent, params: { id: department.id, new_parent_id: [] }
      expect(response).to have_http_status :forbidden
    end

    it "forbids new_department" do
      get :new_department
      expect(response).to have_http_status :forbidden
    end

    it "does not create a department" do
      expect do
        post :add_department, params: { group: { lastname: "Hacked" } }
      end.not_to change(Group, :count)

      expect(response).to have_http_status :forbidden
    end

    it "forbids edit_organization_name" do
      get :edit_organization_name, format: :turbo_stream
      expect(response).to have_http_status :forbidden
    end

    it "forbids cancel_edit_organization_name" do
      patch :cancel_edit_organization_name, format: :turbo_stream
      expect(response).to have_http_status :forbidden
    end

    it "forbids update_organization_name" do
      patch :update_organization_name, params: { organization_name: "Hacked" }, format: :turbo_stream
      expect(response).to have_http_status :forbidden
    end

    it "forbids create_memberships" do
      post :create_memberships,
           params: { id: department.id, membership: { project_id: 0, role_ids: [0] } }
      expect(response).to have_http_status :forbidden
    end

    it "forbids edit_membership" do
      patch :edit_membership,
            params: { id: department.id, membership_id: 0, membership: { project_id: 0, role_ids: [0] } }
      expect(response).to have_http_status :forbidden
    end

    it "forbids destroy_membership" do
      delete :destroy_membership, params: { id: department.id, membership_id: 0 }
      expect(response).to have_http_status :forbidden
    end
  end
end
