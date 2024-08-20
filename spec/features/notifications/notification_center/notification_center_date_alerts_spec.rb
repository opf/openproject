require "spec_helper"
require "features/page_objects/notification"

# rubocop:disable RSpec/ScatteredLet
RSpec.describe "Notification center date alerts", :js, :with_cuprite,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  # Find an assignable time zone with the same UTC offset as the local time zone
  def find_compatible_local_time_zone
    local_offset = Time.now.gmt_offset # rubocop:disable Rails/TimeZone
    time_zone = UserPreferences::UpdateContract.assignable_time_zones
                                               .find { |tz| tz.now.utc_offset == local_offset }
    time_zone or raise "Unable to find an assignable time zone with #{local_offset} seconds offset."
  end

  shared_let(:time_zone) { find_compatible_local_time_zone }
  shared_let(:user) do
    create(:user, preferences: { time_zone: time_zone.tzinfo.canonical_zone.name }).tap do |user|
      user.notification_settings.first.update(
        start_date: 7,
        due_date: 3,
        overdue: 1
      )
    end
  end
  shared_let(:project) { create(:project_with_types) }
  shared_let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages work_package_assigned]) }
  shared_let(:membership) { create(:member, principal: user, project:, roles: [role]) }
  shared_let(:milestone_type) { create(:type_milestone) }

  def create_alertable(**attributes)
    attributes = attributes.reverse_merge(assigned_to: user, project:)
    work_package = create(:work_package, **attributes)

    # TimeCop sets the current time to 1:04h below. To be compatible to historic searches,
    # we need to pretend that the journal records have been created before that time.
    # https://github.com/opf/openproject/pull/11678#issuecomment-1328011996
    #
    work_package.journals.update_all created_at: time_zone.now.change(hour: 0, minute: 0)
    work_package
  end

  # notification will be created by the job because `overdue: 1` in user notifications settings
  shared_let(:milestone_wp_past) do
    create_alertable(subject: "Milestone WP past", type: milestone_type, due_date: time_zone.today - 2.days)
  end

  shared_let(:milestone_wp_future) do
    create_alertable(subject: "Milestone WP future", type: milestone_type, due_date: time_zone.today + 1.day)
  end

  shared_let(:wp_start_past) do
    create_alertable(subject: "WP start past", start_date: time_zone.today - 1.day)
  end
  # notification will be created by job because `start_date: 7` in user notifications settings
  shared_let(:wp_start_future) do
    create_alertable(subject: "WP start future", start_date: time_zone.today + 7.days)
  end

  # notification will be created by job because `overdue: 1` in user notifications settings
  shared_let(:wp_due_past) do
    create_alertable(subject: "WP due past", due_date: time_zone.today - 3.days)
  end
  # notification will be created by job because `due_date: 3` in user notifications settings
  shared_let(:wp_due_future) do
    create_alertable(subject: "WP due future", due_date: time_zone.today + 3.days)
  end

  shared_let(:wp_double_notification) do
    create_alertable(subject: "Alert + Mention", due_date: time_zone.today + 1.day)
  end

  shared_let(:wp_unset_date) do
    create_alertable(subject: "Unset date", due_date: nil)
  end

  shared_let(:wp_due_today) do
    create_alertable(subject: "Due today", due_date: time_zone.today)
  end

  shared_let(:wp_double_alert) do
    create_alertable(subject: "Double alert", start_date: time_zone.today - 1.day, due_date: time_zone.today + 1.day)
  end

  # notification created by CreateDateAlertsNotificationsJob
  let(:notification_milestone_past) do
    Notification.find_by(reason: "date_alert_due_date", resource: milestone_wp_past)
  end

  shared_let(:notification_milestone_future) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: milestone_wp_future)
  end

  shared_let(:notification_wp_start_past) do
    create(:notification,
           reason: :date_alert_start_date,
           recipient: user,
           resource: wp_start_past)
  end

  # notification created by CreateDateAlertsNotificationsJob
  let(:notification_wp_start_future) do
    Notification.find_by(reason: "date_alert_start_date", resource: wp_start_future)
  end

  # notification created by CreateDateAlertsNotificationsJob
  let(:notification_wp_due_past) do
    Notification.find_by(reason: "date_alert_due_date", resource: wp_due_past)
  end

  # notification created by CreateDateAlertsNotificationsJob
  let(:notification_wp_due_future) do
    Notification.find_by(reason: "date_alert_due_date", resource: wp_due_future)
  end

  shared_let(:notification_wp_double_date_alert) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_double_notification)
  end

  shared_let(:notification_wp_double_mention) do
    create(:notification,
           reason: :mentioned,
           recipient: user,
           resource: wp_double_notification)
  end

  shared_let(:notification_wp_double_alerts) do
    due = create(:notification,
                 reason: :date_alert_due_date,
                 recipient: user,
                 resource: wp_double_alert)

    start = create(:notification,
                   reason: :date_alert_start_date,
                   recipient: user,
                   resource: wp_double_alert)

    [start, due]
  end

  shared_let(:notification_wp_unset_date) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_unset_date)
  end

  shared_let(:notification_wp_due_today) do
    create(:notification,
           reason: :date_alert_due_date,
           recipient: user,
           resource: wp_due_today)
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:side_menu) { Components::Submenu.new }
  let(:toaster) { PageObjects::Notifications.new(page) }
  let(:activity_tab) { Components::WorkPackages::Activities.new(notification_wp_due_today) }

  # Converts "hh:mm" into { hour: h, min: m }
  def time_hash(time)
    %i[hour min].zip(time.split(":", 2).map(&:to_i)).to_h
  end

  def timezone_time(time, timezone)
    timezone.now.change(time_hash(time))
  end

  # early in the morning, a bit after 1:00 AM local time, the notifications get
  # created by the job
  let(:notifications_creation_time) { timezone_time("1:04", time_zone) }

  def run_create_date_alerts_notifications_job
    create_date_alerts_service = Notifications::ScheduleDateAlertsNotificationsJob::Service
                                   .new([timezone_time("1:00", time_zone)])
    travel_to(notifications_creation_time)
    create_date_alerts_service.call
    travel_back
  end

  before do
    run_create_date_alerts_notifications_job
    perform_enqueued_jobs
    login_as user
    visit notifications_center_path
    wait_for_reload
  end

  context "without date alerts ee" do
    it "shows the upsale page" do
      side_menu.click_item "Date alert"

      expect(page).to have_current_path /notifications\/date_alerts/
      expect(page).to have_text "Date alerts is an Enterprise"
      expect(page).to have_text "Please upgrade to a paid plan "

      # It does not allows direct url access
      visit notifications_center_path(filter: "reason", name: "dateAlert")
      toaster.expect_error("Filters Reason filter has invalid values.")
    end
  end

  context "with date alerts ee", with_ee: %i[date_alerts] do
    it "shows the date alerts according to specification" do
      center.expect_item(notification_wp_start_past, "Start date was 1 day ago")
      center.expect_item(notification_wp_start_future, "Start date is in 7 days")

      center.expect_item(notification_wp_due_past, "Overdue since 3 days")
      center.expect_item(notification_wp_due_future, "Finish date is in 3 days")

      center.expect_item(notification_milestone_past, "Overdue since 2 days")
      center.expect_item(notification_milestone_future, "Milestone date is in 1 day")

      center.expect_item(notification_wp_unset_date, "Finish date is deleted")

      center.expect_item(notification_wp_due_today, "Finish date is today")

      # Doesn't show the date alert for the mention, not the alert
      center.expect_item(notification_wp_double_mention, /(seconds|minutes) ago by Anonymous/)
      center.expect_no_item(notification_wp_double_date_alert)

      # When switch to date alerts, it shows the alert, no longer the mention
      side_menu.click_item "Date alert"
      wait_for_network_idle
      center.expect_item(notification_wp_double_date_alert, "Finish date is in 1 day")
      center.expect_no_item(notification_wp_double_mention)

      # Ensure that start is created later than due for implicit ID sorting
      double_alert_start, double_alert_due = notification_wp_double_alerts
      expect(double_alert_start.id).to be > double_alert_due.id

      # We see that start is actually the newest ID, hence shown as the primary notification
      # but the date alert still shows the finish date
      center.expect_item(double_alert_start, "Finish date is in 1 day")
      center.expect_no_item(double_alert_due)

      # Opening a date alert opens in overview
      center.click_item notification_wp_start_past
      split_screen = Pages::SplitWorkPackage.new wp_start_past
      split_screen.expect_tab :overview
      wait_for_network_idle

      # We expect no badge count
      activity_tab.expect_no_notification_badge

      # The same is true for the mention item that is opened in date alerts filter
      center.click_item notification_wp_double_date_alert
      split_screen = Pages::SplitWorkPackage.new wp_double_notification
      split_screen.expect_tab :overview
      wait_for_network_idle

      # We expect one badge
      activity_tab.expect_notification_count 1

      # When a work package is updated to a different date
      wp_double_notification.update_column(:due_date, time_zone.now + 5.days)
      page.driver.refresh
      wait_for_reload

      center.expect_item(notification_wp_double_date_alert, "Finish date is in 5 days")
      center.expect_no_item(notification_wp_double_mention)
    end
  end
end
# rubocop:enable RSpec/ScatteredLet
