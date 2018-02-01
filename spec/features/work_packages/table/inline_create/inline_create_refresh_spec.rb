require 'spec_helper'

describe 'Refreshing in inline-create row', flaky: true, js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let!(:query) do
    query              = FactoryGirl.build(:query, user: user, project: project)
    query.column_names = ['subject', 'category']
    query.filters.clear

    query.save!
    query
  end

  before do
    login_as user
    wp_table.visit_query(query)
  end


  it 'correctly updates the set of active columns' do
    expect(page).to have_selector('.wp--row', count: 0)

    wp_table.click_inline_create
    expect(page).to have_selector('.wp--row', count: 1)
    expect(page).to have_selector('.wp-inline-create-row')
    expect(page).to have_selector('.wp-inline-create-row .wp-table--cell-td.subject')
    expect(page).to have_selector('.wp-inline-create-row .wp-table--cell-td.category')

    work_packages_page.add_column! 'Progress (%)'
    expect(page).to have_selector('.wp-inline-create-row .wp-table--cell-td.wp-table--cell-td.percentageDone')
  end
end
