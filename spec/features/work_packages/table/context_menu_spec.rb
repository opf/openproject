require 'spec_helper'

describe 'Work package table context menu', js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:work_package) { FactoryBot.create(:work_package) }

  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(work_package.project) }
  let(:menu) { Components::WorkPackages::ContextMenu.new }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

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
    expect(page).to have_selector('.work-packages--show-view .wp-edit-field.subject',
                                  text: work_package.subject)

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
    # Split view open in copy state
    expect(page).to have_selector('.wp-new-top-row', text: "#{work_package.status.name.capitalize}\n#{work_package.type}")
    expect(page).to have_field('wp-new-inline-edit--field-subject', with: work_package.subject)

    # Open Delete
    goto_context_menu
    menu.choose('Delete')
    destroy_modal.expect_listed(work_package)
    destroy_modal.cancel_deletion

    # Open create new child
    goto_context_menu
    menu.choose('Create new child')
    expect(page).to have_selector('.wp-edit-field.subject input')
    expect(page).to have_selector('.wp-edit-field--display-field.type')

    find('#work-packages--edit-actions-cancel').click
    expect(page).to have_no_selector('.wp-edit-field.subject input')

    # Timeline actions only shown when open
    wp_timeline.expect_timeline!(open: false)

    goto_context_menu
    menu.expect_no_options 'Add predecessor', 'Add follower'

    # Open timeline
    wp_timeline.toggle_timeline
    wp_timeline.expect_timeline!(open: true)

    # Open context menu
    menu.expect_closed
    menu.open_for(work_package)
    menu.expect_options ['Add predecessor', 'Add follower']
  end

  context 'multiple selected' do
    let!(:work_package2) { FactoryBot.create(:work_package) }

    before do
      # Go to table
      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
      wp_table.expect_work_package_listed(work_package2)

      # Select both
      find('body').send_keys [:control, 'a']
    end

    it 'shows a subset of the available menu items' do
      menu.open_for(work_package)
      menu.expect_options ['Open details view', 'Open fullscreen view',
                           'Bulk edit', 'Bulk copy', 'Bulk move', 'Bulk delete']
    end
  end
end
