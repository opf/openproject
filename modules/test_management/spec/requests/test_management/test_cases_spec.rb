# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management cases", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases delete_test_cases manage_test_suites]
           })
  end

  before do
    login_as(user)
  end

  it "renders cases index with split pane layout by default" do
    create(:tm_test_case, project:, title: "Login happy path")

    get project_test_management_test_cases_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-folder-tree-layout="split_pane"')
    expect(response.body).to include("tm-folder-pane-split")
    expect(response.body).to include("Login happy path")
  end

  it "hides split pane tree when layout is sidebar" do
    create(:tm_project_setting, project:, folder_tree_layout: "sidebar")
    create(:tm_test_case, project:)

    get project_test_management_test_cases_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-folder-tree-layout="sidebar"')
    expect(response.body).not_to include("tm-folder-pane-split")
  end

  it "creates a test case with rich-text preconditions" do
    post project_test_management_test_cases_path(project),
         params: {
           test_case: {
             title: "Macro case",
             preconditions: "See ###1 for context",
             priority: "high",
             status: "ready",
             steps_attributes: {
               "0" => { position: 0, action: "Open page", expected_result: "Visible" }
             }
           }
         }

    expect(response).to redirect_to(project_test_management_test_case_path(project, TestManagement::TestCase.last))
    created = TestManagement::TestCase.order(:id).last
    expect(created.title).to eq("Macro case")
    expect(created.preconditions).to include("###1")
    expect(created.steps.count).to eq(1)
  end

  it "creates a test case without steps and drops blank step rows" do
    post project_test_management_test_cases_path(project),
         params: {
           test_case: {
             title: "No steps",
             priority: "low",
             status: "draft",
             steps_attributes: { "0" => { position: 0, action: "", expected_result: "" } }
           }
         }

    created = TestManagement::TestCase.find_by(title: "No steps")
    expect(created).to be_present
    expect(created.steps).to be_empty
  end

  it "updates a test case and adds a step" do
    test_case = create(:tm_test_case, project:, title: "Before")

    patch project_test_management_test_case_path(project, test_case),
          params: {
            test_case: {
              title: "After",
              steps_attributes: { "0" => { position: 0, action: "Click", expected_result: "Done" } }
            }
          }

    expect(response).to redirect_to(project_test_management_test_case_path(project, test_case))
    expect(test_case.reload.title).to eq("After")
    expect(test_case.steps.count).to eq(1)
  end

  it "renders new and edit forms with nested step field names" do
    get new_project_test_management_test_case_path(project)
    expect(response.body).to include("test_case[steps_attributes][0][action]")

    test_case = create(:tm_test_case, project:)
    get edit_project_test_management_test_case_path(project, test_case)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("test_case[steps_attributes][0][action]")
  end

  it "denies viewers from creating cases" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })
    login_as(viewer)

    post project_test_management_test_cases_path(project),
         params: { test_case: { title: "Nope", priority: "low", status: "ready" } }

    expect(response).to have_http_status(:forbidden).or have_http_status(:unprocessable_entity).or have_http_status(:redirect)
    expect(TestManagement::TestCase.where(title: "Nope")).to be_empty
  end

  it "wires the show delete button to the soft-delete confirmation dialog" do
    test_case = create(:tm_test_case, project:)

    get project_test_management_test_case_path(project, test_case)

    expect(response.body).to include(delete_dialog_project_test_management_test_case_path(project, test_case))
    expect(response.body).to include('data-controller="async-dialog"')
    expect(response.body).to include("tm-case-delete-button")
    expect(response.body).not_to include("data-turbo-confirm")
  end
end

