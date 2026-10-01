# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe Admin::Import::Jira::ImportRuns::SelectProjectsController do
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }
  shared_let(:jira) { create(:jira) }

  let(:jira_import) { create(:jira_import, jira:, author: admin) }

  before do
    login_as(admin)
  end

  context "when user is not an admin" do
    before { login_as(non_admin) }

    it "returns forbidden for GET #show" do
      get :show, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for PATCH #update" do
      patch :update, params: { jira_id: jira.id, run_id: jira_import.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for POST #filter" do
      post :filter, params: { jira_id: jira.id, run_id: jira_import.id, filter: "test" }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #check_all" do
      get :check_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #uncheck_all" do
      get :uncheck_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #toggle" do
      get :toggle, params: { jira_id: jira.id, run_id: jira_import.id, project_id: "10001" }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end

    it "returns forbidden for GET #switch_page" do
      get :switch_page, params: { jira_id: jira.id, run_id: jira_import.id, page: 1 }, format: :turbo_stream
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET #show" do
    let(:available_projects) do
      {
        "projects" => [
          { "id" => "10001", "name" => "Project One", "key" => "PROJ1" }
        ]
      }
    end

    before do
      jira_import.update!(available: available_projects)
    end

    it "responds with a dialog component" do
      get :show, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
    end

    it "initializes session with selected project IDs" do
      jira_import.update!(projects: [{ "id" => "10001", "name" => "Project One", "key" => "PROJ1" }])
      get :show, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(session[:selected_ids]).to eq(%w[10001])
      expect(session[:project_page]).to eq(1)
      expect(session[:project_filter]).to be_nil
    end
  end

  describe "PATCH #update" do
    let(:available_projects) do
      {
        "projects" => [
          { "id" => "10001", "name" => "Project One", "key" => "PROJ1" },
          { "id" => "10002", "name" => "Project Two", "key" => "PROJ2" },
          { "id" => "10003", "name" => "Project Three", "key" => "PROJ3" }
        ]
      }
    end

    before do
      jira_import.update!(available: available_projects)
      session[:selected_ids] = %w[10001 10002]
    end

    it "updates the selected projects" do
      patch :update, params: { jira_id: jira.id, run_id: jira_import.id }
      expect(jira_import.reload.projects).to eq([
                                                  { "id" => "10001", "name" => "Project One", "key" => "PROJ1" },
                                                  { "id" => "10002", "name" => "Project Two", "key" => "PROJ2" }
                                                ])
    end

    it "handles empty session projects" do
      session[:selected_ids] = []
      patch :update, params: { jira_id: jira.id, run_id: jira_import.id }
      expect(jira_import.reload.projects).to eq([])
    end

    it "ignores project IDs not in available projects" do
      session[:selected_ids] = %w[10001 99999]
      patch :update, params: { jira_id: jira.id, run_id: jira_import.id }
      expect(jira_import.reload.projects).to eq([
                                                  { "id" => "10001", "name" => "Project One", "key" => "PROJ1" }
                                                ])
    end

    context "when available projects is empty" do
      before do
        jira_import.update!(available: {})
      end

      it "sets projects to empty array" do
        patch :update, params: { jira_id: jira.id, run_id: jira_import.id }
        expect(jira_import.reload.projects).to eq([])
      end
    end
  end

  describe "POST #filter" do
    let(:available_projects) do
      [
        { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
        { "id" => "10002", "name" => "Project Beta", "key" => "BETA" },
        { "id" => "10003", "name" => "Gamma Project", "key" => "GAMMA" }
      ]
    end

    before do
      jira_import.update!(available: { "projects" => available_projects })
    end

    it "responds with turbo stream" do
      post :filter, params: { jira_id: jira.id, run_id: jira_import.id, filter: "Alpha" }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "stores filter in session" do
      post :filter, params: { jira_id: jira.id, run_id: jira_import.id, filter: "Alpha" }, format: :turbo_stream
      expect(session[:project_filter]).to eq("Alpha")
    end

    it "clears filter when blank" do
      session[:project_filter] = "old"
      post :filter, params: { jira_id: jira.id, run_id: jira_import.id, filter: "" }, format: :turbo_stream
      expect(session[:project_filter]).to be_nil
    end
  end

  describe "GET #check_all" do
    let(:available_projects) do
      [
        { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
        { "id" => "10002", "name" => "Project Beta", "key" => "BETA" }
      ]
    end

    before do
      jira_import.update!(available: { "projects" => available_projects })
    end

    it "responds with turbo stream" do
      get :check_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "adds visible projects to session selections" do
      session[:selected_ids] = []
      get :check_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(session[:selected_ids]).to contain_exactly("10001", "10002")
    end

    it "preserves existing selections when adding new ones" do
      session[:selected_ids] = %w[10001]
      get :check_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(session[:selected_ids]).to contain_exactly("10001", "10002")
    end
  end

  describe "GET #uncheck_all" do
    let(:available_projects) do
      [
        { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
        { "id" => "10002", "name" => "Project Beta", "key" => "BETA" }
      ]
    end

    before do
      jira_import.update!(available: { "projects" => available_projects })
    end

    it "responds with turbo stream" do
      get :uncheck_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "removes visible projects from session selections" do
      session[:selected_ids] = %w[10001 10002]
      get :uncheck_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(session[:selected_ids]).to be_empty
    end

    it "preserves selections not in visible projects" do
      session[:selected_ids] = %w[10001 10002 99999]
      get :uncheck_all, params: { jira_id: jira.id, run_id: jira_import.id }, format: :turbo_stream
      expect(session[:selected_ids]).to eq(%w[99999])
    end
  end

  describe "GET #toggle" do
    let(:available_projects) do
      [
        { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
        { "id" => "10002", "name" => "Project Beta", "key" => "BETA" }
      ]
    end

    before do
      jira_import.update!(available: { "projects" => available_projects })
    end

    it "responds with turbo stream" do
      get :toggle, params: { jira_id: jira.id, run_id: jira_import.id, project_id: "10001" }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "adds project if not selected" do
      session[:selected_ids] = []
      get :toggle, params: { jira_id: jira.id, run_id: jira_import.id, project_id: "10001" }, format: :turbo_stream
      expect(session[:selected_ids]).to include("10001")
    end

    it "removes project if already selected" do
      session[:selected_ids] = %w[10001 10002]
      get :toggle, params: { jira_id: jira.id, run_id: jira_import.id, project_id: "10001" }, format: :turbo_stream
      expect(session[:selected_ids]).not_to include("10001")
      expect(session[:selected_ids]).to include("10002")
    end
  end

  describe "GET #switch_page" do
    let(:available_projects) do
      [
        { "id" => "10001", "name" => "Project Alpha", "key" => "ALPHA" },
        { "id" => "10002", "name" => "Project Beta", "key" => "BETA" }
      ]
    end

    before do
      jira_import.update!(available: { "projects" => available_projects })
    end

    it "responds with turbo stream" do
      get :switch_page, params: { jira_id: jira.id, run_id: jira_import.id, page: 2 }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "stores page in session" do
      get :switch_page, params: { jira_id: jira.id, run_id: jira_import.id, page: 2 }, format: :turbo_stream
      expect(session[:project_page]).to eq("2")
    end
  end
end
