require 'spec_helper'

describe 'Work package table context menu', js: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:work_package) { FactoryBot.create(:work_package) }

  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(work_package.project) }
  let(:menu) { Components::WorkPackages::ContextMenu.new }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }
  let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }

  def goto_context_menu list_view = true
    # Go to table
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)

    display_representation.switch_to_card_layout unless list_view
    loading_indicator_saveguard

    # Open context menu
    menu.expect_closed
    menu.open_for(work_package)
  end

  shared_examples_for 'provides a context menu' do
    let(:list_view) { raise 'needs to be defined' }

    context 'for a single work package' do
      it 'provide a context menu' do
        # Open detail pane
        goto_context_menu list_view
        menu.choose('Open details view')
        split_page = Pages::SplitWorkPackage.new(work_package)
        split_page.expect_attributes Subject: work_package.subject

        # Open full view
        goto_context_menu list_view
        menu.choose('Open fullscreen view')
        expect(page).to have_selector('.work-packages--show-view .inline-edit--container.subject',
                                      text: work_package.subject)

        # Open log time
        goto_context_menu list_view
        menu.choose('Log time')
        time_logging_modal.is_visible true
        time_logging_modal.work_package_is_missing false
        time_logging_modal.perform_action 'Cancel'

        # Open Move
        goto_context_menu list_view
        menu.choose('Change project')
        expect(page).to have_selector('h2', text: I18n.t(:button_move))
        expect(page).to have_selector('a.issue', text: "##{work_package.id}")

        # Open Copy
        goto_context_menu list_view
        menu.choose('Copy')
        # Split view open in copy state
        expect(page).
          to have_selector('.wp-new-top-row',
                           text: "#{work_package.status.name.capitalize}\n#{work_package.type.name.upcase}")
        expect(page).to have_field('wp-new-inline-edit--field-subject', with: work_package.subject)

        # Open Delete
        goto_context_menu list_view
        menu.choose('Delete')
        destroy_modal.expect_listed(work_package)
        destroy_modal.cancel_deletion

        # Open create new child
        goto_context_menu list_view
        menu.choose('Create new child')
        expect(page).to have_selector('.inline-edit--container.subject input')
        expect(page).to have_selector('.inline-edit--field.type')
        expect(current_url).to match(/.*\/create_new\?.*(\&)*parent_id=#{work_package.id.to_s}/)

        find('#work-packages--edit-actions-cancel').click
        expect(page).to have_no_selector('.inline-edit--container.subject input')

        # Timeline actions only shown when open
        wp_timeline.expect_timeline!(open: false)

        goto_context_menu list_view
        menu.expect_no_options 'Add predecessor', 'Add follower'
      end
    end

    context 'for multiple selected WPs' do
      let!(:work_package2) { FactoryBot.create(:work_package) }

      it 'provides a context menu with a subset of the available menu items' do
        # Go to table
        wp_table.visit!
        wp_table.expect_work_package_listed(work_package)
        wp_table.expect_work_package_listed(work_package2)

        display_representation.switch_to_card_layout unless list_view
        loading_indicator_saveguard

        # Select all WPs
        find('body').send_keys [:control, 'a']

        menu.open_for(work_package)
        menu.expect_options ['Open details view', 'Open fullscreen view',
                             'Bulk edit', 'Bulk copy', 'Bulk change of project', 'Bulk delete']
      end
    end
  end

  before do
    login_as(user)
    work_package
  end

  context 'in the table' do
    it_behaves_like 'provides a context menu' do
      let(:list_view) { true }
    end

    it 'provides a context menu with timeline options' do
      goto_context_menu true
      # Open timeline
      wp_timeline.toggle_timeline
      wp_timeline.expect_timeline!(open: true)

      # Open context menu
      menu.expect_closed
      menu.open_for(work_package)
      menu.expect_options ['Add predecessor', 'Add follower']
    end

    describe 'creating work packages' do
      let!(:priority) { FactoryBot.create :issue_priority, is_default: true }
      let!(:status) { FactoryBot.create :default_status }
      let!(:type) { FactoryBot.create :type_task }
      let!(:project) { FactoryBot.create :project, types: [type] }
      let!(:work_package) { FactoryBot.create :work_package, project: project, type: type, status: status, priority: priority }
      let(:wp_table) { Pages::WorkPackagesTable.new project }

      it 'can create a new child from the context menu (Regression #33329)' do
        goto_context_menu true
        menu.choose('Create new child')
        expect(page).to have_selector('.inline-edit--container.subject input')
        expect(current_url).to match(/.*\/create_new\?.*(\&)*parent_id=#{work_package.id.to_s}/)

        split_view = ::Pages::SplitWorkPackageCreate.new project: work_package.project
        subject = split_view.edit_field(:subject)
        subject.set_value 'Child task'
        subject.submit_by_enter

        split_view.expect_and_dismiss_notification message: 'Successful creation.'
        expect(page).to have_selector('.wp-breadcrumb', text: "Parent:\n#{work_package.subject}")
        wp = WorkPackage.last
        expect(wp.parent).to eq work_package
      end
    end
  end

  context 'in the card view' do
    it_behaves_like 'provides a context menu' do
      let(:list_view) { false }
    end
  end
end
