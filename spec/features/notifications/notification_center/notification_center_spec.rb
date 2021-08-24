require 'spec_helper'
require 'support/components/notifications/center'

describe "Notification center", type: :feature, js: true do
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
      center.expect_work_package_item second_notification
      center.click_item notification
      split_screen.expect_open

      activity_tab.expect_wp_has_been_created_activity work_package
    end
  end

  describe 'basic use case' do
    current_user { recipient }

    it 'can see the notification and dismiss it' do
      visit home_path
      center.expect_bell_count 2
      center.open

      center.expect_work_package_item notification
      center.expect_work_package_item second_notification
      center.mark_all_read

      notification.reload
      expect(notification.read_ian).to be_truthy

      center.expect_no_item notification
      center.expect_no_item second_notification

      center.open
      center.expect_bell_count 0
    end

    it 'can open the split screen of the notification' do
      visit home_path
      center.expect_bell_count 2
      center.open

      center.click_item notification
      split_screen.expect_open
      center.expect_item_not_read notification
      center.expect_work_package_item second_notification

      center.mark_notification_as_read notification

      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      center.close
      center.expect_bell_count 1

      center.open
      center.expect_no_item notification
      center.expect_work_package_item second_notification
    end

    context 'with multiple notifications per work package' do
      # In this context we have four notifications for two work packages.
      shared_let(:third_notification) do
        FactoryBot.create :notification,
                          recipient: recipient,
                          project: project,
                          resource: second_work_package,
                          journal: work_package.journals.last
      end
      shared_let(:fourth_notification) do
        FactoryBot.create :notification,
                          recipient: recipient,
                          project: project,
                          resource: work_package,
                          journal: work_package.journals.last
      end
      let(:second_split_screen) { ::Pages::SplitWorkPackage.new second_work_package }

      it 'aggregates notifications per work package and sets all as read when opened' do
        visit home_path
        center.expect_bell_count 4
        center.open

        center.expect_number_of_notifications 2

        # Click on first list item, which should be the youngest notification
        center.click_item fourth_notification

        split_screen.expect_open
        center.mark_notification_as_read fourth_notification

        retry_block do
          notification.reload
          raise "Expected notification to be marked read" unless notification.read_ian
        end

        expect(second_notification.reload.read_ian).to be_falsey
        expect(third_notification.reload.read_ian).to be_falsey
        expect(fourth_notification.reload.read_ian).to be_truthy

        # Click on second list item, which should be the youngest notification that does
        # not belong to the work package that represents the first list item.
        center.click_item third_notification

        second_split_screen.expect_open
        center.mark_notification_as_read third_notification
        expect(second_notification.reload.read_ian).to be_truthy
        expect(third_notification.reload.read_ian).to be_truthy
      end
    end
  end
end
