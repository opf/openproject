# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Create test case", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases add_test_cases]
           })
  end

  current_user { user }

  it "creates a case from the quick-create bar and persists the title" do
    visit project_test_management_test_cases_path(project)

    fill_in "tm-new-case-title", with: "Feature create case"
    find("[data-test-selector='tm-new-test-case']").click

    expect(page).to have_current_path(/test_cases\/\d+/, wait: 10)
    expect(TestManagement::TestCase.find_by(title: "Feature create case")).to be_present
  end
end
