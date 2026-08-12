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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe "Admin wiki OAuth clients", :skip_csrf, type: :rails_request do
  let(:admin) { create(:admin) }
  let(:non_admin) { create(:user) }
  let(:wiki_provider) { create(:xwiki_provider) }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  shared_examples "a turbo stream response" do
    it { expect(response).to have_http_status(:ok) }
    it { expect(response.media_type).to eq("text/vnd.turbo-stream.html") }
  end

  shared_examples "an admin-only endpoint" do
    context "when not admin" do
      before do
        login_as non_admin
        send_request
      end

      it { expect(response).not_to have_http_status(:ok) }
    end
  end

  describe "GET /admin/settings/wiki_providers/:wiki_provider_id/oauth_client/new" do
    let(:send_request) do
      get new_admin_settings_wiki_provider_oauth_client_path(wiki_provider), headers: turbo_headers
    end

    it_behaves_like "an admin-only endpoint"

    context "when admin" do
      before do
        login_as admin
        send_request
      end

      it_behaves_like "a turbo stream response"
    end
  end

  describe "POST /admin/settings/wiki_providers/:wiki_provider_id/oauth_client" do
    let(:params) { { oauth_client: { client_id: "my-client-id", client_secret: "my-secret" } } }
    let(:send_request) do
      post admin_settings_wiki_provider_oauth_client_path(wiki_provider), params:, headers: turbo_headers
    end

    it_behaves_like "an admin-only endpoint"

    context "when admin" do
      before { login_as admin }

      context "with valid params" do
        before { send_request }

        it_behaves_like "a turbo stream response"

        it "creates an oauth client" do
          expect(OAuthClient.count).to eq(1)
        end
      end

      context "with valid params and continue_wizard" do
        let(:params) do
          { oauth_client: { client_id: "my-client-id", client_secret: "my-secret" },
            continue_wizard: wiki_provider.id }
        end

        before { send_request }

        it "redirects to the wizard next step" do
          expect(response).to redirect_to(new_admin_settings_wiki_provider_path(continue_wizard: wiki_provider.id))
        end
      end

      context "with invalid params" do
        let(:params) { { oauth_client: { client_id: "", client_secret: "" } } }

        before { send_request }

        it_behaves_like "a turbo stream response"

        it "does not create an oauth client" do
          expect(OAuthClient.count).to eq(0)
        end
      end
    end
  end

  describe "PATCH /admin/settings/wiki_providers/:wiki_provider_id/oauth_client" do
    let!(:oauth_client) { create(:oauth_client, integration: wiki_provider) }
    let(:params) { { oauth_client: { client_id: "new-id", client_secret: "new-secret" } } }
    let(:send_request) do
      patch admin_settings_wiki_provider_oauth_client_path(wiki_provider), params:, headers: turbo_headers
    end

    it_behaves_like "an admin-only endpoint"

    context "when admin" do
      before do
        login_as admin
        send_request
      end

      it_behaves_like "a turbo stream response"

      it "updates the oauth client credentials" do
        expect(wiki_provider.reload.oauth_client.client_id).to eq("new-id")
      end
    end
  end
end
