# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management cases bulk actions and recycle bin", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases delete_test_cases manage_test_suites]
           })
  end
  shared_let(:suite) { create(:tm_suite, project:, name: "Alpha") }
  shared_let(:other_suite) { create(:tm_suite, project:, name: "Beta") }

  before { login_as(user) }

  it "shows the Deleted category and Select cases control on the list" do
    create(:tm_test_case, project:, suite:)

    get project_test_management_test_cases_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("tm-folder-deleted")
    expect(response.body).to include("tm-select-cases")
  end

  it "bulk-updates only submitted fields" do
    first = create(:tm_test_case, project:, suite:, title: "One", priority: "low", status: "draft")
    second = create(:tm_test_case, project:, suite:, title: "Two", priority: "low", status: "ready")

    put project_test_management_test_cases_bulk_path(project),
        params: {
          ids: [first.id, second.id],
          test_case: { priority: "critical", status: "", title: "" }
        }

    expect(response).to redirect_to(project_test_management_test_cases_path(project))
    expect(first.reload.priority).to eq("critical")
    expect(first.title).to eq("One")
    expect(first.status).to eq("draft")
    expect(second.reload.priority).to eq("critical")
    expect(second.status).to eq("ready")
  end

  it "moves and copies selected cases" do
    first = create(:tm_test_case, :with_steps, project:, suite:, title: "Move me",
                                               automation_reference: "tests/x.spec.ts#x")
    second = create(:tm_test_case, project:, suite:, title: "Copy me",
                                   automation_reference: "tests/y.spec.ts#y")

    post move_project_test_management_test_cases_bulk_path(project),
         params: { ids: [first.id], suite_id: other_suite.id }
    expect(first.reload.suite_id).to eq(other_suite.id)

    expect do
      post copy_project_test_management_test_cases_bulk_path(project),
           params: { ids: [second.id], suite_id: other_suite.id }
    end.to change(TestManagement::TestCase.not_deleted, :count).by(1)

    copy = TestManagement::TestCase.not_deleted.order(:id).last
    expect(copy.title).to eq("Copy me")
    expect(copy.suite_id).to eq(other_suite.id)
    expect(copy.automation_reference).to be_nil
    expect(second.reload.automation_reference).to eq("tests/y.spec.ts#y")
  end

  it "opens a soft-delete confirmation dialog for a single case" do
    test_case = create(:tm_test_case, project:, suite:, title: "Soft")

    get delete_dialog_project_test_management_test_case_path(project, test_case),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include("Move this test case to Deleted?")
    expect(response.body).to include("Soft")
    expect(response.body).to include("Move to Deleted")
  end

  it "opens a soft-delete confirmation dialog for a bulk selection" do
    first = create(:tm_test_case, project:, suite:, title: "Bulk one")
    second = create(:tm_test_case, project:, suite:, title: "Bulk two")

    get delete_dialog_project_test_management_test_cases_bulk_path(project),
        params: { ids: [first.id, second.id] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream])
    expect(response.body).to include("Move these 2 test cases to Deleted?")
    expect(response.body).to include("Bulk one")
    expect(response.body).to include("Bulk two")
  end

  it "denies the delete dialog without delete permission" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })
    test_case = create(:tm_test_case, project:, suite:, title: "Protected")
    login_as(viewer)

    get delete_dialog_project_test_management_test_case_path(project, test_case),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:forbidden)
  end

  it "soft-deletes from edit and lists the case under Deleted" do
    test_case = create(:tm_test_case, project:, suite:, title: "Soft")

    delete project_test_management_test_case_path(project, test_case)

    expect(response).to redirect_to(project_test_management_test_cases_path(project))
    expect(test_case.reload).to be_deleted
    expect(test_case.deleted_from_suite_id).to eq(suite.id)

    get project_test_management_test_cases_path(project, suite_id: "deleted")
    expect(response.body).to include("Soft")
    expect(response.body).to include("tm-restore-case-#{test_case.id}")
  end

  it "wires the cases list bulk delete form to the confirmation dialog" do
    create(:tm_test_case, project:, suite:)

    get project_test_management_test_cases_path(project)

    expect(response.body).to include(delete_dialog_project_test_management_test_cases_bulk_path(project))
    expect(response.body).to include("tm-bulk-delete-form")
    expect(response.body).not_to include("data-turbo-confirm")
  end

  it "restores into the previous folder" do
    test_case = create(:tm_test_case, project:, suite:, title: "Back")
    TestManagement::TestCases::DeleteService.new(user:, model: test_case).call

    post restore_project_test_management_test_case_path(project, test_case)

    expect(response).to redirect_to(project_test_management_test_case_path(project, test_case))
    expect(test_case.reload).not_to be_deleted
    expect(test_case.suite_id).to eq(suite.id)
  end

  it "asks for a folder when restoring after the previous suite was removed" do
    test_case = create(:tm_test_case, project:, suite:, title: "Orphan")
    TestManagement::TestCases::DeleteService.new(user:, model: test_case).call
    suite.destroy!

    post restore_project_test_management_test_case_path(project, test_case)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("tm-restore-form")

    post restore_project_test_management_test_case_path(project, test_case),
         params: { suite_id: other_suite.id }

    expect(test_case.reload).not_to be_deleted
    expect(test_case.suite_id).to eq(other_suite.id)
  end

  it "keeps the deleted case id reserved" do
    test_case = create(:tm_test_case, project:, title: "Reserved")
    deleted_id = test_case.id
    TestManagement::TestCases::DeleteService.new(user:, model: test_case).call

    created = TestManagement::TestCases::CreateService
                .new(user:)
                .call(project:, title: "New", priority: "medium", status: "ready")
                .result

    expect(created.id).to be > deleted_id
    expect(TestManagement::TestCase.find(deleted_id)).to be_deleted
  end
end
