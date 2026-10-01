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

RSpec.describe Documents::RefreshTokensController do
  let(:project) { create(:project) }
  let(:document) { create(:document, project:) }
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_documents]) }

  before do
    allow(Setting)
      .to receive(:collaborative_editing_hocuspocus_secret)
      .and_return("test_secret_for_encryption")
  end

  describe "POST #create" do
    context "when user is not logged in" do
      it "redirects to login" do
        post :create, params: { project_id: project.id, document_id: document.id }

        expect(response).to redirect_to(signin_path(back_url: project_document_refresh_token_url(project.id, document)))
      end
    end

    context "when user is logged in but lacks permission" do
      before do
        login_as(user)
      end

      it "returns not found" do
        post :create, params: { project_id: project.id, document_id: document.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user has view_documents permission" do
      before do
        login_as(user)
        create(:member, project:, user:, roles: [role])
      end

      it "returns a successful JSON response" do
        expect do
          post :create, params: { project_id: project.id, document_id: document.id }
        end.to change(Doorkeeper::AccessToken, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("application/json")

        json = response.parsed_body

        aggregate_failures "returns token metadata" do
          expect(json).to have_key("encrypted_token")
          expect(json).to have_key("expires_in_seconds")
        end

        aggregate_failures "valid expiration values" do
          expect(json["expires_in_seconds"]).to eq(5.minutes.to_i)
        end
      end
    end

    context "when document does not exist" do
      before do
        login_as(user)
      end

      it "returns not found" do
        post :create, params: { project_id: project.id, document_id: 999_999 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when token generation fails" do
      before do
        login_as(user)
        create(:member, project:, user:, roles: [role])

        allow(Setting)
          .to receive(:collaborative_editing_hocuspocus_secret)
          .and_return(nil)
      end

      it "returns unprocessable entity" do
        post :create, params: { project_id: project.id, document_id: document.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json).to have_key("error")
      end
    end
  end
end
