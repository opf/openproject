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

RSpec.describe Workflows::MatrixController do
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

  let!(:variant) do
    build_stubbed(:type_variant) do |stub|
      allow(TypeVariant)
        .to receive(:find)
              .with(stub.id.to_s)
              .and_return(stub)
    end
  end

  current_user { build_stubbed(:admin) }

  describe "#show" do
    context "when not a turbo frame request" do
      context "with a single role" do
        it "redirects to the parent workflow edit path" do
          get :show,
              params: {
                role_ids: [role.id.to_s],
                type_id: variant.type_id.to_s,
                variant_id: variant.id.to_s,
                tab: "always"
              }

          expect(response).to redirect_to(
            edit_type_workflow_path(type_id: variant.type_id, variant_id: variant.id, role_ids: [role.id.to_s], tab: "always")
          )
        end

        it "does not forward status_ids to the redirect" do
          get :show,
              params: {
                role_ids: [role.id.to_s],
                type_id: variant.type_id.to_s,
                variant_id: variant.id.to_s,
                tab: "always",
                status_ids: ["1", "2"]
              }

          expect(response).to redirect_to(
            edit_type_workflow_path(type_id: variant.type_id, variant_id: variant.id, role_ids: [role.id.to_s], tab: "always")
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
          get :show,
              params: {
                role_ids: [role.id.to_s, role2.id.to_s],
                type_id: variant.type_id.to_s,
                variant_id: variant.id.to_s,
                tab: "always"
              }

          expect(response).to redirect_to(
            edit_type_workflow_path(type_id: variant.type_id, variant_id: variant.id, role_ids: [role.id.to_s, role2.id.to_s],
                                    tab: "always")
          )
        end
      end
    end
  end

  describe "#confirm_statuses" do
    let(:status) { build_stubbed(:status) }

    # Which statuses the submit drops is the context's call, so the branch is driven through
    # it rather than through a status_ids/displayed_status_ids fixture.
    let(:matrix_context) do
      instance_double(Workflows::MatrixContext,
                      variant:,
                      tab: "always",
                      roles: [role],
                      requested_status_ids: [status.id],
                      removed_displayed_status_ids:)
    end

    def submit_statuses
      allow(controller).to receive(:respond_with_dialog).and_call_original
      allow(controller).to receive(:build_matrix_context).and_return(matrix_context)

      post :confirm_statuses,
           params: {
             role_ids: [role.id.to_s],
             type_id: variant.type_id.to_s,
             variant_id: variant.id.to_s,
             status_ids: [status.id.to_s],
             tab: "always"
           },
           as: :turbo_stream
    end

    context "when the pending selection drops nothing the dialog was showing" do
      let(:removed_displayed_status_ids) { [] }

      before do
        allow(controller).to receive(:update_via_turbo_stream)
        allow(controller).to receive(:respond_with_turbo_streams)

        submit_statuses
      end

      it "updates the status matrix via turbo stream" do
        expect(controller).to have_received(:update_via_turbo_stream)
        expect(controller).to have_received(:respond_with_turbo_streams)
      end
    end

    context "when the pending selection drops a status the dialog was showing" do
      let(:removed_displayed_status_ids) { [build_stubbed(:status).id] }

      before { submit_statuses }

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
    let(:roles) { [role] }

    let(:service) do
      instance_double(Workflows::MatrixUpdateService, call: call_result).tap do |dbl|
        allow(Workflows::MatrixUpdateService)
          .to receive(:new)
                .with(variant:, roles:, tab: "always")
                .and_return(dbl)
      end
    end

    # Statuses remain, so the response is the flash alone — the blankslate replacement is
    # covered by the feature specs.
    let(:matrix_context) do
      instance_double(Workflows::MatrixContext, roles:, tab: "always", statuses: [build_stubbed(:status)])
    end

    def submit_matrix
      service
      allow(controller).to receive(:build_matrix_context).and_return(matrix_context)

      post :update,
           params: {
             role_ids: roles.map { it.id.to_s },
             type_id: variant.type_id,
             variant_id: variant.id,
             tab: "always",
             status: status_params
           },
           format: :turbo_stream
    end

    it "hands the submitted matrix to the service and renders a flash turbo stream" do
      submit_matrix

      expect(service).to have_received(:call).with(
        status: satisfy { it.to_unsafe_h == status_params },
        indeterminate_status: nil
      )
      expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
    end

    context "with multiple roles" do
      let(:role2) { build_stubbed(:project_role) }
      let(:roles) { [role, role2] }

      before do
        allow(role_scope)
          .to receive(:where)
                .with(id: [role.id.to_s, role2.id.to_s])
                .and_return(roles)
      end

      it "passes every selected role to the service" do
        submit_matrix

        expect(Workflows::MatrixUpdateService)
          .to have_received(:new).with(variant:, roles:, tab: "always")
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end

    context "when the service fails" do
      let(:call_result) { ServiceResult.failure }

      it "responds unprocessable with a danger flash" do
        submit_matrix

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      end
    end
  end
end
