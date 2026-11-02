# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management exports", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:viewer) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] })
  end
  shared_let(:cases_only) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }
  shared_let(:outsider) { create(:user) }

  shared_let(:folder) { create(:tm_suite, project:, name: "Accounts") }
  shared_let(:filed) { create(:tm_test_case, project:, suite: folder, title: "Filed case", priority: "high") }
  shared_let(:loose) { create(:tm_test_case, project:, title: "Loose case", priority: "low") }
  shared_let(:run) { create(:tm_test_run, project:, name: "Nightly") }

  let(:current_user) { viewer }

  before { login_as(current_user) }

  describe "test cases" do
    %w[pdf csv xls].each do |format|
      it "downloads #{format}" do
        get project_test_management_export_test_cases_path(project, export_format: format)

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("attachment", ".#{format}")
        expect(response.media_type).to eq(TestManagement::Exports::BaseExporter::MIME_TYPES[format])
      end
    end

    it "exports a folder" do
      get project_test_management_export_test_cases_path(project, export_format: "csv", scope: "folder",
                                                                  suite_id: folder.id)
      expect(response.body).to include("Filed case")
      expect(response.body).not_to include("Loose case")
    end

    it "exports the current filter" do
      get project_test_management_export_test_cases_path(project, export_format: "csv", scope: "filter", priority: "low")
      expect(response.body).to include("Loose case")
      expect(response.body).not_to include("Filed case")
    end

    it "defaults to the current view when no scope is given" do
      get project_test_management_export_test_cases_path(project, export_format: "csv", suite_id: folder.id)
      expect(response.body).not_to include("Loose case")
    end

    it "rejects unknown formats" do
      get project_test_management_export_test_cases_path(project, export_format: "docx")
      expect(response).to have_http_status(:bad_request)
    end

    context "without access to the project" do
      let(:current_user) { outsider }

      it "is forbidden or hidden" do
        get project_test_management_export_test_cases_path(project, export_format: "csv")
        expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
      end
    end
  end

  describe "test run" do
    %w[pdf csv xls].each do |format|
      it "downloads #{format}" do
        get project_test_management_export_test_run_path(project, run, export_format: format)

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("attachment", "Nightly", ".#{format}")
      end
    end

    it "404s for a run of another project" do
      get project_test_management_export_test_run_path(project, create(:tm_test_run), export_format: "csv")
      expect(response).to have_http_status(:not_found)
    end

    context "without view_test_runs" do
      let(:current_user) { cases_only }

      it "is forbidden" do
        get project_test_management_export_test_run_path(project, run, export_format: "csv")
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "menus" do
    it "shows the export menu on the cases list with the folder and project scopes" do
      get project_test_management_test_cases_path(project, suite_id: folder.id)

      expect(response.body).to include("tm-cases-export-menu", "tm-export-folder-csv", "tm-export-project-pdf")
      expect(response.body).not_to include("tm-export-filter-csv")
    end

    it "adds the current-filter scope when filters are active" do
      get project_test_management_test_cases_path(project, priority: "low")
      expect(response.body).to include("tm-export-filter-xls")
    end

    it "shows the export menu on the run page" do
      get project_test_management_test_run_path(project, run)

      expect(response.body).to include("tm-run-export-menu", "tm-run-export-pdf",
                                       project_test_management_export_test_run_path(project, run, export_format: "csv"))
    end
  end
end
