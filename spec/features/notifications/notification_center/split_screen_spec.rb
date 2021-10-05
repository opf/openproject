require 'spec_helper'

describe "Split screen in the notification center", type: :feature, js: true do
  shared_let(:project) { FactoryBot.create :project }
  shared_let(:work_package) { FactoryBot.create :work_package, project: project }
  shared_let(:second_work_package) { FactoryBot.create :work_package, project: project }
  shared_let(:recipient) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages]
  end
  shared_let(:notification) do
    FactoryBot.create :notification,
                      recipient: recipient,
                      project: project,
                      resource: work_package,
                      journal: work_package.journals.last
  end

  shared_let(:second_notification) do
    FactoryBot.create :notification,
                      recipient: recipient,
                      project: project,
                      resource: second_work_package,
                      journal: second_work_package.journals.last
  end

  let(:center) { ::Pages::Notifications::Center.new }
  let(:split_screen) { ::Pages::SplitWorkPackage.new work_package }

  describe 'basic use case' do
    current_user { recipient }

    before do
      visit home_path
      center.open
    end

    it 'can switch between multiple notifications and the split screen remains open and updates accordingly' do
      center.expect_bell_count 2
      center.click_item notification

      # Opening the split screen marks the notifications as read
      split_screen.expect_open
      center.expect_work_package_item notification
      center.expect_work_package_item second_notification

      # Clicking on a another notification changes the split screen content
      center.click_item second_notification
      split_screen = ::Pages::SplitWorkPackage.new(second_work_package, project)
      split_screen.expect_open
      center.expect_work_package_item second_notification
    end

    it 'can navigate between the tabs' do
      center.expect_bell_count 2
      center.click_item notification
      split_screen.expect_open

      # Activity is selected as default
      split_screen.expect_tab :activity
      activity_tab = ::Components::WorkPackages::Activities.new(work_package)
      activity_tab.expect_wp_has_been_created_activity work_package

      # Navigate to the relations tab
      split_screen.switch_to_tab tab: 'relations'
      split_screen.expect_tab :relations
      relations_tab = ::Components::WorkPackages::Relations.new(work_package)
      relations_tab.expect_no_relation work_package

      # Navigate to full view and back
      wp_full = split_screen.switch_to_fullscreen
      wp_full.expect_tab :relations

      wp_full.go_back
      split_screen.expect_tab :relations

      # The split screen can be closed
      split_screen.close
      split_screen.expect_closed
    end
  end
end
