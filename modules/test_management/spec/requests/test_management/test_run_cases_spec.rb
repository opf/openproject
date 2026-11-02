# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management run cases", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:tester) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs execute_test_runs] })
  end
  shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_runs] }) }

  let(:current_user) { tester }
  let(:run) { create(:tm_test_run, project:) }
  let(:run_case) { create(:tm_test_run_case, test_run: run) }

  before { login_as(current_user) }

  def patch_case(params)
    patch project_test_management_test_run_run_case_path(project, run, run_case), params: { run_case: params }
  end

  it "sets the status, records a result and redirects to the row" do
    patch_case(status: "blocked")

    expect(response).to redirect_to(project_test_management_test_run_path(project, run, anchor: "run-case-#{run_case.id}"))
    expect(run_case.reload.status).to eq("blocked")
    expect(run_case.results.count).to eq(1)
    expect(run.reload.state).to eq("in_progress")
  end

  it "sets the assignee" do
    patch_case(assigned_to_id: tester.id)
    expect(run_case.reload.assigned_to).to eq(tester)
  end

  it "flashes an error for a finished run" do
    run.update!(state: "cancelled")
    patch_case(status: "passed")

    expect(flash[:error]).to be_present
    expect(run_case.reload.status).to eq("untested")
  end

  context "as viewer" do
    let(:current_user) { viewer }

    it "is forbidden" do
      patch_case(status: "passed")
      expect(response).to have_http_status(:forbidden)
    end
  end
end
