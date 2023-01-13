require 'spec_helper'

shared_examples_for 'provides a single WP context menu' do
  let(:open_context_menu) { raise 'needs to be defined' }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(work_package.project) }

  it 'provide a context menu' do
    # Open detail pane
    open_context_menu.call
    menu.choose('Open details view')
    split_page = Pages::SplitWorkPackage.new(work_package, work_package.project)
    split_page.expect_attributes Subject: work_package.subject

    # Open full view
    open_context_menu.call
    menu.choose('Open fullscreen view')
    expect(page).to have_selector('.work-packages--show-view .inline-edit--container.subject',
                                  text: work_package.subject)

    # Open log time
    open_context_menu.call
    menu.choose('Log time')
    time_logging_modal.is_visible true
    time_logging_modal.work_package_is_missing false
    time_logging_modal.perform_action 'Cancel'

    # Open Move
    open_context_menu.call
    menu.choose('Change project')
    expect(page).to have_selector('h2', text: I18n.t(:button_move))
    expect(page).to have_selector('a.work_package', text: "##{work_package.id}")

    # Open Copy
    open_context_menu.call
    menu.choose('Copy')
    # Split view open in copy state
    expect(page)
      .to have_selector('.wp-new-top-row',
                        text: "#{work_package.status.name.capitalize}\n#{work_package.type.name.upcase}")
    expect(page).to have_field('wp-new-inline-edit--field-subject', with: work_package.subject)

    # Open Delete
    open_context_menu.call
    menu.choose('Delete')
    destroy_modal.expect_listed(work_package)
    destroy_modal.cancel_deletion

    # Open create new child
    open_context_menu.call
    menu.choose('Create new child')
    expect(page).to have_selector('.inline-edit--container.subject input')
    expect(current_url).to match(/.*\/create_new\?.*(&)*parent_id=#{work_package.id}/)

    find('#work-packages--edit-actions-cancel').click
    expect(page).to have_no_selector('.inline-edit--container.subject input')

    # Timeline actions only shown when open
    wp_timeline.expect_timeline!(open: false)

    open_context_menu.call
    menu.expect_no_options 'Add predecessor', 'Add follower'

    # Copy to other project
    open_context_menu.call
    menu.choose('Copy to other project')
    expect(page).to have_selector('h2', text: I18n.t(:button_copy))
    expect(page).to have_selector('a.work_package', text: "##{work_package.id}")
  end

  describe 'creating work packages' do
    let!(:priority) { create :issue_priority, is_default: true }
    let!(:status) { create :default_status }

    it 'can create a new child from the context menu (Regression #33329)' do
      open_context_menu.call
      menu.choose('Create new child')
      expect(page).to have_selector('.inline-edit--container.subject input')
      expect(current_url).to match(/.*\/create_new\?.*(&)*parent_id=#{work_package.id}/)

      split_view = Pages::SplitWorkPackageCreate.new project: work_package.project
      subject = split_view.edit_field(:subject)
      subject.set_value 'Child task'
      # Wait a bit for the split view to be fully initialized
      sleep 1
      subject.submit_by_enter

      split_view.expect_and_dismiss_toaster message: 'Successful creation.'
      expect(page).to have_selector('[data-qa-selector="op-wp-breadcrumb"]', text: "Parent:\n#{work_package.subject}")
      wp = WorkPackage.last
      expect(wp.parent).to eq work_package
    end
  end
end
