require 'spec_helper'

describe "Notification center date alerts", js: true, with_settings: { journal_aggregation_time_minutes: 0 } do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) { project_with_types }
  shared_let(:role) { create(:role, permissions: %i[view_work_packages edit_work_packages work_package_assigned]) }
  shared_let(:membership) { create(:member, principal: user, project: project_with_types, roles: [role]) }
  shared_let(:milestone_type) { create(:type_milestone) }

  shared_let(:milestone_wp_past) do
    create(:work_package, subject: 'Milestone WP past', project:, type: milestone_type, due_date: 2.days.ago)
  end
  shared_let(:milestone_wp_future) do
    create(:work_package, subject: 'Milestone WP future', project:, type: milestone_type, due_date: 1.day.from_now)
  end

  shared_let(:wp_start_past) { create(:work_package, subject: 'WP start past', project:, start_date: 1.day.ago) }
  shared_let(:wp_start_future) { create(:work_package, subject: 'WP start future', project:, start_date: 2.days.from_now) }

  shared_let(:wp_due_past) { create(:work_package, subject: 'WP due past', project:, due_date: 3.days.ago) }
  shared_let(:wp_due_future) { create(:work_package, subject: 'WP due future', project:, due_date: 3.days.from_now) }

  shared_let(:wp_double_notification) { create(:work_package, subject: 'Alert + Mention', project:, due_date: 1.day.from_now) }

  shared_let(:wp_unset_date) { create(:work_package, subject: 'Unset date', project:, due_date: nil) }

  shared_let(:wp_double_alert) do
    create(:work_package, subject: 'Double alert', project:, start_date: 1.day.ago, due_date: 1.day.from_now)
  end

  shared_let(:notification_milestone_past) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: milestone_wp_past,
           project:)
  end

  shared_let(:notification_milestone_future) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: milestone_wp_future,
           project:)
  end

  shared_let(:notification_wp_start_past) do
    create(:notification,
           reason: :date_alert_start_date,
           recipient: user,
           resource: wp_start_past,
           project:)
  end

  shared_let(:notification_wp_start_future) do
    create(:notification,
           reason: :date_alert_start_date,
           recipient: user,
           resource: wp_start_future,
           project:)
  end

  shared_let(:notification_wp_due_past) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_due_past,
           project:)
  end

  shared_let(:notification_wp_due_future) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_due_future,
           project:)
  end

  shared_let(:notification_wp_double_date_alert) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_double_notification,
           project:)
  end

  shared_let(:notification_wp_double_mention) do
    create(:notification,
           reason: :mentioned,
           recipient: user,
           resource: wp_double_notification,
           project:)
  end

  shared_let(:notification_wp_double_alerts) do
    due = create(:notification,
                 reason: :date_alert_due_date,
                 recipient: user,
                 resource: wp_double_alert,
                 project:)

    start = create(:notification,
                   reason: :date_alert_start_date,
                   recipient: user,
                   resource: wp_double_alert,
                   project:)

    [start, due]
  end

  shared_let(:notification_wp_unset_date) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_unset_date,
           project:)
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
    center.expect_item(notification_milestone_future, 'Milestone date is in 1 day')

    center.expect_item(notification_wp_unset_date, 'Finish date is deleted')

    # Doesn't show the date alert for the mention, not the alert
    center.expect_item(notification_wp_double_mention, /(seconds|minutes) ago by Anonymous/)
    center.expect_no_item(notification_wp_double_date_alert)

    # When switch to date alerts, it shows the alert, no longer the mention
    side_menu.click_item 'Date alert'
    center.expect_item(notification_wp_double_date_alert, 'Finish date is in 1 day')
    center.expect_no_item(notification_wp_double_mention)

    # Ensure that start is created later than due for implicit ID sorting
    double_alert_start, double_alert_due = notification_wp_double_alerts
    expect(double_alert_start.id).to be > double_alert_due.id

    # We see that start is actually the newest ID, hence shown as the primary notification
    # but the date alert still shows the finish date
    center.expect_item(double_alert_start, 'Finish date is in 1 day')
    center.expect_no_item(double_alert_due)

    # When a work package is updated to a different date
    wp_double_notification.update_column(:due_date, 5.days.from_now)
    page.driver.refresh

    center.expect_item(notification_wp_double_date_alert, 'Finish date is in 5 days')
    center.expect_no_item(notification_wp_double_mention)
  end
end
