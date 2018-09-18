require 'spec_helper'

describe 'Refreshing in inline-create row', flaky: true, js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create :project }

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { ::Components::WorkPackages::Columns.new }

  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
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

    columns.add 'Progress (%)'
    expect(page).to have_selector('.wp-inline-create-row .wp-table--cell-td.wp-table--cell-td.percentageDone')
  end
end
