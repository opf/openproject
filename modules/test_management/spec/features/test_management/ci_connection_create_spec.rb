# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Create CI connection", :js do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases manage_test_ci]
           })
  end

  current_user { user }

  it "creates a connection from project settings" do
    visit project_test_management_project_settings_path(project)

    section = find("[data-test-selector='tm-ci-new']")
    section.click unless section[:open]
    within(section) do
      fill_in "tm-ci-new-name", with: "Shop GitHub"
      fill_in "tm-ci-new-repository", with: "acme/shop"
      fill_in "tm-ci-new-token", with: "ghp_feature_spec_token"
      click_button I18n.t("test_management.project_settings.ci.add")
    end

    expect(page).to have_css("[data-test-selector='tm-ci-connections']", wait: 10)
    connection = TestManagement::CiConnection.find_by(project:, name: "Shop GitHub")
    expect(connection).to be_present
    expect(connection.decrypted_token).to eq("ghp_feature_spec_token")
  end
end
