require 'spec_helper'

describe 'Work package table context menu', js: true do
  let(:user) { FactoryGirl.create(:admin) }
  let(:work_package) { FactoryGirl.create(:work_package) }

  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:menu) { Components::WorkPackagesContextMenu.new }

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
  end

  it 'provides a context menu for a single work package' do
    # Open detail pane
    goto_context_menu
    menu.choose('Open details view')
    split_page = Pages::SplitWorkPackage.new(work_package)
    split_page.expect_attributes Subject: work_package.subject

    # Open full view
    goto_context_menu
    menu.choose('Open fullscreen view')
    expect(page).to have_selector('.work-packages--show-view #work-package-subject',
                                  text: work_package.subject)

    # Open edit link
    goto_context_menu
    menu.choose('Edit')
    expect(page).to have_selector('#inplace-edit--write-value--subject')
    find('#work-packages--edit-actions-cancel').click
    expect(page).to have_no_selector('#inplace-edit--write-value--subject')

    # Open log time
    goto_context_menu
    menu.choose('Log time')
    expect(page).to have_selector('h2', text: I18n.t(:label_spent_time))

    # Open Move
    goto_context_menu
    menu.choose('Move')
    expect(page).to have_selector('h2', text: I18n.t(:button_move))
    expect(page).to have_selector('a.issue', text: "##{work_package.id}")

    # Open Copy
    goto_context_menu
    menu.choose('Copy')
    expect(page).to have_selector('h2', text: I18n.t(:button_copy))
    expect(page).to have_selector('a.issue', text: "##{work_package.id}")

    # Open Delete
    goto_context_menu
    menu.choose('Delete')
    wp_table.dismiss_alert_dialog!
  end

  context 'multiple selected' do
    let!(:work_package2) { FactoryGirl.create(:work_package) }

    before do
      # Go to table
      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
      wp_table.expect_work_package_listed(work_package2)

      # Select both
      all('td.checkbox input').each { |el| el.set(true) }
    end

    it 'shows a subset of the available menu items' do
      menu.open_for(work_package)
      menu.expect_options ['Open details view', 'Open fullscreen view',
                           'Edit', 'Copy', 'Move', 'Delete']
    end
  end
end
