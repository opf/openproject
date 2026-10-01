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

RSpec.describe Bim::IfcModels::IfcModelsController do
  let(:project) do
    create(:project,
           enabled_module_names: %w[bim],
           identifier: "project-a")
  end
  let(:other_project) do
    create(:project,
           enabled_module_names: %w[bim],
           identifier: "project-b")
  end
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_ifc_models manage_ifc_models]
           })
  end
  let!(:other_project_ifc_model) { create(:ifc_model, project: other_project) }

  before do
    login_as(user)
  end

  describe "#direct_upload_finished" do
    let(:pending_attachment) { create(:pending_direct_upload, author: user, container: nil, filename: "model.ifc") }
    let(:callback_nonce) { SecureRandom.hex(32) }

    before do
      session[:pending_ifc_model_title] = "My model"
      session[:pending_ifc_model_is_default] = "0"
      session[:pending_ifc_model_ifc_model_id] = nil
      session[:pending_ifc_model_attachment_id] = pending_attachment.id
      session[:pending_ifc_model_project_id] = project.id
      session[:pending_ifc_model_callback_nonce] = callback_nonce
      allow(Attachments::FinishDirectUploadJob).to receive(:perform_later)
    end

    it "rejects callbacks with tampered tokens" do
      allow(Bim::IfcModels::CreateService).to receive(:new)

      get :direct_upload_finished,
          params: {
            project_id: project.identifier,
            key: "uploads/attachment/file/#{pending_attachment.id}/model.ifc",
            du_token: "tampered-token"
          }

      expect(Bim::IfcModels::CreateService).not_to have_received(:new)
      expect(response).to redirect_to(action: :new)
      expect(flash[:error]).to eq("Direct upload failed.")
      expect(Attachments::FinishDirectUploadJob).not_to have_received(:perform_later)
    end

    it "rejects callbacks trying to claim another upload" do
      victim = create(:user)
      victim_attachment = create(:pending_direct_upload, author: victim, container: nil, filename: "victim.ifc")
      forged_token = Rails.application.message_verifier(Bim::IfcModels::IfcModelsController::DIRECT_UPLOAD_CALLBACK_PURPOSE).generate(
        {
          attachment_id: victim_attachment.id,
          project_id: project.id,
          user_id: user.id,
          nonce: callback_nonce
        },
        purpose: Bim::IfcModels::IfcModelsController::DIRECT_UPLOAD_CALLBACK_PURPOSE,
        expires_in: Bim::IfcModels::IfcModelsController::DIRECT_UPLOAD_CALLBACK_TTL
      )

      session[:pending_ifc_model_attachment_id] = victim_attachment.id
      allow(Bim::IfcModels::CreateService).to receive(:new)

      get :direct_upload_finished,
          params: {
            project_id: project.identifier,
            key: "uploads/attachment/file/#{victim_attachment.id}/victim.ifc",
            du_token: forged_token
          }

      expect(response).to redirect_to(action: :new)
      expect(flash[:error]).to eq("Direct upload failed.")
      expect(Bim::IfcModels::CreateService).not_to have_received(:new)
      expect(Attachments::FinishDirectUploadJob).not_to have_received(:perform_later)
    end
  end

  describe "#destroy" do
    it "returns not found and does not delete an IFC model from another project" do
      delete :destroy,
             params: {
               project_id: project.identifier,
               id: other_project_ifc_model.id
             }

      expect(response).to have_http_status(:not_found)
      expect(Bim::IfcModels::IfcModel.exists?(other_project_ifc_model.id)).to be(true)
    end
  end
end
