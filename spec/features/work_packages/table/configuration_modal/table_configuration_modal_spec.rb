require 'spec_helper'

describe 'Work Package table configuration modal', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }
  let!(:wp_1) { FactoryBot.create(:work_package, project: project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }

  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = ['subject', 'done_ratio']

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit!
    wp_table.expect_work_package_listed wp_1
  end

  it 'focuses on the modal when opening it' do
    modal.open!
    expect(page).to have_focus_on('.columns-modal--content input.select2-input')
  end

  it 'focuses on the columns tab when opened through header' do
    # Open header dropdown
    find('.work-package-table--container th #subject').click

    # Open insert columns entry
    find('#column-context-menu .menu-item', text: 'Insert columns ...').click

    # Expect focus on table configuration modal
    expect(page).to have_focus_on('.columns-modal--content input.select2-input')

    # Expect active tab is columns
    expect(page).to have_selector('.tab-show.selected', text: 'Columns')
  end
end
