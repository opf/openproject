# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Update run case status", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs execute_test_runs]
           })
  end
  shared_let(:run) { create(:tm_test_run, project:) }
  shared_let(:run_case) { create(:tm_test_run_case, test_run: run, status: "untested") }

  current_user { user }

  it "sets a status from the run show page" do
    visit project_test_management_test_run_path(project, run)

    expect(page).to have_css("[data-test-selector='tm-run-case-#{run_case.id}']")

    within("[data-test-selector='tm-run-case-status-#{run_case.id}']") do
      click_button
    end
    find("[role='menuitem']", text: /passed/i).click

    expect(page).to have_css("[data-test-selector='tm-run-case-#{run_case.id}']", wait: 10)
    expect(run_case.reload.status).to eq("passed")
  end
end
