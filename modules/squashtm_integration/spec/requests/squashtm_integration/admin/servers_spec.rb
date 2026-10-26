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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "SquashTM server administration",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }

  let(:current_user) { admin }
  let(:connection_check) { instance_double(SquashTMIntegration::ConnectionCheck, call: nil) }
  let(:server_path) { "/squashtm_integration/admin/server" }

  before do
    allow(SquashTMIntegration::ConnectionCheck).to receive(:new).and_return(connection_check)
    login_as current_user
  end

  describe "GET /squashtm_integration/admin/server" do
    it "renders the form without the stored token" do
      create(:squashtm_server, api_token: "secret-token")

      get server_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://squashtm.example.com/squash")
      expect(response.body).not_to include("secret-token")
    end

    context "for a non-admin" do
      let(:current_user) { create(:user) }

      it "is forbidden" do
        get server_path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /squashtm_integration/admin/server" do
    let(:params) do
      { squashtm_server: { base_url: "https://squashtm.example.com/squash/", api_token: "new-token" } }
    end

    it "creates the server when none exists" do
      patch server_path, params: params

      expect(response).to redirect_to(server_path)
      server = SquashTMIntegration::Server.sole
      expect(server.base_url).to eq("https://squashtm.example.com/squash")
      expect(server.api_token).to eq("new-token")
    end

    it "keeps the stored token when the token field is left empty" do
      create(:squashtm_server, api_token: "stored-token")

      patch server_path, params: { squashtm_server: { base_url: "https://other.example.com/squash", api_token: "" } }

      expect(response).to redirect_to(server_path)
      server = SquashTMIntegration::Server.sole
      expect(server.base_url).to eq("https://other.example.com/squash")
      expect(server.api_token).to eq("stored-token")
    end

    it "shows the errors and saves nothing when the connection check fails" do
      allow(connection_check).to receive(:call) { |errors| errors.add(:api_token, :rejected) }

      patch server_path, params: params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("was rejected by the SquashTM server")
      expect(SquashTMIntegration::Server).not_to exist
    end
  end

  describe "POST /squashtm_integration/admin/server/test_connection" do
    before { create(:squashtm_server) }

    it "reports a successful connection" do
      post "#{server_path}/test_connection"

      expect(response).to redirect_to(server_path)
      expect(flash[:notice]).to eq("The connection to SquashTM was successful.")
    end

    it "reports why the connection failed" do
      allow(connection_check).to receive(:call) { |errors| errors.add(:api_token, :rejected) }

      post "#{server_path}/test_connection"

      expect(flash[:error]).to include("API token was rejected by the SquashTM server.")
    end
  end

  describe "GET /squashtm_integration/admin/server/destroy_dialog" do
    it "renders the confirmation dialog" do
      create(:squashtm_server)

      get "#{server_path}/destroy_dialog", as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Delete the SquashTM server configuration?")
    end

    it "is not found when no server is configured" do
      get "#{server_path}/destroy_dialog", as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /squashtm_integration/admin/server" do
    it "deletes the server" do
      create(:squashtm_server)

      delete server_path

      expect(response).to redirect_to(server_path)
      expect(SquashTMIntegration::Server).not_to exist
    end

    it "is not found when no server is configured" do
      delete server_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
