require "spec_helper"

RSpec.describe "Work Package table configuration modal", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let!(:wp_1) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "done_ratio"]

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit!
    wp_table.expect_work_package_listed wp_1
  end

  it "focuses on the columns tab when opened through header" do
    # Open header dropdown
    find(".work-package-table--container th #subject").click

    # Open insert columns entry
    find("#column-context-menu .menu-item", text: "Insert columns").click

    # Expect active tab is columns
    expect(page).to have_css(".op-tab-row--link_selected", text: "COLUMNS")
  end
end
