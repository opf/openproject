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

RSpec.describe RolesController do
  let(:user) { create(:admin) }
  let(:public_permissions) { OpenProject::AccessControl.public_permissions.map(&:name) }

  current_user { user }

  describe "#create" do
    let(:name) { "A role name" }
    let(:permissions) { %w(view_work_packages edit_work_packages) }
    let(:params) { { role: { name:, permissions: permissions + [""] } } }

    context "for a project role" do
      it "persists the role and redirects with a success message" do
        expect { post :create, params: }.to change(ProjectRole, :count).by(1)

        role = ProjectRole.find_by!(name:)
        expect(role.permissions).to match_array(permissions.map(&:to_sym) | public_permissions)
        expect(response).to redirect_to(roles_path)
        expect(flash[:notice]).to eq I18n.t(:notice_successful_create)
      end
    end

    context "for a global role" do
      let(:permissions) { %w(view_user_email) }
      let(:params) { super().merge(global_role: "1") }

      it "persists a global role and redirects with a success message" do
        expect { post :create, params: }.to change(GlobalRole, :count).by(1)

        expect(GlobalRole.find_by!(name:).permissions).to eq [:view_user_email]
        expect(response).to redirect_to(roles_path)
        expect(flash[:notice]).to eq I18n.t(:notice_successful_create)
      end
    end

    context "when copying workflows" do
      let!(:transition) { create(:status_transition, type: create(:type)) }
      let(:params) { super().merge(copy_workflow_from: transition.role_id.to_s) }

      it "copies the source role's transitions to the new role" do
        post(:create, params:)

        role = ProjectRole.find_by!(name:)
        expect(role.workflow_status_transitions)
          .to contain_exactly(have_attributes(workflow_id: transition.workflow_id,
                                              old_status_id: transition.old_status_id,
                                              new_status_id: transition.new_status_id))
        expect(response).to redirect_to(roles_path)
      end
    end

    context "with an invalid name" do
      let(:name) { "" }

      it "renders the new form with validation errors without creating a role" do
        expect { post :create, params: }.not_to change(Role, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template("roles/new")
        expect(assigns(:role)).to be_a(ProjectRole)
        expect(assigns(:role)).to be_new_record
        expect(assigns(:call).errors[:name]).to be_present
      end
    end
  end

  describe "#update" do
    let!(:role) { create(:project_role, name: "Original name", permissions: [:add_work_packages]) }
    let(:name) { "Updated role name" }
    let(:params) do
      { id: role.id, role: { name:, permissions: ["view_work_packages", "edit_work_packages", ""] } }
    end

    it "persists the changes and redirects with a success message" do
      put(:update, params:)

      expect(role.reload.name).to eq name
      expect(role.permissions).to match_array(%i(view_work_packages edit_work_packages) | public_permissions)
      expect(response).to redirect_to(roles_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
    end

    context "with an invalid name" do
      let(:name) { "" }

      it "renders edit with validation errors and preserves the stored role" do
        original_permissions = role.permissions

        put(:update, params:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template("roles/edit")
        expect(assigns(:role)).to eq role
        expect(assigns(:role).name).to eq ""
        expect(assigns(:call).errors[:name]).to be_present
        expect(role.reload.name).to eq "Original name"
        expect(role.permissions).to match_array(original_permissions)
      end
    end
  end

  describe "#bulk_update" do
    let!(:cleared_role) { create(:project_role, permissions: [:add_work_packages]) }
    let!(:updated_role) { create(:project_role, permissions: [:add_work_packages]) }
    let!(:omitted_role) { create(:project_role, permissions: [:add_work_packages]) }
    let!(:global_role) { create(:global_role) }
    let!(:hidden_role) { create(:work_package_role, permissions: [:view_work_packages]) }
    let(:permissions) { %w(view_work_packages edit_work_packages) }
    let(:params) do
      {
        permissions: {
          cleared_role.id.to_s => "",
          updated_role.id.to_s => permissions,
          global_role.id.to_s => ["view_user_email"]
        }
      }
    end

    it "updates visible roles, clears empty or omitted permissions, and leaves hidden roles unchanged" do
      put(:bulk_update, params:)

      expect(cleared_role.reload.permissions).to match_array(public_permissions)
      expect(updated_role.reload.permissions).to match_array(permissions.map(&:to_sym) | public_permissions)
      expect(omitted_role.reload.permissions).to match_array(public_permissions)
      expect(global_role.reload.permissions).to eq [:view_user_email]
      expect(hidden_role.reload.permissions).to eq [:view_work_packages]
      expect(response).to redirect_to(roles_path)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
    end

    context "with a missing permission dependency" do
      let(:permissions) { %w(edit_work_packages) }

      it "renders the report with validation errors" do
        original_permissions = updated_role.permissions

        put(:bulk_update, params:)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template("roles/report")
        expect(assigns(:roles)).to contain_exactly(cleared_role, updated_role, omitted_role, global_role)
        failed_calls = assigns(:calls).reject(&:success?)
        expect(failed_calls.map(&:result)).to contain_exactly(updated_role)
        expect(failed_calls.first.errors[:permissions]).to be_present
        expect(updated_role.reload.permissions).to match_array(original_permissions)
      end
    end
  end

  describe "#destroy" do
    let!(:role) { create(:project_role, permissions: [:read_files]) }

    context "with a deletable role" do
      it "deletes the role and schedules storage integration management" do
        expect { delete :destroy, params: { id: role.id } }
          .to change(Role, :count).by(-1)
          .and have_enqueued_job(Storages::ManageStorageIntegrationsJob)

        expect(response).to redirect_to(roles_path)
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq I18n.t(:notice_successful_delete)
      end
    end

    context "with a built-in role" do
      let!(:role) { create(:non_member, permissions: [:read_files]) }

      it "preserves the role and redirects with a flash error" do
        expect { delete :destroy, params: { id: role.id } }.not_to change(Role, :count)

        expect(enqueued_jobs).to be_empty
        expect(response).to redirect_to(roles_path)
        expect(response).to have_http_status(:see_other)
        expect(flash[:error]).to eq I18n.t(:error_can_not_remove_role)
      end
    end
  end

  describe "#report" do
    let!(:builtin_role) { create(:non_member) }
    let!(:global_role) { create(:global_role) }
    let!(:project_role) { create(:project_role) }
    let!(:hidden_role) { create(:work_package_role) }

    before do
      get :report
    end

    it "renders the report" do
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:report)
    end

    it "assigns visible, non-public permissions" do
      expect(assigns(:permissions))
        .to match_array(OpenProject::AccessControl.permissions.reject(&:public?).select(&:visible?))
    end

    it "assigns visible roles ordered by built-in status and position" do
      expect(assigns(:roles)).to eq [global_role, project_role, builtin_role]
    end
  end
end
