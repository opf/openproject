require 'spec_helper'

describe "Notification center date alerts", js: true, with_settings: { journal_aggregation_time_minutes: 0 } do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) { project_with_types }
  shared_let(:role) { create :role, permissions: %i[view_work_packages edit_work_packages work_package_assigned] }
  shared_let(:membership) { create :member, principal: user, project: project_with_types, roles: [role] }
  shared_let(:milestone_type) { create :type_milestone }

  shared_let(:milestone_wp_past) { create :work_package, project:, type: milestone_type, due_date: 2.days.ago }
  shared_let(:milestone_wp_future) { create :work_package, project:, type: milestone_type, due_date: 1.day.from_now }

  shared_let(:wp_start_past) { create :work_package, project:, start_date: 1.day.ago }
  shared_let(:wp_start_future) { create :work_package, project:, start_date: 2.days.from_now }

  shared_let(:wp_due_past) { create :work_package, project:, due_date: 3.days.ago }
  shared_let(:wp_due_future) { create :work_package, project:, due_date: 3.days.from_now }

  shared_let(:wp_double_notification) { create :work_package, project:, due_date: 1.days.from_now }

  shared_let(:notification_milestone_past) do
    create :notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: milestone_wp_past,
           project:
  end

  shared_let(:notification_milestone_future) do
    create :notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: milestone_wp_future,
           project:
  end

  shared_let(:notification_wp_start_past) do
    create :notification,
           reason: :date_alert_start_date,
           recipient: user,
           resource: wp_start_past,
           project:
  end

  shared_let(:notification_wp_start_future) do
    create :notification,
           reason: :date_alert_start_date,
           recipient: user,
           resource: wp_start_future,
           project:
  end

  shared_let(:notification_wp_due_past) do
    create :notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_due_past,
           project:
  end

  shared_let(:notification_wp_due_future) do
    create :notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_due_future,
           project:
  end

  shared_let(:notification_wp_double_date_alert) do
    create :notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_double_notification,
           project:
  end

  shared_let(:notification_wp_double_mention) do
    create :notification,
           reason: :mentioned,
           recipient: user,
           resource: wp_double_notification,
           project:
  end

  let(:center) { ::Pages::Notifications::Center.new }
  let(:side_menu) { ::Components::Notifications::Sidemenu.new }

  before do
    login_as user
    visit notifications_center_path
  end

  it 'shows the date alerts according to specification' do
    center.expect_item(notification_wp_start_past, 'Start date was 1 day ago')
    center.expect_item(notification_wp_start_future, 'Start date is in 2 days')

    center.expect_item(notification_wp_due_past, 'Overdue since 3 days')
    center.expect_item(notification_wp_due_future, 'Finish date is in 3 days')

    center.expect_item(notification_milestone_past, 'Overdue since 2 days')
    center.expect_item(notification_milestone_future, 'Finish date is in 1 day')

    # Doesn't show the date alert for the mention, not the alert
    center.expect_item(notification_wp_double_mention, /(seconds|minutes) ago by Anonymous/)
    center.expect_no_item(notification_wp_double_date_alert)

    # When switch to date alerts, it shows the alert, no longer the mention
    side_menu.click_item 'Date alert'
    center.expect_item(notification_wp_double_date_alert, 'Finish date is in 1 day')
    center.expect_no_item(notification_wp_double_mention)

    # When a work package is updated to a different date
    wp_double_notification.update_column(:due_date, 5.days.from_now)
    page.driver.refresh

    center.expect_item(notification_wp_double_date_alert, 'Finish date is in 5 days')
    center.expect_no_item(notification_wp_double_mention)
  end
end
