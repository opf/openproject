# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package Testing tab", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:tester) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages view_test_cases view_test_runs show_testing_content
                           link_test_cases_to_work_packages]
           })
  end
  shared_let(:no_tab_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_test_cases] })
  end
  shared_let(:no_runs_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_test_cases show_testing_content] })
  end

  let(:work_package) { create(:work_package, project:, subject: "Checkout story") }
  let(:suite) { create(:tm_suite, project:, name: "Payments") }
  let!(:linked_case) { create(:tm_test_case, project:, suite:, title: "Pay by card") }
  let!(:unlinked_case) { create(:tm_test_case, project:, title: "Unrelated case") }
  let(:current_user) { tester }

  before do
    create(:tm_test_case_work_package, test_case: linked_case, work_package:)
    login_as(current_user)
  end

  describe "GET /work_packages/:id/test_management/tab" do
    it "renders the linked cases inside the tab's turbo frame" do
      get work_package_test_management_tab_path(work_package)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="work-package-testing-tab-content"')
      expect(response.body).to include("tm-wp-testing-case-#{linked_case.id}", "Pay by card", "Payments")
      expect(response.body).not_to include("Unrelated case")
      expect(response.body).to include(project_test_management_test_case_path(project, linked_case))
      expect(response.body).to include("Not run yet")
    end

    it "shows the latest run result of each case" do
      older = create(:tm_test_run, :completed, project:, name: "Sprint 1")
      newer = create(:tm_test_run, :in_progress, project:, name: "Sprint 2")
      create(:tm_test_run_case, test_run: older, test_case: linked_case, status: "passed")
      create(:tm_test_run_case, test_run: newer, test_case: linked_case, status: "failed")

      get work_package_test_management_tab_path(work_package)

      expect(response.body).to include("Sprint 2")
      expect(response.body).not_to include("Sprint 1")
    end

    it "hides deleted cases and shows the empty state" do
      linked_case.soft_delete!

      get work_package_test_management_tab_path(work_package)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("tm-wp-testing-empty")
      expect(response.body).not_to include("Pay by card")
    end

    it "hides linked cases of projects where the user cannot view test cases" do
      foreign = create(:tm_test_case, project: other_project, title: "Foreign case")
      create(:tm_test_case_work_package, test_case: foreign, work_package:)

      get work_package_test_management_tab_path(work_package)

      expect(response.body).to include("Pay by card")
      expect(response.body).not_to include("Foreign case")
    end

    context "without view_test_runs" do
      let(:current_user) { no_runs_user }

      it "lists the cases but not their run results" do
        run = create(:tm_test_run, :in_progress, project:, name: "Hidden run")
        create(:tm_test_run_case, test_run: run, test_case: linked_case, status: "failed")

        get work_package_test_management_tab_path(work_package)

        expect(response.body).to include("Pay by card")
        expect(response.body).not_to include("Hidden run")
      end
    end

    context "without show_testing_content" do
      let(:current_user) { no_tab_user }

      it "is not found" do
        get work_package_test_management_tab_path(work_package)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with the module disabled" do
      before { project.enabled_module_names = project.enabled_module_names - %w[test_management] }

      after { project.enabled_module_names = project.enabled_module_names + %w[test_management] }

      it "is not found" do
        get work_package_test_management_tab_path(work_package)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "for a work package the user cannot see" do
      it "is not found" do
        hidden = create(:work_package, project: other_project)
        get work_package_test_management_tab_path(hidden)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /work_packages/:id/test_management/tab/count" do
    it "returns the number of visible linked cases" do
      get work_package_test_management_tab_count_path(work_package)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("count" => 1)
    end

    context "without show_testing_content" do
      let(:current_user) { no_tab_user }

      it "is not found" do
        get work_package_test_management_tab_count_path(work_package)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
