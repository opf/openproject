# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package table semantic ID navigation",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  let(:user) { create(:admin) }
  let(:project) { create(:project, identifier: "NAVTEST") }
  let(:work_package) { create(:work_package, project:, subject: "Semantic nav test") }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    work_package
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  it "navigates to the semantic ID URL when clicking the ID link" do
    semantic_id = work_package.reload.identifier

    # The ID column should show the semantic identifier
    expect(page).to have_link(semantic_id)

    # Click the semantic ID link in the table
    page.find("a", text: semantic_id).click

    # Should navigate to a URL containing the semantic identifier, not the numeric ID
    expect(page).to have_current_path(
      project_work_package_path(project, semantic_id, "activity")
    )
  end
end
