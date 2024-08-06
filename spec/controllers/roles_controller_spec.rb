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
  let(:user) do
    build_stubbed(:admin)
  end
  let(:params) do
    {
      role: {
        name: "A role name",
        permissions: ["add_work_packages", "edit_work_packages", "log_own_time", ""],
        assignable: "0"
      },
      copy_workflow_from: "5"
    }
  end

  current_user { user }

  describe "#create" do
    let(:new_role) { double("role double") }
    let(:service_call) { ServiceResult.success(result: new_role) }
    let(:create_params) do
      cp = ActionController::Parameters.new(params[:role])
                 .merge(global_role: nil, copy_workflow_from: "5")
      cp.permit!

      cp
    end
    let(:create_service) do
      service_double = double("create service")

      expect(Roles::CreateService)
        .to receive(:new)
        .with(user:)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(create_params)
        .and_return(service_call)
    end

    before do
      create_service

      post :create, params:
    end

    context "success" do
      context "for a member role" do
        it "redirects to roles#index" do
          expect(response)
            .to redirect_to(roles_path)
        end

        it "has a flash message" do
          expect(flash[:notice])
            .to eql I18n.t(:notice_successful_create)
        end
      end

      context "for a global role" do
        let(:params) do
          {
            role: {
              name: "A role name",
              permissions: ["add_work_packages", "edit_work_packages", "log_time", ""],
              assignable: "0"
            },
            global_role: "1",
            copy_workflow_from: "5"
          }
        end
        let(:create_params) do
          cp = ActionController::Parameters.new(params[:role])
                 .merge(global_role: "1", copy_workflow_from: "5")
          cp.permit!

          cp
        end

        it "redirects to roles#index" do
          expect(response)
            .to redirect_to(roles_path)
        end

        it "has a flash message" do
          expect(flash[:notice])
            .to eql I18n.t(:notice_successful_create)
        end
      end
    end

    context "failure" do
      let(:service_call) { ServiceResult.failure(result: new_role) }

      it "returns a 200 OK" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the new template" do
        expect(response)
          .to render_template("roles/new")
      end

      it "has the service call assigned" do
        expect(assigns[:call])
          .to eql service_call
      end

      it "has the role assigned" do
        expect(assigns[:role])
          .to eql new_role
      end
    end
  end

  describe "#update" do
    let(:params) do
      {
        id: role.id,
        role: {
          name: "A role name",
          permissions: ["add_work_packages", "edit_work_packages", "log_time", ""],
          assignable: "0"
        }
      }
    end
    let(:role) do
      double("role double", id: 6).tap do |d|
        allow(Role)
          .to receive(:find)
          .with(d.id.to_s)
          .and_return(d)
      end
    end
    let(:service_call) { ServiceResult.success(result: role) }
    let(:update_params) do
      cp = ActionController::Parameters.new(params[:role])
      cp.permit!

      cp
    end
    let(:update_service) do
      service_double = double("update service")

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user:, model: role)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params)
        .and_return(service_call)
    end

    before do
      update_service

      put :update, params:
    end

    context "success" do
      it "redirects to roles#index" do
        expect(response)
          .to redirect_to(roles_path)
      end

      it "has a flash message" do
        expect(flash[:notice])
          .to eql I18n.t(:notice_successful_update)
      end
    end

    context "failure" do
      let(:service_call) { ServiceResult.failure(result: role) }

      it "returns a 200 OK" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the edit template" do
        expect(response)
          .to render_template("roles/edit")
      end

      it "has the service call assigned" do
        expect(assigns[:call])
          .to eql service_call
      end

      it "has the role assigned" do
        expect(assigns[:role])
          .to eql role
      end
    end
  end

  describe "#bulk_update" do
    let(:params) do
      {
        permissions: { "0" => "", "1" => ["edit_work_packages"], "3" => %w(add_work_packages delete_work_packages) }
      }
    end
    let(:role0) do
      double("role double", id: 0)
    end
    let(:role1) do
      double("role double", id: 1)
    end
    let(:role2) do
      double("role double", id: 2)
    end
    let(:role3) do
      double("role double", id: 3)
    end
    let(:roles) do
      [role0, role1, role2, role3]
    end

    let!(:stub_roles_scope) do
      allow(controller)
        .to receive(:roles_scope)
        .and_return(roles)
    end

    let(:service_call0) { ServiceResult.success(result: role0) }
    let(:service_call1) { ServiceResult.success(result: role1) }
    let(:service_call2) { ServiceResult.success(result: role2) }
    let(:service_call3) { ServiceResult.success(result: role3) }
    let(:update_params0) do
      { permissions: [] }
    end
    let(:update_service0) do
      service_double = double("update service")

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user:, model: role0)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params0)
        .and_return(service_call0)
    end
    let(:update_params1) do
      { permissions: params[:permissions]["1"] }
    end
    let(:update_service1) do
      service_double = double("update service")

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user:, model: role1)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params1)
        .and_return(service_call1)
    end
    let(:update_params2) do
      { permissions: [] }
    end
    let(:update_service2) do
      service_double = double("update service")

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user:, model: role2)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params2)
        .and_return(service_call2)
    end
    let(:update_params3) do
      { permissions: params[:permissions]["3"] }
    end
    let(:update_service3) do
      service_double = double("update service")

      expect(Roles::UpdateService)
        .to receive(:new)
        .with(user:, model: role3)
        .and_return(service_double)

      expect(service_double)
        .to receive(:call)
        .with(update_params3)
        .and_return(service_call3)
    end

    before do
      update_service0
      update_service1
      update_service2
      update_service3

      put :bulk_update, params:
    end

    context "success" do
      it "redirects to roles#index" do
        expect(response)
          .to redirect_to(roles_path)
      end

      it "has a flash message" do
        expect(flash[:notice])
          .to eql I18n.t(:notice_successful_update)
      end
    end

    context "failure" do
      let(:service_call2) { ServiceResult.failure(result: role2) }

      it "returns a 200 OK" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the report template" do
        expect(response)
          .to render_template("roles/report")
      end

      it "has the service call assigned" do
        expect(assigns[:calls])
          .to contain_exactly(service_call0, service_call1, service_call2, service_call3)
      end

      it "has the roles assigned" do
        expect(assigns[:roles])
          .to match_array roles
      end
    end
  end

  describe "#destroy" do
    let(:role) { create(:project_role) }
    let(:params) { { id: role.id } }

    subject { delete(:destroy, params:) }

    context "with the role not in use" do
      it "redirects and destroyes the role" do
        allow_any_instance_of(Role).to receive(:permissions).and_return([:read_files])
        role
        expect(Role.count).to eq(1)
        expect(enqueued_jobs.count).to eq(0)

        subject

        expect(enqueued_jobs.count).to eq(1)
        expect(enqueued_jobs[0][:job]).to eq(Storages::ManageStorageIntegrationsJob)
        expect(response).to redirect_to roles_path
        expect(Role.count).to eq(0)
      end
    end

    context "with the role in use" do
      it "redirects with a flash error" do
        allow_any_instance_of(Role).to receive(:deletable?).and_return(false)
        role
        expect(Role.count).to eq(1)
        expect(enqueued_jobs.count).to eq(0)

        subject

        expect(enqueued_jobs.count).to eq(0)
        expect(Role.count).to eq(1)
        expect(response).to redirect_to roles_path
        expect(flash[:error]).to eq I18n.t(:error_can_not_remove_role)
      end
    end
  end

  describe "#report" do
    let!(:stub_roles_scope) do
      allow(controller)
        .to receive(:roles_scope)
              .and_return(roles)
    end
    let!(:roles) do
      build_stubbed_list(:project_role, 1)
    end

    before do
      delete :report
    end

    it "is successful" do
      expect(response)
        .to have_http_status :ok
    end

    it "renders the template" do
      expect(response)
        .to render_template :report
    end

    it "assigns permissions" do
      expect(assigns(:permissions))
        .to match OpenProject::AccessControl.permissions.reject(&:public?)
    end

    it "assigns roles" do
      expect(assigns(:roles))
        .to match roles
    end
  end
end
