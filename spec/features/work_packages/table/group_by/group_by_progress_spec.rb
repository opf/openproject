require 'spec_helper'

describe 'Work Package group by progress', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }

  let!(:wp_1) { FactoryBot.create(:work_package, project: project) }
  let!(:wp_2) { FactoryBot.create(:work_package, project: project, done_ratio: 10) }
  let!(:wp_3) { FactoryBot.create(:work_package, project: project, done_ratio: 10) }
  let!(:wp_4) { FactoryBot.create(:work_package, project: project, done_ratio: 50) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }

  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
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
    expect(page).to have_selector('.group--value .count', count: 3)
    expect(page).to have_selector('.group--value', text: '0% (1)')
    expect(page).to have_selector('.group--value', text: '10% (2)')
    expect(page).to have_selector('.group--value', text: '50% (1)')

    # Update category of wp_none
    cat = wp_table.edit_field(wp_1, :percentageDone)
    cat.update '50'

    loading_indicator_saveguard

    # Expect changed groups
    expect(page).to have_selector('.group--value .count', count: 2)
    expect(page).to have_selector('.group--value', text: '10% (2)')
    expect(page).to have_selector('.group--value', text: '50% (2)')
  end

  context 'with grouped query' do
    let!(:query) do
      query              = FactoryBot.build(:query, user: user, project: project)
      query.column_names = ['subject', 'done_ratio']
      query.group_by = 'done_ratio'

      query.save!
      query
    end

    it 'keeps the disabled group by when reloading (Regression WP#26778)' do
      # Expect table to be grouped as WP created above
      expect(page).to have_selector('.group--value .count', count: 3)

      group_by.disable_via_menu
      expect(page).to have_no_selector('.group--value')

      # Expect disabled group by to be kept after reload
      page.driver.browser.navigate.refresh
      expect(page).to have_no_selector('.group--value')

      # But query has not been changed
      query.reload
      expect(query.group_by).to eq 'done_ratio'
    end
  end
end
