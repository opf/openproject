require "spec_helper"

RSpec.describe "Notification center", :js, :with_cuprite,
               with_ee: %i[date_alerts],
               # We decrease the notification polling interval because some portions of the JS code rely on something triggering
               # the Angular change detection. This is usually done by the notification polling, but we don't want to wait
               with_settings: { journal_aggregation_time_minutes: 0, notifications_polling_interval: 1_000 } do
  # Notice that the setup in this file here is not following the normal rules as
  # it also tests notification creation.
  let!(:project1) { create(:project) }
  let!(:project2) { create(:project) }
  let!(:recipient) do
    # Needs to take place before the work package is created so that the notification listener is set up
    create(:user,
           member_with_permissions: { project1 => [:view_work_packages], project2 => [:view_work_packages] },
           notification_settings: [build(:notification_setting, all: true)])
  end
  let!(:other_user) do
    create(:user)
  end
  let(:work_package) do
    create(:work_package, project: project1, author: other_user)
  end
  let(:work_package2) do
    create(:work_package, project: project2, author: other_user)
  end
  let(:notification) do
    # Will have been created via the JOURNAL_CREATED event listeners
    work_package.journals.first.notifications.first
  end
  let(:notification2) do
    # Will have been created via the JOURNAL_CREATED event listeners
    work_package2.journals.first.notifications.first
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:side_menu) { Components::Submenu.new }
  let(:activity_tab) { Components::WorkPackages::Activities.new(work_package) }
  let(:split_screen) { Pages::SplitWorkPackage.new work_package }
  let(:split_screen2) { Pages::SplitWorkPackage.new work_package2 }
  let(:full_screen) { Pages::FullWorkPackage.new work_package }

  let(:notifications) do
    [notification, notification2]
  end

  before do
    # The notifications need to be created as a different user
    # as they are otherwise swallowed to avoid self notification.

    User.execute_as(other_user) do
      perform_enqueued_jobs do
        notifications
      end
    end
  end

  describe "notification for a new journal" do
    current_user { recipient }

    it "does not show all details of the journal" do
      visit home_path
      wait_for_reload
      center.expect_bell_count 2
      center.open

      center.expect_work_package_item notification
      center.expect_work_package_item notification2
      center.click_item notification
      split_screen.expect_open

      activity_tab.expect_wp_has_been_created_activity work_package
    end
  end

  describe "basic use case" do
    current_user { recipient }

    it "can see the notification and dismiss it" do
      visit home_path
      wait_for_reload
      center.expect_bell_count 2
      center.open

      center.expect_work_package_item notification
      center.expect_work_package_item notification2
      center.mark_all_read
      wait_for_network_idle

      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      center.expect_no_item notification
      center.expect_no_item notification2

      center.open
      center.expect_bell_count 0
    end

    context "with more than 100 notifications" do
      let(:notifications) do
        attributes = { recipient:, resource: work_package }

        create_list(:notification, 100, attributes.merge(reason: :mentioned)) +
        create_list(:notification, 105, attributes.merge(reason: :watched))
      end

      it "can dismiss all notifications of the currently selected filter" do
        visit home_path
        wait_for_reload
        center.expect_bell_count "99+"
        center.open

        # side menu items show full count of notifications (inbox has one more due to the "Created" notification)
        side_menu.expect_item_with_count "Inbox", 206
        side_menu.expect_item_with_count "Mentioned", 100
        side_menu.expect_item_with_count "Watcher", 105

        # select watcher filter and mark all as read
        side_menu.click_item "Watcher"
        side_menu.finished_loading
        center.mark_all_read
        wait_for_network_idle

        center.expect_bell_count "99+"
        side_menu.expect_item_with_count "Inbox", 101
        side_menu.expect_item_with_count "Mentioned", 100
        side_menu.expect_item_with_no_count "Watcher"

        # select inbox and mark all as read
        side_menu.click_item "Inbox"
        side_menu.finished_loading
        center.mark_all_read
        wait_for_network_idle

        center.expect_bell_count 0
        side_menu.expect_item_with_no_count "Inbox"
        side_menu.expect_item_with_no_count "Mentioned"
        side_menu.expect_item_with_no_count "Watcher"
      end
    end

    it "can open the split screen of the work package when clicking the notification" do
      visit home_path
      wait_for_reload
      center.expect_bell_count 2
      center.open

      center.click_item notification
      split_screen.expect_open

      center.expect_item_not_read notification
      center.expect_work_package_item notification2

      center.mark_notification_as_read notification
      wait_for_network_idle
      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      visit home_path
      wait_for_reload
      center.expect_bell_count 1

      center.open
      center.expect_no_item notification
      center.expect_work_package_item notification2
    end

    it "can open the full view of the work package when double clicking the notification" do
      visit home_path
      center.expect_bell_count 2
      center.open

      center.double_click_item notification
      full_screen.expect_subject

      full_screen.go_back
      center.expect_item_not_read notification
    end

    context "with a new notification" do
      let(:work_package3) do
        create(:work_package,
               project: project1,
               author: other_user)
      end
      let(:notification3) do
        create(:notification,
               reason: :commented,
               recipient:,
               resource: work_package3,
               actor: other_user,
               journal: work_package3.journals.reload.last,
               read_ian: true)
      end

      it "opens a toaster if the notification is part of the current filters" do
        visit home_path
        center.open
        center.expect_bell_count 2
        center.expect_work_package_item notification
        center.expect_work_package_item notification2
        center.expect_no_toaster
        notification3.update(read_ian: false)
        center.expect_toast
        center.update_via_toaster
        center.expect_no_toaster
        center.expect_work_package_item notification
        center.expect_work_package_item notification2
        center.expect_work_package_item notification3
      end

      it "does not open a toaster if the notification is not part of the current filters" do
        visit home_path
        center.open
        center.expect_bell_count 2
        side_menu.click_item "Mentioned"
        side_menu.finished_loading
        center.expect_no_toaster
        notification3.update(read_ian: false)
        # We need to wait for the bell to poll for updates
        sleep 15
        center.expect_no_toaster
      end
    end

    context "with date alert notifications" do
      let(:starting_soon_work_package) do
        # Executing as current user to avoid notification creation
        User.execute_as(recipient) do
          create(:work_package,
                 start_date: 3.days.from_now,
                 project: project1)
        end
      end
      let(:ending_soon_work_package) do
        # Executing as current user to avoid notification creation
        User.execute_as(recipient) do
          create(:work_package,
                 due_date: 2.days.from_now,
                 project: project1)
        end
      end
      let(:overdue_milestone_work_package) do
        # Executing as current user to avoid notification creation
        User.execute_as(recipient) do
          create(:work_package,
                 :is_milestone,
                 due_date: 1.day.ago,
                 project: project1)
        end
      end
      let(:start_date_notification) do
        create(:notification,
               reason: :date_alert_start_date,
               recipient:,
               resource: starting_soon_work_package,
               read_ian: false)
      end
      let(:due_date_notification) do
        create(:notification,
               reason: :date_alert_due_date,
               recipient:,
               resource: ending_soon_work_package,
               read_ian: false)
      end
      let(:overdue_date_notification) do
        create(:notification,
               reason: :date_alert_due_date,
               recipient:,
               resource: overdue_milestone_work_package,
               read_ian: false)
      end

      let(:notifications) do
        [notification, start_date_notification, due_date_notification, overdue_date_notification]
      end

      it "displays the date alerts; allows reading and filtering them" do
        visit home_path
        wait_for_reload
        center.open
        # Three date alerts and the standard (created) notification
        center.expect_bell_count 4
        center.expect_work_package_item notification
        center.expect_work_package_item start_date_notification
        center.expect_work_package_item due_date_notification
        center.expect_work_package_item overdue_date_notification

        # Reading one will update the unread notification list
        center.mark_notification_as_read start_date_notification
        wait_for_network_idle

        center.expect_bell_count 3

        # Filtering for only date alert notifications (that are unread)
        side_menu.click_item "Date alert"
        wait_for_reload

        center.expect_work_package_item due_date_notification
        center.expect_work_package_item overdue_date_notification
        center.expect_no_item(notification, start_date_notification)

        # do not open a toaster if the notification is not part of the current filters
        create(:notification,
               reason: :mentioned,
               recipient:,
               resource: overdue_milestone_work_package)

        # We need to wait for the bell to poll for updates
        sleep 15
        center.expect_no_toaster
      end
    end

    it "opens the next notification after marking one as read" do
      visit home_path
      wait_for_reload
      center.expect_bell_count 2
      center.open

      center.click_item notification
      split_screen.expect_open

      # Marking the first notification as read (via icon on the notification row)
      center.mark_notification_as_read notification
      wait_for_network_idle

      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      # The second is automatically opened in the split screen
      split_screen2.expect_open

      # When marking the second as closed (via the icon in the split screen)
      # the empty state is shown
      split_screen2.mark_notifications_as_read
      wait_for_network_idle

      retry_block do
        notification.reload
        raise "Expected notification to be marked read" unless notification.read_ian
      end

      center.expect_no_item notification
      center.expect_no_item notification2

      center.expect_empty
    end

    context "with multiple notifications per work package" do
      # In this context we have four notifications for two work packages.
      let(:notification3) do
        work_package2.journal_notes = "A new notification is created here on wp 2"
        work_package2.save!

        # Will have been created via the JOURNAL_CREATED event listeners
        work_package2.journals.last.notifications.first
      end
      let(:notification4) do
        work_package.journal_notes = "Another notification is created here on wp 1"
        work_package.save!

        # Will have been created via the JOURNAL_CREATED event listeners
        work_package.journals.last.notifications.first
      end

      let(:notifications) do
        [notification, notification2, notification3, notification4]
      end

      it "aggregates notifications per work package and sets all as read when opened" do
        visit home_path
        wait_for_reload
        center.expect_bell_count 4
        center.open

        center.expect_number_of_notifications 2

        # Click on first list item, which should be the youngest notification
        center.click_item notification4

        split_screen.expect_open
        center.mark_notification_as_read notification4
        wait_for_network_idle

        retry_block do
          notification4.reload
          raise "Expected notification to be marked read" unless notification4.read_ian
        end

        expect(notification.reload.read_ian).to be_truthy
        expect(notification2.reload.read_ian).to be_falsey
        expect(notification3.reload.read_ian).to be_falsey
        expect(notification4.reload.read_ian).to be_truthy

        # Click on second list item, which should be the youngest notification that does
        # not belong to the work package that represents the first list item.
        center.click_item notification3

        split_screen2.expect_open
        center.mark_notification_as_read notification3
        wait_for_network_idle
        retry_block do
          notification3.reload
          raise "Expected notification to be marked read" unless notification3.read_ian
        end

        expect(notification2.reload.read_ian).to be_truthy
        expect(notification3.reload.read_ian).to be_truthy
      end
    end
  end

  describe "logging into deep link", with_settings: { login_required: true } do
    it "redirects to the notification deep link" do
      visit notifications_center_path(state: "details/#{work_package.id}/activity")

      expect(page).to have_current_path /login/

      login_with recipient.login, "adminADMIN!", visit_signin_path: false

      expect(page).to have_current_path /notifications\/details\/#{work_package.id}\/activity/
    end
  end
end
