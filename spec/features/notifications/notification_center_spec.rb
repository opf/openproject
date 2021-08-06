require 'spec_helper'
require 'support/components/notifications/center'

describe "Notification center", type: :feature, js: true do
  shared_let(:project) { FactoryBot.create :project }
  shared_let(:work_package) { FactoryBot.create :work_package, project: project }
  shared_let(:work_package2) { FactoryBot.create :work_package, project: project }
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

  shared_let(:notification2) do
      FactoryBot.create :notification,
                        recipient: recipient,
                        project: project,
                        resource: work_package2,
                        journal: work_package.journals.last
    end

  let(:center) { ::Components::Notifications::Center.new }
  let(:activity_tab) { ::Components::WorkPackages::Activities.new(work_package) }
  let(:split_screen) { ::Pages::SplitWorkPackage.new work_package }

  describe 'notification for a new journal' do
    current_user { recipient }

    it 'will not show all details of the journal' do
      allow(notification.journal).to receive(:initial?).and_return true
      visit home_path
      center.expect_bell_count 2
      center.open

      center.expect_work_package_item notification
      center.expect_work_package_item notification2
      center.click_item notification
      split_screen.expect_open

      activity_tab.expect_activity_listed "created on #{work_package.created_at.strftime('%m/%d/%Y')}"
    end
  end

  describe 'basic use case' do
    current_user { recipient }

    it 'can see the notification and dismiss it' do
      visit home_path
      center.expect_bell_count 2
      center.open

      center.expect_work_package_item notification
      center.expect_work_package_item notification2
      center.mark_all_read

      center.expect_bell_count 0
      notification.reload
      expect(notification.read_ian).to be_truthy

      center.expect_no_item notification
      center.expect_no_item notification2
    end

    it 'can open the split screen of the notification to mark it as read' do
      visit home_path
      center.expect_bell_count 2
      center.open

      center.click_item notification
      split_screen.expect_open
      center.expect_read_item notification
      center.expect_work_package_item notification2

      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      center.close
      center.expect_bell_count 1

      center.open
      center.expect_no_item notification
      center.expect_work_package_item notification2
    end

    it 'can switch between multiple notifications and the split screen remains open and updates accordingly' do
      visit home_path
      center.expect_bell_count 2
      center.open

      center.click_item notification
      split_screen.expect_open
      center.expect_read_item notification
      center.expect_work_package_item notification2

      center.click_item notification2
      split_screen = ::Pages::SplitWorkPackage.new(work_package2, project)
      split_screen.expect_open
      center.expect_read_item notification2

      split_screen.close
      split_screen.expect_closed

      center.close
      center.expect_bell_count 0

      center.open
      center.expect_empty
    end
  end
end
