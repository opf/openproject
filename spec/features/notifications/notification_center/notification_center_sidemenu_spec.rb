require "spec_helper"

RSpec.describe "Notification center sidemenu",
               :js,
               :with_cuprite,
               with_ee: %i[date_alerts work_package_sharing] do
  shared_let(:project) { create(:project) }
  shared_let(:project2) { create(:project) }
  shared_let(:project3) { create(:project, parent: project2) }

  shared_let(:recipient) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages],
             project2 => %i[view_work_packages],
             project3 => %i[view_work_packages]
           })
  end
  shared_let(:other_user) { create(:user) }

  shared_let(:work_package) { create(:work_package, project:, author: other_user) }
  shared_let(:work_package2) { create(:work_package, project: project2, author: other_user) }
  shared_let(:work_package3) { create(:work_package, project: project3, author: other_user) }
  shared_let(:work_package4) { create(:work_package, project: project3, author: other_user) }
  shared_let(:work_package5) { create(:work_package, :is_milestone, project: project3, author: other_user) }
  shared_let(:work_package6) { create(:work_package, :is_milestone, project: project3, author: other_user) }

  let(:notification_watched) do
    create(:notification,
           recipient:,
           resource: work_package,
           reason: :watched)
  end

  let(:notification_assigned) do
    create(:notification,
           recipient:,
           resource: work_package2,
           reason: :assigned)
  end

  let(:notification_responsible) do
    create(:notification,
           recipient:,
           resource: work_package3,
           reason: :responsible)
  end

  let(:notification_mentioned) do
    create(:notification,
           recipient:,
           resource: work_package4,
           reason: :mentioned)
  end

  let(:notification_date) do
    create(:notification,
           recipient:,
           resource: work_package5,
           reason: :date_alert_start_date)
  end

  let(:notification_shared) do
    create(:notification,
           recipient:,
           resource: work_package6,
           reason: :shared)
  end

  let(:notifications) do
    [notification_watched, notification_assigned, notification_responsible, notification_mentioned, notification_date,
     notification_shared]
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:side_menu) { Components::Submenu.new }

  before do
    notifications
    login_as recipient
    center.visit!
    wait_for_reload
  end

  context "with no notifications to show" do
    let(:notifications) { nil }

    it "still shows the sidebar and a placeholder" do
      side_menu.expect_open

      expect(page).to have_text "New notifications will appear here when there is activity that concerns you"

      center.expect_no_toaster

      side_menu.expect_item_with_no_count "Inbox"
      side_menu.expect_item_with_no_count "Assignee"
      side_menu.expect_item_with_no_count "Mentioned"
      side_menu.expect_item_with_no_count "Accountable"
      side_menu.expect_item_with_no_count "Watcher"
      side_menu.expect_item_with_no_count "Date alert"
      side_menu.expect_item_with_no_count "Shared"
    end
  end

  it "updates the numbers when a notification is read" do
    side_menu.expect_open

    # Expect standard filters
    side_menu.expect_item_with_count "Inbox", 6
    side_menu.expect_item_with_count "Assignee", 1
    side_menu.expect_item_with_count "Mentioned", 1
    side_menu.expect_item_with_count "Accountable", 1
    side_menu.expect_item_with_count "Watcher", 1
    side_menu.expect_item_with_count "Date alert", 1
    side_menu.expect_item_with_count "Shared", 1

    # Expect project filters
    side_menu.expect_item_with_count project.name, 1
    side_menu.expect_item_with_count project2.name, 1
    side_menu.expect_item_with_count "... #{project3.name}", 4

    # Reading a notification...
    center.mark_notification_as_read notification_watched

    # ...  will change the filter counts
    side_menu.expect_item_with_count "Inbox", 5
    side_menu.expect_item_with_count "Assignee", 1
    side_menu.expect_item_with_count "Mentioned", 1
    side_menu.expect_item_with_count "Accountable", 1
    side_menu.expect_item_with_count "Date alert", 1
    side_menu.expect_item_with_count "Shared", 1
    side_menu.expect_item_with_no_count "Watcher"

    # ... and show only those projects with a notification
    side_menu.expect_no_item project.name
    side_menu.expect_item_with_count project2.name, 1
    side_menu.expect_item_with_count "... #{project3.name}", 4

    # Empty filter sets have a separate message
    side_menu.click_item "Watcher"
    side_menu.finished_loading
    expect(page).to have_text "Looks like you are all caught up for this filter"

    # Marking all as read
    side_menu.click_item "Inbox"
    side_menu.finished_loading
    center.mark_all_read
    side_menu.expect_item_with_no_count "Inbox"
    side_menu.expect_item_with_no_count "Assignee"
    side_menu.expect_item_with_no_count "Mentioned"
    side_menu.expect_item_with_no_count "Accountable"
    side_menu.expect_item_with_no_count "Watcher"
    side_menu.expect_item_with_no_count "Date alert"
    side_menu.expect_item_with_no_count "Shared"

    side_menu.expect_no_item project.name
    side_menu.expect_no_item project2.name
    side_menu.expect_no_item "... #{project3.name}"
  end

  it "updates the content when a filter is clicked" do
    # All notifications are shown
    center.expect_work_package_item *notifications

    # Filter for "Watcher"
    side_menu.click_item "Watcher"
    side_menu.finished_loading
    center.expect_work_package_item notification_watched
    center.expect_no_item notification_assigned, notification_responsible, notification_mentioned, notification_date,
                          notification_shared

    # Filter for "Assignee"
    side_menu.click_item "Assignee"
    side_menu.finished_loading
    center.expect_work_package_item notification_assigned
    center.expect_no_item notification_watched, notification_responsible, notification_mentioned, notification_date,
                          notification_shared

    # Filter for "Accountable"
    side_menu.click_item "Accountable"
    side_menu.finished_loading
    center.expect_work_package_item notification_responsible
    center.expect_no_item notification_watched, notification_assigned, notification_mentioned, notification_date,
                          notification_shared

    # Filter for "Mentioned"
    side_menu.click_item "Mentioned"
    side_menu.finished_loading
    center.expect_work_package_item notification_mentioned
    center.expect_no_item notification_watched, notification_assigned, notification_responsible, notification_date,
                          notification_shared

    # Filter for "Date alert"
    side_menu.click_item "Date alert"
    side_menu.finished_loading
    center.expect_work_package_item notification_date
    center.expect_no_item notification_watched, notification_assigned, notification_responsible, notification_mentioned,
                          notification_shared

    # Filter for "Shared"
    side_menu.click_item "Shared"
    side_menu.finished_loading
    center.expect_work_package_item notification_shared
    center.expect_no_item notification_watched, notification_assigned, notification_responsible, notification_mentioned,
                          notification_date

    # Filter for project1
    side_menu.click_item project.name
    side_menu.finished_loading
    center.expect_work_package_item notification_watched
    center.expect_no_item notification_assigned, notification_responsible, notification_mentioned, notification_date,
                          notification_shared

    # Filter for project3
    side_menu.click_item "... #{project3.name}"
    side_menu.finished_loading
    center.expect_work_package_item notification_responsible, notification_mentioned, notification_date, notification_shared
    center.expect_no_item notification_watched, notification_assigned

    # Reset by clicking on the Inbox
    side_menu.click_item "Inbox"
    side_menu.finished_loading
    center.expect_work_package_item *notifications
  end
end
