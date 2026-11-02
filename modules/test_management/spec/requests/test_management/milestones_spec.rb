# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management milestones", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:manager) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs manage_test_milestones view_work_packages]
           })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:cases_only) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

  let(:current_user) { manager }
  let(:base) { "/projects/#{project.identifier}/test_management/milestones" }

  before { login_as(current_user) }

  describe "GET index" do
    let!(:release) { create(:tm_milestone, project:, name: "Release 2.0", due_date: Date.current + 10) }
    let!(:sprint) { create(:tm_milestone, project:, parent: release, name: "Sprint 14") }
    let!(:done) { create(:tm_milestone, :completed, project:, name: "Release 1.9") }

    before do
      run = create(:tm_test_run, project:, milestone: sprint)
      create(:tm_test_run_case, test_run: run, status: "passed")
      create(:tm_test_run_case, test_run: run, status: "failed")
    end

    it "lists open milestones with sub-milestones and progress" do
      get base

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("tm-milestone-row-#{release.id}", "tm-milestone-row-#{sprint.id}", "tm-new-milestone")
      expect(response.body).not_to include("Release 1.9")
      expect(response.body).to include("tm-milestone-bar")
    end

    it "filters completed milestones" do
      get base, params: { filter: "completed" }
      expect(response.body).to include("Release 1.9")
      expect(response.body).not_to include("tm-milestone-row-#{release.id}")
    end

    context "as a viewer" do
      let(:current_user) { viewer }

      it "shows the list without the New button" do
        get base
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("tm-new-milestone")
      end
    end

    context "without view_test_runs" do
      let(:current_user) { cases_only }

      it "is forbidden" do
        get base
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "is not found when milestones are disabled" do
      create(:tm_project_setting, project:).update!(enable_milestones: false)
      get base
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET show" do
    it "shows progress, sub-milestones and the runs of both" do
      release = create(:tm_milestone, project:, name: "Release 2.0")
      sprint = create(:tm_milestone, project:, parent: release, name: "Sprint 14")
      own = create(:tm_test_run, project:, milestone: release, name: "Regression")
      child_run = create(:tm_test_run, project:, milestone: sprint, name: "Smoke")

      get "#{base}/#{release.id}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("tm-milestone-summary", "tm-milestone-child-#{sprint.id}",
                                       "tm-milestone-run-#{own.id}", "tm-milestone-run-#{child_run.id}",
                                       "tm-milestone-start", "tm-milestone-complete")
    end
  end

  describe "POST create / PATCH update" do
    it "creates a milestone and redirects to it" do
      version = create(:version, project:)
      post base, params: { milestone: { name: "Release 2.0", due_date: "2026-12-01", version_id: version.id } }

      milestone = TestManagement::Milestone.sole
      expect(response).to redirect_to("#{base}/#{milestone.id}")
      expect(milestone).to have_attributes(name: "Release 2.0", version:, created_by: manager)
    end

    it "re-renders the form on errors" do
      post base, params: { milestone: { name: "", start_date: "2026-12-10", due_date: "2026-12-01" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("tm-milestone-form")
    end

    it "updates a milestone" do
      milestone = create(:tm_milestone, project:)
      patch "#{base}/#{milestone.id}", params: { milestone: { name: "Release 2.1" } }
      expect(milestone.reload.name).to eq("Release 2.1")
    end

    context "as a viewer" do
      let(:current_user) { viewer }

      it "is forbidden" do
        post base, params: { milestone: { name: "Release 2.0" } }
        expect(response).to have_http_status(:forbidden)
        expect(TestManagement::Milestone.count).to eq(0)
      end
    end
  end

  describe "transitions and delete" do
    let!(:milestone) { create(:tm_milestone, project:) }

    it "starts, completes and reopens" do
      post "#{base}/#{milestone.id}/start"
      expect(milestone.reload.status).to eq("started")
      post "#{base}/#{milestone.id}/complete"
      expect(milestone.reload.status).to eq("completed")
      post "#{base}/#{milestone.id}/reopen"
      expect(milestone.reload.status).to eq("started")
    end

    it "flashes an error for an impossible transition" do
      post "#{base}/#{milestone.id}/reopen"
      expect(flash[:error]).to include("not possible")
    end

    it "deletes and keeps the runs" do
      run = create(:tm_test_run, project:, milestone:)
      delete "#{base}/#{milestone.id}"
      expect(response).to redirect_to(base)
      expect(run.reload.milestone_id).to be_nil
    end
  end

  describe "run form" do
    it "assigns a run to a milestone and shows it on the run page" do
      milestone = create(:tm_milestone, project:, name: "Release 2.0")
      run = create(:tm_test_run, project:)

      get "/projects/#{project.identifier}/test_management/test_runs/#{run.id}/edit"
      expect(response.body).to include("tm-run-milestone-field", "Release 2.0")

      patch "/projects/#{project.identifier}/test_management/test_runs/#{run.id}",
            params: { test_run: { milestone_id: milestone.id } }
      expect(run.reload.milestone).to eq(milestone)

      get "/projects/#{project.identifier}/test_management/test_runs/#{run.id}"
      expect(response.body).to include("tm-run-milestone")
    end
  end

  describe "export" do
    it "downloads csv, xls and pdf" do
      milestone = create(:tm_milestone, project:)
      %w[csv xls pdf].each do |format|
        get "/projects/#{project.identifier}/test_management/exports/milestones/#{milestone.id}",
            params: { export_format: format }
        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Disposition"]).to include("attachment", ".#{format}")
      end
    end
  end
end
