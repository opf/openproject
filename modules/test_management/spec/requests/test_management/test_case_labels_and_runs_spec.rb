# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test case labels and runs tab", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases view_test_runs]
           })
  end

  before { login_as(user) }

  it "saves labels from the form and shows them in the grid and on the overview" do
    post project_test_management_test_cases_path(project),
         params: { test_case: { title: "Labeled", priority: "medium", status: "ready", label_names: "smoke, api" } }

    test_case = TestManagement::TestCase.find_by!(title: "Labeled")
    expect(test_case.labels.map(&:name)).to contain_exactly("smoke", "api")

    get project_test_management_test_cases_path(project)
    expect(response.body).to include("tm-case-labels-#{test_case.id}", "smoke", "api")

    get project_test_management_test_case_path(project, test_case)
    expect(response.body).to include("tm-case-labels")
  end

  it "offers existing labels on the form" do
    create(:tm_label, project:, name: "regression")
    get new_project_test_management_test_case_path(project)

    expect(response.body).to include("tm-label-suggestions", 'value="regression"')
  end

  it "lists runs containing the case with state and final status" do
    test_case = create(:tm_test_case, project:)
    run = create(:tm_test_run, :completed, project:, name: "Release 3")
    create(:tm_test_run_case, test_run: run, test_case:, status: "passed", final_status: "passed")

    get project_test_management_test_case_path(project, test_case, tab: "runs")

    expect(response.body).to include("tm-case-runs", "Release 3", "Completed", "Passed")
    expect(response.body).to include(project_test_management_test_run_path(project, run))
  end

  it "shows run results in the case history" do
    test_case = create(:tm_test_case, project:)
    run = create(:tm_test_run, :in_progress, project:, name: "Smoke")
    create(:tm_test_run_case, test_run: run, test_case:, status: "failed")
    TestManagement::TestRuns::CompleteService.new(user: create(:admin), model: run).call

    get project_test_management_test_case_path(project, test_case, tab: "history")
    expect(response.body).to include("Run R#{run.id}", "completed: Failed")
  end
end
