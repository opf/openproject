# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management runs", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:manager) do
    create(:user,
           firstname: "Run", lastname: "Manager",
           member_with_permissions: {
             project => %i[view_test_cases view_test_runs add_test_runs execute_test_runs view_work_packages]
           })
  end
  shared_let(:viewer) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] })
  end

  let(:current_user) { manager }

  before { login_as(current_user) }

  describe "GET index" do
    let!(:active) { create(:tm_test_run, project:, name: "Active run") }
    let!(:done) { create(:tm_test_run, :completed, project:, name: "Done run") }
    let!(:dropped) { create(:tm_test_run, :cancelled, project:, name: "Dropped run") }

    before do
      create(:tm_test_run_case, test_run: done, status: "passed")
      create(:tm_test_run_case, test_run: done, status: "failed")
    end

    it "shows active runs by default with filter tabs and a New run button" do
      get project_test_management_test_runs_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Active run")
      expect(response.body).not_to include("Done run")
      %w[active completed cancelled all].each { |f| expect(response.body).to include("tm-run-filter-#{f}") }
      expect(response.body).to include("tm-new-run")
    end

    it "filters completed runs and shows progress and pass rate" do
      get project_test_management_test_runs_path(project, filter: "completed")

      expect(response.body).to include("Done run")
      expect(response.body).not_to include("Active run")
      expect(response.body).to include("tm-run-progress")
      expect(response.body).to include("50% passed")
    end

    it "lists every run under All" do
      get project_test_management_test_runs_path(project, filter: "all")
      expect(response.body).to include("Active run", "Done run", "Dropped run")
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "has no New run button" do
        get project_test_management_test_runs_path(project)
        expect(response.body).not_to include("tm-new-run")
      end
    end
  end

  describe "new / create" do
    let(:suite) { create(:tm_suite, project:, name: "Checkout") }
    let!(:test_case) { create(:tm_test_case, project:, suite:, title: "Pay by card") }

    it "renders the form with the three selection options and the selection dialog" do
      get new_project_test_management_test_run_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Either reuse a folder name or specify a new one.")
      %w[all specific dynamic].each { |mode| expect(response.body).to include("test_run_selection_mode_#{mode}") }
      expect(response.body).to include("tm-run-change-selection", "Pay by card", "0 test cases included")
      expect(response.body).not_to match(/\son[a-z]+="/)
    end

    it "re-renders with the applied selection without saving" do
      post project_test_management_test_runs_path(project),
           params: { refresh_selection: "1",
                     test_run: { name: "Draft", selection_mode: "dynamic", selection_submitted: "1",
                                 selection_suite_ids: [suite.id] } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1 test cases included")
      expect(TestManagement::TestRun.count).to eq(0)
    end

    it "creates a run with selected cases and redirects to it" do
      post project_test_management_test_runs_path(project),
           params: { test_run: { name: "Checkout run", selection_mode: "specific", selection_submitted: "1",
                                 assigned_to_id: manager.id, test_case_ids: [test_case.id] } }

      run = TestManagement::TestRun.last
      expect(response).to redirect_to(project_test_management_test_run_path(project, run))
      expect(run.test_cases).to eq([test_case])
      expect(run.run_cases.first.assigned_to).to eq(manager)
    end

    it "re-renders the form on errors" do
      post project_test_management_test_runs_path(project), params: { test_run: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(TestManagement::TestRun.count).to eq(0)
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "is forbidden" do
        post project_test_management_test_runs_path(project), params: { test_run: { name: "x" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET show" do
    let(:root) { create(:tm_suite, project:, name: "Accounts") }
    let(:child) { create(:tm_suite, project:, parent: root, name: "Sign in") }
    let(:run) { create(:tm_test_run, :in_progress, project:, name: "Sprint 12") }
    let!(:run_case) do
      create(:tm_test_run_case, test_run: run, status: "passed",
                                test_case: create(:tm_test_case, project:, suite: child, title: "Valid login"))
    end

    it "shows the summary, collapsible sections and grouped cases with menus" do
      get project_test_management_test_run_path(project, run)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Sprint 12", "R#{run.id}", "tm-run-pie", "Test case status", "100% (1)")
      expect(body).to include("tm-run-statistics", "tm-run-schedule", "This run has no scheduled start/end dates.")
      expect(body).to include("tm-run-group-#{root.id}", "tm-run-group-#{child.id}", "Valid login")
      expect(body).to include('name="run_case[status]"', 'name="run_case[assigned_to_id]"')
      expect(body).to include("tm-run-complete", "tm-run-cancel")
      expect(body).to include(complete_dialog_project_test_management_test_run_path(project, run))
      expect(body).to include(cancel_dialog_project_test_management_test_run_path(project, run))
      expect(body).to include('data-controller="async-dialog"')
      expect(body).not_to include("tm-run-complete-form")
      expect(body).not_to include("tm-run-cancel-form")
    end

    it "opens a complete confirmation dialog" do
      get complete_dialog_project_test_management_test_run_path(project, run),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("Complete this test run?")
      expect(response.body).to include("Sprint 12")
      expect(response.body).to include("Complete run")
    end

    it "opens a cancel confirmation dialog" do
      get cancel_dialog_project_test_management_test_run_path(project, run),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("Cancel this test run?")
      expect(response.body).to include("Sprint 12")
      expect(response.body).to include("Cancel run")
    end

    it "denies the complete dialog without manage or upload permission" do
      login_as(viewer)

      get complete_dialog_project_test_management_test_run_path(project, run),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:forbidden)
    end

    it "is read-only for a finished run" do
      run.update!(state: "completed")
      get project_test_management_test_run_path(project, run)

      expect(response.body).not_to include('name="run_case[status]"')
      expect(response.body).to include("tm-run-frozen", "tm-run-reopen")
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "shows statuses without menus or actions" do
        get project_test_management_test_run_path(project, run)

        expect(response.body).not_to include('name="run_case[status]"')
        expect(response.body).not_to include("tm-run-complete")
      end
    end

    it "lists only linked work packages the user can see and hides the section otherwise" do
      visible_wp = create(:work_package, project:, subject: "Visible story")
      hidden_wp = create(:work_package, project: create(:project), subject: "Secret story")
      run.test_run_work_packages.create!(work_package: hidden_wp)

      get project_test_management_test_run_path(project, run)
      expect(response.body).not_to include("tm-run-references", "Secret story")

      run.test_run_work_packages.create!(work_package: visible_wp)
      get project_test_management_test_run_path(project, run)
      expect(response.body).to include("tm-run-references", "Visible story")
      expect(response.body).not_to include("Secret story")
    end

    it "shows the latest result of each case (and of the shown past iteration)" do
      first = create(:tm_test_run_iteration, test_run: run, number: 1)
      create(:tm_test_result, run_case:, status: "failed", comment: "Old failure", iteration: first)
      create(:tm_test_run_iteration, test_run: run, number: 2)
      create(:tm_test_result, run_case:, status: "passed", comment: "Fixed now")

      get project_test_management_test_run_path(project, run)
      expect(response.body).to include("Fixed now")
      expect(response.body).not_to include("Old failure")

      get project_test_management_test_run_path(project, run, iteration: 1)
      expect(response.body).to include("Old failure")
      expect(response.body).not_to include("Fixed now")
    end

    it "404s for a run of another project" do
      get project_test_management_test_run_path(project, create(:tm_test_run))
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "edit / update" do
    let(:run) { create(:tm_test_run, project:, name: "Old") }

    it "renders the edit form" do
      get edit_project_test_management_test_run_path(project, run)
      expect(response.body).to include('value="Old"')
    end

    it "updates the run" do
      patch project_test_management_test_run_path(project, run), params: { test_run: { name: "New" } }

      expect(response).to redirect_to(project_test_management_test_run_path(project, run))
      expect(run.reload.name).to eq("New")
    end
  end

  describe "transitions" do
    let(:run) { create(:tm_test_run, :in_progress, project:) }
    let!(:run_case) { create(:tm_test_run_case, test_run: run, status: "failed") }

    it "completes, then reopens" do
      post complete_project_test_management_test_run_path(project, run)
      expect(response).to redirect_to(project_test_management_test_run_path(project, run))
      expect(run.reload.state).to eq("completed")
      expect(run_case.reload.final_status).to eq("failed")

      post reopen_project_test_management_test_run_path(project, run)
      expect(run.reload.state).to eq("in_progress")
    end

    it "cancels" do
      post cancel_project_test_management_test_run_path(project, run)
      expect(run.reload.state).to eq("cancelled")
    end

    context "as viewer" do
      let(:current_user) { viewer }

      it "cannot complete" do
        post complete_project_test_management_test_run_path(project, run)
        expect(response).to have_http_status(:forbidden)
        expect(run.reload.state).to eq("in_progress")
      end
    end
  end

  describe "DELETE destroy" do
    let!(:run) { create(:tm_test_run, project:, name: "Disposable") }
    let(:deleter) do
      create(:user, member_with_permissions: {
               project => %i[view_test_cases view_test_runs delete_test_runs]
             })
    end

    it "deletes the run when permitted" do
      login_as(deleter)
      delete project_test_management_test_run_path(project, run)

      expect(response).to redirect_to(project_test_management_test_runs_path(project))
      expect(TestManagement::TestRun.find_by(id: run.id)).to be_nil
    end

    it "forbids viewers" do
      login_as(viewer)
      delete project_test_management_test_run_path(project, run)

      expect(response).to have_http_status(:forbidden)
      expect(TestManagement::TestRun.find_by(id: run.id)).to be_present
    end
  end
end
