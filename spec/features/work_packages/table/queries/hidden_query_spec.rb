require 'spec_helper'

describe 'Visiting a hidden query', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:highlighting) { ::Components::WorkPackages::Highlighting.new }
  let!(:work_package) { FactoryBot.create :work_package, project: project }

  let!(:query) { FactoryBot.create(:query, name: 'my hidden query', user: user, project: project, hidden: true) }

  before do
    login_as(user)
    wp_table.visit!
  end

  it 'does not render the hidden query' do
    expect(page).to have_selector('.wp-query-menu--search-ul')
    expect(page).to have_no_selector('.ui-menu-item', text: 'my hidden query')

    query.update(name: 'my visible query', hidden: false)
    wp_table.visit!
    expect(page).to have_selector('.ui-menu-item', text: 'my visible query')
  end
end
