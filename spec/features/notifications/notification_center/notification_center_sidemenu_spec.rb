require 'spec_helper'

describe "Notification center sidemenu", type: :feature, js: true do
  shared_let(:project) { create :project }
  shared_let(:project2) { create :project }
  shared_let(:project3) { create :project, parent: project2 }

  shared_let(:recipient) do
    create :user,
                      member_in_projects: [project, project2, project3],
                      member_with_permissions: %i[view_work_packages]
  end
  shared_let(:other_user) { create(:user) }

  shared_let(:work_package) { create :work_package, project: project, author: other_user }
  shared_let(:work_package2) { create :work_package, project: project2, author: other_user }
  shared_let(:work_package3) { create :work_package, project: project3, author: other_user }
  shared_let(:work_package4) { create :work_package, project: project3, author: other_user }

  let(:notification) do
    create :notification,
                      recipient: recipient,
                      project: project,
                      resource: work_package,
                      reason: :watched
  end

  let(:notification2) do
    create :notification,
                      recipient: recipient,
                      project: project2,
                      resource: work_package2,
                      reason: :assigned
  end

  let(:notification3) do
    create :notification,
                      recipient: recipient,
                      project: project3,
                      resource: work_package3,
                      reason: :responsible
  end

  let(:notification4) do
    create :notification,
                      recipient: recipient,
                      project: project3,
                      resource: work_package4,
                      reason: :mentioned
  end

  let(:notifications) do
    [notification, notification2, notification3, notification4]
  end

  let(:center) { ::Pages::Notifications::Center.new }
  let(:side_menu) { ::Components::Notifications::Sidemenu.new }

  before do
    notifications
    login_as recipient
    center.visit!
  end

  context 'with no notifications to show' do
    let(:notifications) { nil }

    it 'still shows the sidebar and a placeholder' do
      side_menu.expect_open

      expect(page).to have_text 'New notifications will appear here when there is activity that concerns you'

      center.expect_no_toaster

      side_menu.expect_item_with_no_count 'Inbox'
      side_menu.expect_item_with_no_count 'Assigned'
      side_menu.expect_item_with_no_count '@mentioned'
      side_menu.expect_item_with_no_count 'Accountable'
      side_menu.expect_item_with_no_count 'Watching'
    end
  end

  it 'updates the numbers when a notification is read' do
    side_menu.expect_open

    # Expect standard filters
    side_menu.expect_item_with_count 'Inbox', 4
    side_menu.expect_item_with_count 'Assigned', 1
    side_menu.expect_item_with_count '@mentioned', 1
    side_menu.expect_item_with_count 'Accountable', 1
    side_menu.expect_item_with_count 'Watching', 1

    # Expect project filters
    side_menu.expect_item_with_count project.name, 1
    side_menu.expect_item_with_count project2.name, 1
    side_menu.expect_item_with_count "... #{project3.name}", 2

    # Reading a notification...
    center.mark_notification_as_read notification

    # ...  will change the filter counts
    side_menu.expect_item_with_count 'Inbox', 3
    side_menu.expect_item_with_count 'Assigned', 1
    side_menu.expect_item_with_count '@mentioned', 1
    side_menu.expect_item_with_count 'Accountable', 1
    side_menu.expect_item_with_no_count 'Watching'

    # ... and show only those projects with a notification
    side_menu.expect_item_not_visible project.name
    side_menu.expect_item_with_count project2.name, 1
    side_menu.expect_item_with_count "... #{project3.name}", 2

    # Empty filter sets have a separate message
    side_menu.click_item 'Watching'
    side_menu.finished_loading
    expect(page).to have_text 'There are no notifications in this view at the moment'

    # Marking all as read
    side_menu.click_item 'Inbox'
    side_menu.finished_loading
    center.mark_all_read
    side_menu.expect_item_with_no_count 'Inbox'
    side_menu.expect_item_with_no_count 'Assigned'
    side_menu.expect_item_with_no_count '@mentioned'
    side_menu.expect_item_with_no_count 'Accountable'
    side_menu.expect_item_with_no_count 'Watching'

    side_menu.expect_item_not_visible project.name
    side_menu.expect_item_not_visible project2.name
    side_menu.expect_item_not_visible "... #{project3.name}"
  end

  it 'updates the content when a filter is clicked' do
    # All notifications are shown
    center.expect_work_package_item notification, notification2, notification3, notification4

    # Filter for "Watching"
    side_menu.click_item 'Watching'
    side_menu.finished_loading
    center.expect_work_package_item notification
    center.expect_no_item notification2, notification3, notification4

    # Filter for "Assignee"
    side_menu.click_item 'Assigned'
    side_menu.finished_loading
    center.expect_work_package_item notification2
    center.expect_no_item notification, notification3, notification4

    # Filter for "Accountable"
    side_menu.click_item 'Accountable'
    side_menu.finished_loading
    center.expect_work_package_item notification3
    center.expect_no_item notification, notification2, notification4

    # Filter for "@mentioned"
    side_menu.click_item '@mentioned'
    side_menu.finished_loading
    center.expect_work_package_item notification4
    center.expect_no_item notification, notification2, notification3

    # Filter for project1
    side_menu.click_item project.name
    side_menu.finished_loading
    center.expect_work_package_item notification
    center.expect_no_item notification2, notification3, notification4

    # Filter for project3
    side_menu.click_item "... #{project3.name}"
    side_menu.finished_loading
    center.expect_work_package_item notification3, notification4
    center.expect_no_item notification, notification2

    # Reset by clicking on the Inbox
    side_menu.click_item 'Inbox'
    side_menu.finished_loading
    center.expect_work_package_item notification, notification2, notification3, notification4
  end
end
