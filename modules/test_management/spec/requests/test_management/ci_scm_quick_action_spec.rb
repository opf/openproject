# frozen_string_literal: true

require "spec_helper"

# 0016: the Repositories-module hint offers a quick action instead of a prefilled form; connections
# take reference names, e2e mode and an attached repository.
RSpec.describe "Test management CI connections: attach repository", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management repository]) }
  shared_let(:ci_admin) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_ci] }) }
  shared_let(:repository) { create(:repository_git, project:) }

  let(:settings_path) { project_test_management_project_settings_path(project) }
  let(:connections_path) { "/projects/#{project.identifier}/test_management/project_settings/ci_connections" }

  before { login_as(ci_admin) }

  it "shows the hint with a quick action and does not prefill the form" do
    get settings_path

    expect(response).to have_http_status(:ok)
    page = response.parsed_body
    expect(page.at_css("[data-test-selector='tm-ci-attach-scm']")["href"]).to include("attach_scm_repository=1")
    expect(page.at_css("[data-test-selector='tm-ci-scm-prefilled']")).to be_nil
    checkbox = page.at_css("details#tm-ci-new input[type=checkbox][name='ci_connection[scm_repository_id]']")
    expect(checkbox["checked"]).to be_nil
  end

  it "opens the new-connection form with the repository attached when the quick action is used" do
    create(:tm_ci_connection, project:)
    get settings_path, params: { attach_scm_repository: 1 }

    page = response.parsed_body
    expect(page.at_css("details#tm-ci-new")["open"]).not_to be_nil
    expect(page.at_css("[data-test-selector='tm-ci-scm-prefilled']")).to be_present
    checkbox = page.at_css("details#tm-ci-new input[type=checkbox][name='ci_connection[scm_repository_id]']")
    expect(checkbox["value"]).to eq(repository.id.to_s)
    expect(checkbox["checked"]).to be_present
    expect(TestManagement::CiConnection.where(project_id: project.id).count).to eq(1)
  end

  it "saves reference name, e2e mode and the attached repository, then shows the attached note" do
    post connections_path, params: { ci_connection: { name: "Legacy", provider: "jenkins", base_url: "https://ci.example.com",
                                                      repository: "legacy/e2e", ingest_mode: "new_run", inbound_only: "1",
                                                      reference_name: "legacy", e2e_tests: "always",
                                                      scm_repository_id: repository.id.to_s } }
    expect(response).to have_http_status(:see_other)

    connection = TestManagement::CiConnection.find_by!(project_id: project.id)
    expect(connection).to have_attributes(reference_name: "legacy", e2e_tests: "always", scm_repository_id: repository.id)

    get settings_path
    page = response.parsed_body
    expect(page.at_css("[data-test-selector='tm-ci-scm-attached']").text).to include("Legacy")
    expect(page.at_css("[data-test-selector='tm-ci-attach-scm']")).to be_nil
    expect(page.at_css("[data-test-selector='tm-ci-reference-#{connection.id}']").text).to include("legacy")

    patch "#{connections_path}/#{connection.id}", params: { ci_connection: { scm_repository_id: "" } }
    expect(connection.reload.scm_repository_id).to be_nil
  end
end
