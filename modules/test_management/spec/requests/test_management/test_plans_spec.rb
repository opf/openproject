# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management plans", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:manager) do
    create(:user,
           firstname: "Plan", lastname: "Manager",
           member_with_permissions: {
             project => %i[view_test_cases view_test_plans manage_test_plans view_work_packages]
           })
  end

  let(:current_user) { manager }

  before { login_as(current_user) }

  describe "new / create" do
    it "creates a plan and renders show after redirect" do
      post project_test_management_test_plans_path(project),
           params: { test_plan: { name: "Release campaign" } }

      plan = TestManagement::TestPlan.last
      expect(plan).to be_present
      expect(response).to redirect_to(project_test_management_test_plan_path(project, plan))
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Release campaign", "tm-plan-entry-form", "No entries yet")
    end

    it "re-renders the form on errors" do
      post project_test_management_test_plans_path(project), params: { test_plan: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(TestManagement::TestPlan.count).to eq(0)
    end
  end

  describe "GET show" do
    let!(:plan) { create(:tm_test_plan, project:, name: "Sprint plan") }

    it "shows the plan header and empty entries state when manageable" do
      get project_test_management_test_plan_path(project, plan)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sprint plan", "tm-plan-entry-form", "No entries yet")
    end
  end
end
