# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management menu, placeholders and admin settings", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs manage_test_ci] })
  end
  shared_let(:admin) { create(:admin) }

  let(:current_user) { user }

  before { login_as(current_user) }

  it "renders the submenu with the folder tree (sidebar layout, Cases)" do
    create(:tm_project_setting, project:, folder_tree_layout: "sidebar")
    create(:tm_suite, project:, name: "Accounts")
    get project_test_management_menu_path(project, section: "cases")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Accounts")
  end

  it "renders the CI placeholder page" do
    get project_test_management_placeholder_path(project, page: "ci")
    expect(response).to have_http_status(:ok)
  end

  it "404s for dropped and unknown placeholders" do
    get project_test_management_placeholder_path(project, page: "nope")
    expect(response).to have_http_status(:not_found)

    get project_test_management_placeholder_path(project, page: "reports")
    expect(response).to have_http_status(:not_found)

    get project_test_management_placeholder_path(project, page: "requirements")
    expect(response).to have_http_status(:not_found)

    get project_test_management_placeholder_path(project, page: "runs")
    expect(response).to have_http_status(:not_found)
  end

  it "redirects the dropped Executions placeholder to the Runs list" do
    get "/projects/#{project.identifier}/test_management/placeholders/executions"

    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to(project_test_management_test_runs_path(project.identifier))
  end

  it "has no Executions menu entry" do
    get project_test_management_test_runs_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("placeholders/executions")
    expect(response.body).not_to match(/>\s*Executions\s*</)
  end

  describe "admin settings" do
    it "is admin only" do
      get test_management_admin_settings_path
      expect(response).to have_http_status(:forbidden)
    end

    context "as admin" do
      let(:current_user) { admin }

      it "shows and updates the default prefix" do
        get test_management_admin_settings_path
        expect(response).to have_http_status(:ok)

        patch test_management_admin_settings_path, params: { default_display_prefix: "QA" }
        expect(response).to redirect_to(test_management_admin_settings_path)
        expect(Setting.plugin_openproject_test_management["default_display_prefix"]).to eq("QA")
      end
    end
  end
end
