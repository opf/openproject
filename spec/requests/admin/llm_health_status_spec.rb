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

RSpec.describe "LLM connection health status", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true } do
  shared_let(:admin) { create(:admin) }

  let(:base_url) { "https://example.com/v1" }

  before { login_as(admin) }

  describe "GET /admin/llm_connection/health_status_report" do
    it "redirects to the settings page when nothing is configured yet" do
      get llm_connection_health_status_report_path

      expect(response).to redirect_to(llm_connection_path)
    end

    context "with a connection" do
      let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:) }

      it "offers to run the checks when none have run" do
        get llm_connection_health_status_report_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("has not been checked yet")
      end

      it "renders the report once it exists" do
        mock_llm_models_response(base_url)
        mock_llm_chat_response(base_url)
        post llm_connection_health_status_report_path

        get llm_connection_health_status_report_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Configuration")
      end
    end

    it "sends the administrator to the settings while the connection is disabled" do
      create(:llm_connection, :with_models, base_url:)

      get llm_connection_health_status_report_path

      expect(response).to redirect_to(llm_connection_path)
      expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.disabled_notice"))
    end
  end

  describe "POST /admin/llm_connection/health_status_report" do
    let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:, default_chat_model_id: "qwen3.6-27b") }

    before do
      mock_llm_models_response(base_url)
      mock_llm_chat_response(base_url)
    end

    it "refuses to run the checks while the connection is disabled" do
      connection.update!(enabled: false)

      expect { post llm_connection_health_status_report_path }
        .not_to change(connection.health_reports, :count)

      expect(response).to redirect_to(llm_connection_path)
      expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.disabled_notice"))
    end

    it "stores a report and sends the completion an administrator asked for" do
      expect { post llm_connection_health_status_report_path }
        .to change(connection.health_reports, :count).by(1)

      expect(response).to redirect_to(llm_connection_health_status_report_path)
      expect(WebMock).to have_requested(:post, "#{base_url}/chat/completions").once
    end

    it "says what the checks found" do
      post llm_connection_health_status_report_path

      expect(flash[:notice]).to include("The checks have run")
      expect(flash[:notice]).to match(/\d+ passed/)
    end

    # Without it a second run within the same minute renders an identical page.
    it "counts the results next to the timestamp" do
      post llm_connection_health_status_report_path

      get llm_connection_health_status_report_path

      expect(response.body).to include("Last checked")
      expect(response.body).to match(/\d+ passed, \d+ warnings, \d+ failed/)
    end
  end

  describe "POST /admin/llm_connection/health_status_report/create_health_status_report" do
    let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:, default_chat_model_id: "qwen3.6-27b") }

    before do
      mock_llm_models_response(base_url)
      mock_llm_chat_response(base_url)
    end

    it "updates the side panel and confirms the run" do
      post create_health_status_report_llm_connection_health_status_report_path,
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("llm-connections-side-panel-health-status-component")
      expect(response.body).to include("The checks have run.")
    end
  end

  describe "GET /admin/llm_connection/health_status_report.txt" do
    let!(:connection) do
      create(:llm_connection, :with_models, :enabled, base_url:,
                                                      api_key: "sk-super-secret",
                                                      custom_headers: { "apikey" => "gateway-secret" })
    end

    before do
      mock_llm_models_response(base_url)
      mock_llm_chat_response(base_url)
      post llm_connection_health_status_report_path
    end

    it "downloads the report" do
      get llm_connection_health_status_report_path(format: :txt)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("base_url")
    end

    # The report is pasted into support tickets. A gateway header routinely
    # carries a second credential, so neither it nor the API key may appear.
    it "contains no credentials" do
      get llm_connection_health_status_report_path(format: :txt)

      expect(response.body).not_to include("sk-super-secret")
      expect(response.body).not_to include("gateway-secret")
    end
  end

  describe "authorisation" do
    let!(:connection) { create(:llm_connection, :enabled, base_url:) }

    it "is refused to a non-admin" do
      login_as(create(:user))

      get llm_connection_health_status_report_path

      expect(response).not_to have_http_status(:ok)
    end
  end
end
