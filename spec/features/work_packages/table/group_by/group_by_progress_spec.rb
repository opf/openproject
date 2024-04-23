require "spec_helper"

RSpec.describe "Work Package group by progress", :js do
  shared_let(:user) { create(:admin) }

  shared_let(:project) { create(:project) }

  shared_let(:wp_none) { create(:work_package, project:) }
  shared_let(:wp_10p1) { create(:work_package, project:, done_ratio: 10) }
  shared_let(:wp_10p2) { create(:work_package, project:, done_ratio: 10) }
  shared_let(:wp_50p) { create(:work_package, project:, done_ratio: 50) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { Components::WorkPackages::GroupBy.new }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "estimated_hours", "remaining_hours", "done_ratio"]

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed wp_none, wp_10p1, wp_10p2, wp_50p
  end

  it "shows group headers for group by progress (regression test #26717)" do
    # Group by category
    group_by.enable_via_menu "% Complete"

    # Expect table to be grouped as WP created above
    group_by.expect_number_of_groups 3
    group_by.expect_grouped_by_value "50%", 1
    group_by.expect_grouped_by_value "10%", 2
    group_by.expect_grouped_by_value "-", 1

    # Update work and remaining work of wp_none to have 50% completeness
    wp_table.edit_field(wp_none, :estimatedTime).update "10"
    loading_indicator_saveguard
    wp_table.edit_field(wp_none, :remainingTime).update "5"
    loading_indicator_saveguard

    # Expect changed groups
    group_by.expect_number_of_groups 2
    group_by.expect_grouped_by_value "10%", 2
    group_by.expect_grouped_by_value "50%", 2
  end

  context "with grouped query" do
    let!(:query) do
      query              = build(:query, user:, project:)
      query.column_names = ["subject", "done_ratio"]
      query.group_by = "done_ratio"

      query.save!
      query
    end

    it "keeps the disabled group by when reloading (Regression WP#26778)" do
      # Expect table to be grouped as WP created above
      group_by.expect_number_of_groups 3

      group_by.disable_via_menu
      group_by.expect_no_groups

      # Expect disabled group by to be kept after reload
      page.driver.browser.navigate.refresh
      group_by.expect_no_groups

      # But query has not been changed
      query.reload
      expect(query.group_by).to eq "done_ratio"
    end
  end
end
