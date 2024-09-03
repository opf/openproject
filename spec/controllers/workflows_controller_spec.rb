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

RSpec.describe WorkflowsController do
  let!(:role_scope) do
    role_scope = instance_double(ActiveRecord::Relation)

    allow(Role)
      .to receive(:where)
            .with(type: ProjectRole.name)
            .and_return(role_scope)

    allow(role_scope)
      .to receive_messages(order: role_scope, find_by: nil)

    allow(role_scope)
      .to receive(:find)
            .with(role.id.to_s)
            .and_return(role)

    allow(role_scope)
      .to receive(:find_by)
            .with(id: role.id.to_s)
            .and_return(role)

    role_scope
  end

  let!(:role) do
    build_stubbed(:project_role)
  end
  let!(:type) do
    build_stubbed(:type) do |t|
      allow(Type)
        .to receive(:find)
              .with(t.id.to_s)
              .and_return(t)

      allow(Type)
        .to receive(:find_by)
              .and_return(nil)

      allow(Type)
        .to receive(:find_by)
              .with(id: t.id.to_s)
              .and_return(t)
    end
  end

  current_user { build_stubbed(:admin) }

  describe "#index" do
    let(:counts) { instance_double(Hash) }

    before do
      allow(Workflow)
        .to receive(:count_by_type_and_role)
        .and_return(counts)

      get :show
    end

    it "is successful" do
      expect(response)
        .to be_successful
    end

    it "assigns the workflows by type and role" do
      expect(assigns[:workflow_counts])
        .to eql counts
    end
  end

  describe "#edit" do
    let(:non_type_status) { build_stubbed(:status) }
    let(:type_status) { build_stubbed(:status) }

    before do
      allow(type)
        .to receive(:statuses)
              .and_return [type_status]

      allow(Status)
        .to receive(:all)
              .and_return [type_status, non_type_status]

      allow(Type)
        .to receive(:order)
              .and_return([type])

      allow(role_scope)
        .to receive(:order)
              .and_return([role])
    end

    context "without parameters" do
      before do
        get :edit
      end

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the edit template" do
        expect(response)
          .to render_template :edit
      end

      it "does not assign role" do
        expect(assigns[:role])
          .to be_nil
      end

      it "does not assign type" do
        expect(assigns[:type])
          .to be_nil
      end

      it "assigns roles" do
        expect(assigns[:roles])
          .to eq [role]
      end

      it "assigns types" do
        expect(assigns[:types])
          .to eq [type]
      end
    end

    context "with role and type params, and only used statuses" do
      before do
        get :edit, params: { role_id: role.id.to_s, type_id: type.id.to_s, used_statuses_only: "1" }
      end

      it "responds with the used statuses", :aggregate_failures do
        expect(response)
          .to have_http_status(:ok)
        expect(response)
          .to render_template :edit
        expect(assigns[:role])
          .to eq role
        expect(assigns[:type])
          .to eq type
        expect(assigns[:roles])
          .to eq [role]
        expect(assigns[:types])
          .to eq [type]
        expect(assigns[:statuses])
          .to eq type.statuses
      end
    end

    context "with role and type params, and no statuses filter" do
      before do
        get :edit, params: { role_id: role.id.to_s, type_id: type.id.to_s }
      end

      it "responds with all statuses", :aggregate_failures do
        expect(response)
          .to have_http_status(:ok)
        expect(response)
          .to render_template :edit
        expect(assigns[:role])
          .to eq role
        expect(assigns[:type])
          .to eq type
        expect(assigns[:roles])
          .to eq [role]
        expect(assigns[:types])
          .to eq [type]
        expect(assigns[:statuses])
          .to eq Status.all
      end
    end

    context "with role and type params and with all statuses" do
      before do
        get :edit, params: { role_id: role.id.to_s, type_id: type.id.to_s, used_statuses_only: "0" }
      end

      it "is successful" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the edit template" do
        expect(response)
          .to render_template :edit
      end

      it "assigns role" do
        expect(assigns[:role])
          .to eq role
      end

      it "assign type" do
        expect(assigns[:type])
          .to eq type
      end

      it "assigns roles" do
        expect(assigns[:roles])
          .to eq [role]
      end

      it "assigns types" do
        expect(assigns[:types])
          .to eq [type]
      end

      it "assigns statuses" do
        expect(assigns[:statuses])
          .to eq Status.all
      end
    end
  end

  describe "#update" do
    let(:status_params) { { "1" => "2" } }
    let(:service) do
      service = instance_double(Workflows::BulkUpdateService)

      allow(Workflows::BulkUpdateService)
        .to receive(:new)
        .with(role:, type:)
        .and_return(service)

      service
    end
    let!(:call) do
      expect(service)
        .to receive(:call)
        .with(status_params)
        .and_return(call_result)
    end
    let(:call_result) { ServiceResult.success }
    let(:params) do
      {
        role_id: role.id,
        type_id: type.id,
        status: status_params
      }
    end

    before do
      post :update, params:
    end

    it "redirects to edit" do
      expect(response)
        .to redirect_to edit_workflows_path(role_id: role.id, type_id: type.id)
    end
  end

  describe "#copy" do
    let(:target_type1) { build_stubbed(:type) }
    let(:target_type2) { build_stubbed(:type) }

    let(:target_role1) { build_stubbed(:project_role) }
    let(:target_role2) { build_stubbed(:project_role) }

    let(:params) do
      {
        source_type_id: type.id.to_s,
        source_role_id: role.id.to_s,
        target_type_ids: [target_type1.id.to_s, target_type2.id.to_s],
        target_role_ids: [target_role1.id.to_s, target_role2.id.to_s]
      }
    end

    before do
      allow(role_scope)
        .to receive(:where)
              .with(id: [target_role1.id.to_s, target_role2.id.to_s])
              .and_return([target_role1, target_role2])

      allow(Type)
        .to receive(:where)
              .with(id: [target_type1.id.to_s, target_type2.id.to_s])
              .and_return([target_type1, target_type2])

      allow(Workflow)
        .to receive(:copy)
    end

    context "with a get request" do
      before do
        get :copy, params:
      end

      it "is a success" do
        expect(response)
          .to have_http_status(:ok)
      end

      it "renders the copy template" do
        expect(response)
          .to render_template :copy
      end

      it "assigns the source_type" do
        expect(assigns[:source_type])
          .to eq type
      end

      it "assigns the source_role" do
        expect(assigns[:source_role])
          .to eq role
      end

      it "assigns the target_types" do
        expect(assigns[:target_types])
          .to eq [target_type1, target_type2]
      end

      it "assigns the target_roles" do
        expect(assigns[:target_roles])
          .to eq [target_role1, target_role2]
      end
    end

    context "when posting with all the params" do
      before do
        post :copy, params:
      end

      it "calls the Workflow.copy method" do
        expect(Workflow)
          .to have_received(:copy)
                .with(type, role, [target_type1, target_type2], [target_role1, target_role2])
      end

      it "sets a flash notice" do
        expect(flash[:notice])
          .to eq I18n.t(:notice_successful_update)
      end

      it "redirects to the copy action" do
        expect(response)
          .to redirect_to copy_workflows_path(source_type_id: type, source_role_id: role)
      end
    end

    context "when posting with 'any' for source_type" do
      let(:params) do
        {
          source_type_id: "any",
          source_role_id: role.id.to_s,
          target_type_ids: [target_type1.id.to_s, target_type2.id.to_s],
          target_role_ids: [target_role1.id.to_s, target_role2.id.to_s]
        }
      end

      before do
        post :copy, params:
      end

      it "calls the Workflow.copy method" do
        expect(Workflow)
          .to have_received(:copy)
                .with(nil, role, [target_type1, target_type2], [target_role1, target_role2])
      end

      it "sets a flash notice" do
        expect(flash[:notice])
          .to eq I18n.t(:notice_successful_update)
      end

      it "redirects to the copy action" do
        expect(response)
          .to redirect_to copy_workflows_path(source_role_id: role)
      end
    end

    context "when posting with 'any' for source_role" do
      let(:params) do
        {
          source_type_id: type.id.to_s,
          source_role_id: "any",
          target_type_ids: [target_type1.id.to_s, target_type2.id.to_s],
          target_role_ids: [target_role1.id.to_s, target_role2.id.to_s]
        }
      end

      before do
        post :copy, params:
      end

      it "calls the Workflow.copy method" do
        expect(Workflow)
          .to have_received(:copy)
                .with(type, nil, [target_type1, target_type2], [target_role1, target_role2])
      end

      it "sets a flash notice" do
        expect(flash[:notice])
          .to eq I18n.t(:notice_successful_update)
      end

      it "redirects to the copy action" do
        expect(response)
          .to redirect_to copy_workflows_path(source_type_id: type)
      end
    end

    context "when posting with 'any' for both sources" do
      let(:params) do
        {
          source_type_id: "any",
          source_role_id: "any",
          target_type_ids: [target_type1.id.to_s, target_type2.id.to_s],
          target_role_ids: [target_role1.id.to_s, target_role2.id.to_s]
        }
      end

      before do
        post :copy, params:
      end

      it "does not call the Workflow.copy method" do
        expect(Workflow)
          .not_to have_received(:copy)
      end

      it "sets a flash error" do
        expect(flash[:error])
          .to eq I18n.t(:error_workflow_copy_source)
      end

      it "renders the copy action" do
        expect(response)
          .to render_template :copy
      end
    end

    context "when posting without target_type_ids" do
      let(:params) do
        {
          source_type_id: type.id.to_s,
          source_role_id: role.id.to_s,
          target_role_ids: [target_role1.id.to_s, target_role2.id.to_s]
        }
      end

      before do
        post :copy, params:
      end

      it "does not call the Workflow.copy method" do
        expect(Workflow)
          .not_to have_received(:copy)
      end

      it "sets a flash error" do
        expect(flash[:error])
          .to eq I18n.t(:error_workflow_copy_target)
      end

      it "renders the copy action" do
        expect(response)
          .to render_template :copy
      end
    end

    context "when posting without target_role_ids" do
      let(:params) do
        {
          source_type_id: type.id.to_s,
          source_role_id: role.id.to_s,
          target_type_ids: [target_type1.id.to_s, target_type2.id.to_s]
        }
      end

      before do
        post :copy, params:
      end

      it "does not call the Workflow.copy method" do
        expect(Workflow)
          .not_to have_received(:copy)
      end

      it "sets a flash error" do
        expect(flash[:error])
          .to eq I18n.t(:error_workflow_copy_target)
      end

      it "renders the copy action" do
        expect(response)
          .to render_template :copy
      end
    end
  end
end
