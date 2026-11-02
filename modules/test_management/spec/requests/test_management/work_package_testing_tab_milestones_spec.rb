# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package Testing tab milestones", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:tester) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages view_test_cases view_test_runs show_testing_content]
           })
  end
  shared_let(:no_runs_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages view_test_cases show_testing_content] })
  end
  shared_let(:version) { create(:version, project:, name: "2.0") }

  let(:current_user) { tester }
  let(:work_package) { create(:work_package, project:, subject: "Checkout story") }
  let(:release) { create(:tm_milestone, project:, name: "Release 2.0") }

  before { login_as(current_user) }

  def tab(view = nil)
    get work_package_test_management_tab_path(work_package, view:)
    response.body
  end

  it "shows no milestones segment when the work package is not linked to one" do
    release
    body = tab
    expect(body).to include("tm-wp-testing-view-cases", "tm-wp-testing-view-runs")
    expect(body).not_to include("tm-wp-testing-view-milestones", "Release 2.0")
  end

  it "opens on the milestones view when the work package is linked, with progress" do
    create(:tm_milestone_work_package, milestone: release, work_package:)
    run = create(:tm_test_run, project:, milestone: release)
    create(:tm_test_run_case, test_run: run, status: "passed")

    body = tab
    expect(body).to include('data-view="milestones"', "tm-wp-testing-milestone-#{release.id}", "Release 2.0",
                            "tm-milestone-bar", "tm-milestone-donut")
    expect(body).not_to include("tm-wp-testing-milestone-via-version")
  end

  it "shows milestones tied to the work package's version" do
    release.update!(version:)
    work_package.update_column(:version_id, version.id)

    body = tab("milestones")
    expect(body).to include("tm-wp-testing-milestone-#{release.id}", "tm-wp-testing-milestone-via-version")
  end

  it "falls back to the default view for an unknown view" do
    create(:tm_milestone_work_package, milestone: release, work_package:)
    expect(tab("nope")).to include('data-view="milestones"')
    expect(tab("runs")).to include('data-view="runs"')
  end

  context "without view_test_runs" do
    let(:current_user) { no_runs_user }

    it "hides milestones" do
      create(:tm_milestone_work_package, milestone: release, work_package:)
      expect(tab).not_to include("tm-wp-testing-view-milestones", "Release 2.0")
    end
  end

  it "hides milestones when they are disabled in the project" do
    create(:tm_milestone_work_package, milestone: release, work_package:)
    create(:tm_project_setting, project:).update!(enable_milestones: false)
    expect(tab).not_to include("tm-wp-testing-milestone-#{release.id}")
  end
end
