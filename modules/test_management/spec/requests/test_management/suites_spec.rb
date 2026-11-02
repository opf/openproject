# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Test management suites (folders)", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_test_cases add_test_cases edit_test_cases manage_test_suites]
           })
  end

  before do
    login_as(user)
  end

  it "renders the new-folder form with suite[name] params" do
    get project_test_management_test_cases_path(project)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('name="suite[name]"')
  end

  it "creates a root folder and opens it" do
    post project_test_management_suites_path(project), params: { suite: { name: "Test" } }

    created = project.tm_suites.find_by(name: "Test", parent_id: nil)
    expect(created).to be_present
    expect(response).to redirect_to(project_test_management_test_cases_path(project, suite_id: created.id))
  end

  it "does not render a 'Folders' title next to New folder" do
    get project_test_management_test_cases_path(project)

    expect(response.body).to include('data-test-selector="tm-new-folder-button"')
    expect(response.body).not_to include("tm-folder-tree--title")
  end

  it "keeps New folder top-level even when a folder is selected" do
    parent = create(:tm_suite, project:, name: "Parent")

    get project_test_management_test_cases_path(project, suite_id: parent.id)

    new_folder_form = response.body[/<form[^>]*id="tm-new-folder-dialog[^"]*-form".*?<\/form>/m]
    expect(new_folder_form).to be_present
    expect(new_folder_form).not_to include("suite[parent_id]")
  end

  it "offers Add subfolder for the selected folder" do
    parent = create(:tm_suite, project:, name: "Parent")

    get project_test_management_test_cases_path(project, suite_id: parent.id)

    expect(response.body).to include('data-test-selector="tm-add-subfolder-button"')
    expect(response.body).to include("Inside: Parent")
    subfolder_form = response.body[/<form[^>]*id="tm-add-subfolder-dialog-form".*?<\/form>/m]
    expect(subfolder_form).to include('name="suite[parent_id]"')
    expect(subfolder_form).to include(%(value="#{parent.id}"))
  end

  it "does not offer Add subfolder without a selected folder" do
    get project_test_management_test_cases_path(project)

    expect(response.body).not_to include("tm-add-subfolder-button")
  end

  it "renders nested folders as expandable branches" do
    parent = create(:tm_suite, project:, name: "Parent")
    child = create(:tm_suite, project:, name: "Child", parent:)
    create(:tm_suite, project:, name: "Grandchild", parent: child)

    get project_test_management_test_cases_path(project)

    expect(response.body.scan('<details class="tm-folder-branch" open').size).to eq(2)
    expect(response.body).to include("tm-folder-children")
    expect(response.body).to include("octicon-chevron-right")
    expect(response.body).to include("octicon-file-directory")
  end

  it "creates a subfolder" do
    parent = create(:tm_suite, project:, name: "Parent")

    post project_test_management_suites_path(project), params: { suite: { name: "Child", parent_id: parent.id } }

    child = project.tm_suites.find_by(name: "Child")
    expect(child.parent).to eq(parent)
    expect(response).to redirect_to(project_test_management_test_cases_path(project, suite_id: child.id))
  end

  it "rejects a parent from another project" do
    other = create(:tm_suite, project: create(:project), name: "Foreign")

    post project_test_management_suites_path(project), params: { suite: { name: "Child", parent_id: other.id } }

    expect(project.tm_suites.where(name: "Child")).not_to exist
  end

  it "renames and deletes a folder" do
    suite = create(:tm_suite, project:, name: "Old")

    patch project_test_management_suite_path(project, suite), params: { suite: { name: "New" } }
    expect(suite.reload.name).to eq("New")

    delete project_test_management_suite_path(project, suite)
    expect(TestManagement::Suite.where(id: suite.id)).not_to exist
  end
end
