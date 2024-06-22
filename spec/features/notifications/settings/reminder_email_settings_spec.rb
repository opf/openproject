require "spec_helper"
require_relative "../../users/notifications/shared_examples"

RSpec.describe "Reminder email", :js, :with_cuprite do
  shared_examples "reminder settings" do
    it "allows to configure the reminder settings" do
      # Configure the digest
      reminders_settings_page.visit!

      # By default a reminder timed for 8:00 should be configured
      reminders_settings_page.expect_active_daily_times("08:00 am")

      reminders_settings_page.add_time

      # The next suggested time is taken: 12:00
      reminders_settings_page.expect_active_daily_times("08:00 am", "12:00 pm")

      reminders_settings_page.set_time "Time 2", "03:00 pm"

      reminders_settings_page.expect_active_daily_times("08:00 am", "03:00 pm")

      reminders_settings_page.save

      reminders_settings_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      reminders_settings_page.reload!

      # Deactivate the second time but then remove the first one will activate the second (then only) one
      # so that one time is always enabled.
      reminders_settings_page.expect_active_daily_times("08:00 am", "03:00 pm")
      reminders_settings_page.deactivate_time("Time 2")
      reminders_settings_page.remove_time("Time 1")

      reminders_settings_page.save

      reminders_settings_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      reminders_settings_page.reload!

      reminders_settings_page.expect_active_daily_times("03:00 pm")
    end
  end

  context "when configuring via the my page" do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }

    current_user do
      create(:user)
    end

    it_behaves_like "reminder settings"
  end

  context "when configuring via the user administration page" do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { create(:user) }

    current_user do
      create(:admin)
    end

    it_behaves_like "reminder settings"
  end
end
