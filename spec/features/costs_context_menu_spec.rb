require 'spec_helper'

describe 'Work package table log unit costs', js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:work_package) { FactoryBot.create(:work_package) }

  let(:wp_table) { ::Pages::WorkPackagesTable.new }
  let(:menu) { ::Components::WorkPackages::ContextMenu.new }

  def goto_context_menu
    # Go to table
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)

    # Open context menu
    menu.expect_closed
    menu.open_for(work_package)
  end

  before do
    login_as(user)
    work_package

    goto_context_menu
  end

  it 'renders the log unit costs menu item' do
    menu.choose(I18n.t(:label_log_costs))
    expect(page).to have_selector('h2', text: I18n.t(:label_log_costs))
  end
end
