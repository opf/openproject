require 'spec_helper'

describe 'Work Package group by progress', js: true do
  let(:user) { create :admin }

  let(:project) { create(:project) }

  let!(:wp_1) { create(:work_package, project: project) }
  let!(:wp_2) { create(:work_package, project: project, done_ratio: 10) }
  let!(:wp_3) { create(:work_package, project: project, done_ratio: 10) }
  let!(:wp_4) { create(:work_package, project: project, done_ratio: 50) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }

  let!(:query) do
    query              = build(:query, user: user, project: project)
    query.column_names = ['subject', 'done_ratio']

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed wp_1, wp_2, wp_3, wp_4
  end

  it 'shows group headers for group by progress (regression test #26717)' do
    # Group by category
    group_by.enable_via_menu 'Progress (%)'

    # Expect table to be grouped as WP created above
    group_by.expect_number_of_groups 3
    group_by.expect_grouped_by_value '0%', 1
    group_by.expect_grouped_by_value '10%', 2
    group_by.expect_grouped_by_value '50%', 1

    # Update category of wp_none
    cat = wp_table.edit_field(wp_1, :percentageDone)
    cat.update '50'

    loading_indicator_saveguard

    # Expect changed groups
    group_by.expect_number_of_groups 2
    group_by.expect_grouped_by_value '10%', 2
    group_by.expect_grouped_by_value '50%', 2
  end

  context 'with grouped query' do
    let!(:query) do
      query              = build(:query, user: user, project: project)
      query.column_names = ['subject', 'done_ratio']
      query.group_by = 'done_ratio'

      query.save!
      query
    end

    it 'keeps the disabled group by when reloading (Regression WP#26778)' do
      # Expect table to be grouped as WP created above
      group_by.expect_number_of_groups 3

      group_by.disable_via_menu
      group_by.expect_no_groups

      # Expect disabled group by to be kept after reload
      page.driver.browser.navigate.refresh
      group_by.expect_no_groups

      # But query has not been changed
      query.reload
      expect(query.group_by).to eq 'done_ratio'
    end
  end
end