RSpec.describe "Test management cases – linked work packages", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:hidden_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
  shared_let(:wp_one) { create(:work_package, project:, subject: "Login page") }
  shared_let(:wp_two) { create(:work_package, project:, subject: "Logout button") }
  shared_let(:invisible_wp) { create(:work_package, project: hidden_project, subject: "Secret") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases view_work_packages]
           })
  end

  before do
    login_as(user)
  end

  it "creates a case linked to several work packages" do
    post project_test_management_test_cases_path(project),
         params: {
           test_case: {
             title: "Linked case",
             priority: "medium",
             status: "ready",
             work_package_ids: ["", wp_one.id.to_s, wp_two.id.to_s]
           }
         }

    created = TestManagement::TestCase.find_by!(title: "Linked case")
    expect(response).to redirect_to(project_test_management_test_case_path(project, created))
    expect(created.work_packages).to contain_exactly(wp_one, wp_two)
  end

  it "rejects linking a work package the user cannot see and writes nothing" do
    post project_test_management_test_cases_path(project),
         params: {
           test_case: {
             title: "Sneaky",
             priority: "medium",
             status: "ready",
             work_package_ids: [wp_one.id.to_s, invisible_wp.id.to_s]
           }
         }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(TestManagement::TestCase.where(title: "Sneaky")).to be_empty
    expect(TestManagement::TestCaseWorkPackage.where(work_package: invisible_wp)).to be_empty
  end

  it "replaces and clears links on update" do
    test_case = create(:tm_test_case, project:)
    test_case.work_packages << wp_one

    patch project_test_management_test_case_path(project, test_case),
          params: { test_case: { work_package_ids: ["", wp_two.id.to_s] } }
    expect(test_case.reload.work_packages).to contain_exactly(wp_two)

    patch project_test_management_test_case_path(project, test_case),
          params: { test_case: { work_package_ids: [""] } }
    expect(test_case.reload.work_packages).to be_empty
  end

  it "keeps links when the field is not submitted" do
    test_case = create(:tm_test_case, project:)
    test_case.work_packages << wp_one

    patch project_test_management_test_case_path(project, test_case),
          params: { test_case: { title: "Renamed" } }

    expect(test_case.reload.work_packages).to contain_exactly(wp_one)
  end

  it "does not persist links from an invalid update" do
    test_case = create(:tm_test_case, project:)

    patch project_test_management_test_case_path(project, test_case),
          params: { test_case: { work_package_ids: [wp_one.id.to_s, invisible_wp.id.to_s] } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(test_case.reload.work_packages).to be_empty
  end

  it "shows linked work packages opening in a new tab" do
    test_case = create(:tm_test_case, project:)
    test_case.work_packages << wp_one

    get project_test_management_test_case_path(project, test_case)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Login page")
    expect(response.body).to include(%(href="#{work_package_path(wp_one)}"))
    expect(response.body).to include('target="_blank"')
    expect(response.body).to include('rel="noopener noreferrer"')
  end

  it "shows a placeholder when nothing is linked" do
    test_case = create(:tm_test_case, project:)

    get project_test_management_test_case_path(project, test_case)

    expect(response.body).to include("No linked work packages.")
  end

  it "renders the work package autocompleter on the form" do
    get new_project_test_management_test_case_path(project)

    expect(response.body).to include("opce-autocompleter")
    expect(response.body).to include("test_case[work_package_ids][]")
    expect(response.body).to include("test_case[steps_attributes][0][data]")
  end
end

RSpec.describe "Test management cases – folders, meta, tabs and history", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management work_package_tracking]) }
  shared_let(:bug_type) { create(:type, name: "Bug") }
  shared_let(:task_type) { create(:type, name: "Task") }
  shared_let(:user) do
    create(:user,
           firstname: "Casey", lastname: "Writer",
           member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases manage_test_suites view_work_packages]
           })
  end

  before do
    ProjectType.find_or_create_by!(project:, type: bug_type)
    ProjectType.find_or_create_by!(project:, type: task_type)
    login_as(user)
  end

  it "lists cases of subfolders when a parent folder is selected and counts descendants" do
    parent = create(:tm_suite, project:, name: "Parent")
    child = create(:tm_suite, project:, name: "Child", parent:)
    create(:tm_test_case, project:, suite: parent, title: "Direct case")
    create(:tm_test_case, project:, suite: child, title: "Nested case")
    create(:tm_test_case, project:, title: "Unfiled case")

    get project_test_management_test_cases_path(project, suite_id: parent.id)

    expect(response.body).to include("Direct case", "Nested case")
    expect(response.body).not_to include("Unfiled case")
    expect(response.body).to match(/data-test-selector="tm-folder-#{parent.id}".*?Counter[^>]*>\s*2\s*</m)
  end

  it "does not show an Assignee column or field" do
    create(:tm_test_case, project:)

    get project_test_management_test_cases_path(project)
    expect(response.body).not_to include("Assignee")

    get new_project_test_management_test_case_path(project)
    expect(response.body).not_to include("assigned_to_id")
  end

  it "records the author on create and the last editor on update" do
    post project_test_management_test_cases_path(project), params: { test_case: { title: "Meta case", status: "draft" } }
    test_case = TestManagement::TestCase.find_by(title: "Meta case")
    expect(test_case.author).to eq(user)
    expect(test_case.updated_by).to be_nil

    editor = create(:user, member_with_permissions: { project => %i[view_test_cases edit_test_cases] })
    login_as(editor)
    patch project_test_management_test_case_path(project, test_case), params: { test_case: { status: "ready" } }

    expect(test_case.reload.updated_by).to eq(editor)
    expect(test_case.events.map(&:action)).to eq(%w[created updated])
    expect(test_case.events.last.user).to eq(editor)
    expect(test_case.events.last.details).to include("status" => %w[draft ready])
  end

  it "shows created by and last edited by with dates on the overview tab" do
    test_case = create(:tm_test_case, project:, author: user)
    test_case.update_columns(updated_by_id: user.id)

    get project_test_management_test_case_path(project, test_case)

    expect(response.body).to include('data-test-selector="tm-case-created-by"', 'data-test-selector="tm-case-updated-by"')
    expect(response.body).to include("Casey Writer")
    expect(response.body).not_to include(">Assignee<")
  end

  it "shows a dash when the last editor is unknown" do
    test_case = create(:tm_test_case, project:, author: user)

    get project_test_management_test_case_path(project, test_case)

    expect(response.body).to match(/tm-case-updated-by">\s*<span[^>]*>—/)
  end

  it "renders the tab bar above the title with one URL per tab" do
    test_case = create(:tm_test_case, project:)

    get project_test_management_test_case_path(project, test_case)

    body = response.body
    %w[overview runs defects history].each do |tab|
      expect(body).to include(%(data-test-selector="tm-case-tab-#{tab}"))
    end
    expect(body).to include("tab=runs", "tab=defects", "tab=history")
    # The title also appears in <title>; compare against the page header instead.
    expect(body.index("tm-case-tabs")).to be < body.index(/PageHeader-title[" ]/)
    expect(body).to include('data-test-selector="tm-case-tab-panel-overview"')
  end

  it "shows a blankslate on the runs tab" do
    test_case = create(:tm_test_case, project:)

    get project_test_management_test_case_path(project, test_case, tab: "runs")

    expect(response.body).to include("No runs include this case yet.")
  end

  it "lists linked bugs on the defects tab" do
    bug = create(:work_package, project:, type: bug_type, subject: "Crash on save")
    task = create(:work_package, project:, type: task_type, subject: "Write docs")
    test_case = create(:tm_test_case, project:)
    test_case.work_packages << [bug, task]

    get project_test_management_test_case_path(project, test_case, tab: "defects")

    expect(response.body).to include("Crash on save")
    expect(response.body).not_to include("Write docs")
  end

  it "shows a blankslate when no defects are linked" do
    test_case = create(:tm_test_case, project:)

    get project_test_management_test_case_path(project, test_case, tab: "defects")

    expect(response.body).to include("No defects linked.")
  end

  it "shows the change history" do
    test_case = create(:tm_test_case, project:, author: user, status: "draft")
    test_case.update!(status: "ready", updated_by: user)

    get project_test_management_test_case_path(project, test_case, tab: "history")

    expect(response.body).to include('data-test-selector="tm-history-created"', 'data-test-selector="tm-history-updated"')
    expect(response.body).to include("Status changed from draft to ready")
  end

  it "falls back to the overview for an unknown tab" do
    test_case = create(:tm_test_case, project:)

    get project_test_management_test_case_path(project, test_case, tab: "nope")

    expect(response.body).to include('data-test-selector="tm-case-tab-panel-overview"')
  end
end
