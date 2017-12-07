require 'spec_helper'

describe 'Work Package group by progress', js: true do
  let(:user) { FactoryGirl.create :admin }

  let(:project) { FactoryGirl.create(:project) }

  let!(:wp_1) { FactoryGirl.create(:work_package, project: project) }
  let!(:wp_2) { FactoryGirl.create(:work_package, project: project, done_ratio: 10) }
  let!(:wp_3) { FactoryGirl.create(:work_package, project: project, done_ratio: 10) }
  let!(:wp_4) { FactoryGirl.create(:work_package, project: project, done_ratio: 50) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let!(:query) do
    query              = FactoryGirl.build(:query, user: user, project: project)
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
    wp_table.click_setting_item 'Group by ...'
    select 'Progress (%)', from: 'selected_columns_new'
    click_button 'Apply'

    # Expect table to be grouped as WP created above
    expect(page).to have_selector('.group--value .count', count: 3)
    expect(page).to have_selector('.group--value', text: '0 (1)')
    expect(page).to have_selector('.group--value', text: '10 (2)')
    expect(page).to have_selector('.group--value', text: '50 (1)')

    # Update category of wp_none
    cat = wp_table.edit_field(wp_1, :percentageDone)
    cat.update '50'

    loading_indicator_saveguard

    # Expect changed groups
    expect(page).to have_selector('.group--value .count', count: 2)
    expect(page).to have_selector('.group--value', text: '10 (2)')
    expect(page).to have_selector('.group--value', text: '50 (2)')
  end
end
