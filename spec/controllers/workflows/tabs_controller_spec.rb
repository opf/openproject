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

RSpec.describe Workflows::TabsController do
  let!(:role_scope) do
    role_scope = instance_double(ActiveRecord::Relation)

    allow(Role)
      .to receive(:where)
            .with(type: ProjectRole.name)
            .and_return(role_scope)

    allow(role_scope)
      .to receive(:order)
            .and_return(role_scope)

    allow(role_scope)
      .to receive(:find)
            .with(role.id.to_s)
            .and_return(role)

    allow(role_scope)
      .to receive(:where)
            .with(id: [role.id.to_s])
            .and_return([role])

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
    end
  end

  current_user { build_stubbed(:admin) }

  describe "#edit" do
    context "when not a turbo frame request" do
      context "with a single role" do
        it "redirects to the parent workflow edit path" do
          get :edit,
              params: {
                role_ids: [role.id.to_s],
                workflow_type_id: type.id.to_s,
                tab: "always"
              }

          expect(response).to redirect_to(
            edit_workflow_path(type, role_ids: [role.id.to_s], tab: "always")
          )
        end

        it "does not forward status_ids to the redirect" do
          get :edit,
              params: {
                role_ids: [role.id.to_s],
                workflow_type_id: type.id.to_s,
                tab: "always",
                status_ids: ["1", "2"]
              }

          expect(response).to redirect_to(
            edit_workflow_path(type, role_ids: [role.id.to_s], tab: "always")
          )
          expect(response.location).not_to include("status_ids")
        end
      end

      context "with multiple roles" do
        let(:role2) { build_stubbed(:project_role) }

        before do
          allow(role_scope)
            .to receive(:where)
                  .with(id: [role.id.to_s, role2.id.to_s])
                  .and_return([role, role2])
        end

        it "redirects preserving all role ids" do
          get :edit,
              params: {
                role_ids: [role.id.to_s, role2.id.to_s],
                workflow_type_id: type.id.to_s,
                tab: "always"
              }

          expect(response).to redirect_to(
            edit_workflow_path(type, role_ids: [role.id.to_s, role2.id.to_s], tab: "always")
          )
        end
      end
    end
  end

  describe "#confirm_statuses" do
    before do
      allow(controller)
        .to receive(:respond_with_dialog)
              .and_call_original
    end

    context "when no statuses were removed" do
      before do
        allow(controller).to receive(:statuses_for_form).and_return([])
        allow(controller).to receive(:workflows_for_form)
        allow(controller).to receive(:update_via_turbo_stream)
        allow(controller).to receive(:respond_with_turbo_streams)

        post :confirm_statuses,
             params: {
               role_ids: [role.id.to_s],
               workflow_type_id: type.id.to_s,
               status_ids: ["1", "2"],
               original_status_ids: ["1", "2"],
               tab: "always"
             },
             as: :turbo_stream
      end

      it "updates the status matrix via turbo stream" do
        expect(controller).to have_received(:update_via_turbo_stream)
        expect(controller).to have_received(:respond_with_turbo_streams)
      end
    end

    context "when statuses were removed" do
      before do
        post :confirm_statuses,
             params: {
               role_ids: [role.id.to_s],
               workflow_type_id: type.id.to_s,
               status_ids: ["1"],
               original_status_ids: ["1", "2"],
               tab: "always"
             },
             as: :turbo_stream
      end

      it "responds with the danger dialog" do
        expect(controller)
          .to have_received(:respond_with_dialog)
                .with(an_instance_of(Workflows::StatusRemovalDangerDialogComponent))
      end
    end
  end

  describe "#update" do
    let(:status_params) { { "1" => { "2" => ["always"] } } }
    let(:call_result) { ServiceResult.success }

    context "with a single role" do
      let(:service) do
        instance_double(Workflows::BulkUpdateService).tap do |dbl|
          allow(Workflows::BulkUpdateService)
            .to receive(:new)
                  .with(role: role, type: type, tab: "always")
                  .and_return(dbl)
        end
      end

      before do
        allow(service).to receive(:call).with(status_params).and_return(call_result)
        allow(controller).to receive(:statuses_for_form).and_return([build_stubbed(:status)])
        post :update,
             params: { role_ids: [role.id.to_s], workflow_type_id: type.id, tab: "always", status: status_params },
             format: :turbo_stream
      end

      it "calls the service and renders a flash turbo stream" do
        expect(service).to have_received(:call).with(status_params)
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end

    context "with multiple roles" do
      let(:role2) { build_stubbed(:project_role) }
      let(:service1) do
        instance_double(Workflows::BulkUpdateService).tap do |dbl|
          allow(Workflows::BulkUpdateService)
            .to receive(:new)
                  .with(role: role, type: type, tab: "always")
                  .and_return(dbl)
        end
      end
      let(:service2) do
        instance_double(Workflows::BulkUpdateService).tap do |dbl|
          allow(Workflows::BulkUpdateService)
            .to receive(:new)
                  .with(role: role2, type: type, tab: "always")
                  .and_return(dbl)
        end
      end

      before do
        allow(role_scope)
          .to receive(:where)
                .with(id: [role.id.to_s, role2.id.to_s])
                .and_return([role, role2])
        allow(service1).to receive(:call).with(status_params).and_return(call_result)
        allow(service2).to receive(:call).with(status_params).and_return(call_result)
        allow(controller).to receive(:statuses_for_form).and_return([build_stubbed(:status)])
        post :update,
             params: {
               role_ids: [role.id.to_s, role2.id.to_s],
               workflow_type_id: type.id,
               tab: "always",
               status: status_params
             },
             format: :turbo_stream
      end

      it "calls the service for each role and renders a flash turbo stream" do
        expect(service1).to have_received(:call).with(status_params)
        expect(service2).to have_received(:call).with(status_params)
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end
  end
end
