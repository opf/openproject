# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management run case view", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:tester) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs] }) }
  shared_let(:outsider) { create(:user) }

  let(:current_user) { tester }
  let(:run) { create(:tm_test_run, project:, state: "in_progress") }
  let(:test_case) { create(:tm_test_case, project:, title: "Pay by card") }
  let!(:steps) do
    ["Open the cart", "Enter the card number", "Confirm the payment"].each_with_index.map do |action, index|
      create(:tm_test_step, test_case:, position: index, action:, expected_result: "OK")
    end
  end
  let(:run_case) { create(:tm_test_run_case, test_run: run, test_case:, status: "failed") }
  let(:page_path) { project_test_management_test_run_run_case_path(project, run, run_case) }
  let(:xss) { "<script>alert(1)</script>" }
  let!(:result) do
    create(:tm_test_result, run_case:, status: "failed", source: "automation", comment: "[chromium] boom",
                            error_message: "Expected receipt #{xss}", error_trace: "Error: boom\n    at pay.spec.ts:9")
  end

  before do
    create(:tm_test_step_result, result:, test_step: steps[0], position: 0, status: "passed", step_action: steps[0].action)
    create(:tm_test_step_result, result:, test_step: steps[1], position: 1, status: "failed", step_action: steps[1].action,
                                 error_message: "Card field #{xss}", details: { "substeps" => [{ "title" => "Fill #{xss}", "status" => "passed" }] })
    create(:tm_test_step_result, result:, test_step: steps[2], position: 2, status: "untested", step_action: steps[2].action)
    create(:tm_test_step_result, result:, kind: "reported", position: 3, status: "failed", reported_title: "hooks.rb:9",
                                 details: { "hook" => true })
    login_as(current_user)
  end

  it "shows the error, the failed step, the step results and reported steps, all escaped" do
    get page_path

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include("Failed at step 2")
    expect(body).to include("Expected receipt &lt;script&gt;alert(1)&lt;/script&gt;")
    expect(body).to include("at pay.spec.ts:9")
    expect(body).to include("Not run")
    expect(body).to include("hooks.rb:9")
    expect(body).not_to include(xss)
  end

  it "offers the record form with a status and an actual result per step" do
    get page_path

    expect(response.body).to include(%(name="run_case[step_results][#{steps.first.id}][status]"))
    expect(response.body).to include(%(name="run_case[step_results][#{steps.first.id}][actual_result]"))
    expect(response.body).to include("From the step results")
  end

  it "records a manual result with step results and returns to the view" do
    patch page_path, params: {
      return_to: "run_case",
      run_case: { comment: "Manual retry", step_results: {
        steps[0].id.to_s => { status: "passed", actual_result: "" },
        steps[1].id.to_s => { status: "passed" },
        steps[2].id.to_s => { status: "failed", actual_result: "No receipt <b>shown</b>" }
      } }
    }

    expect(response).to redirect_to(page_path)
    latest = run_case.results.order(:id).last
    expect(run_case.reload.status).to eq("failed")
    expect(latest.step_results.map(&:status)).to eq(%w[passed passed failed])
    expect(latest.step_results.last.actual_result).to eq("No receipt <b>shown</b>")
  end

  it "shows the error line and a details link on the run page" do
    get project_test_management_test_run_path(project, run)

    expect(response.body).to include("Failed at step 2: Expected receipt &lt;script&gt;")
    expect(response.body).to include(page_path)
  end

  context "as viewer" do
    let(:current_user) { viewer }

    it "shows the view without the record form and cannot record" do
      get page_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("run_case[step_results]")

      patch page_path, params: { run_case: { status: "passed" } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "without access" do
    let(:current_user) { outsider }

    it "is not visible" do
      get page_path
      expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
    end
  end
end
