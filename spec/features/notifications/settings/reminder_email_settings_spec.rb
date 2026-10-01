# frozen_string_literal: true

require "spec_helper"
require_relative "../../users/notifications/shared_examples"

RSpec.describe "Reminder email", :js do
  shared_examples "reminder settings" do
    it "allows to configure the reminder settings" do
      # Configure the digest
      reminders_settings_page.visit!

      # By default a reminder timed for 8:00 should be configured
      reminders_settings_page.expect_active_daily_times("08:00 AM")

      reminders_settings_page.add_time

      # The next suggested time is taken: 12:00
      reminders_settings_page.expect_active_daily_times("08:00 AM", "12:00 PM")

      reminders_settings_page.set_time "03:00 PM"

      reminders_settings_page.expect_active_daily_times("08:00 AM", "03:00 PM")

      reminders_settings_page.save_daily_reminders_form

      reminders_settings_page.expect_and_dismiss_flash

      reminders_settings_page.reload!

      # Remove the second time. After that the first time cannot be removed,
      # so that one time is always enabled.
      reminders_settings_page.expect_active_daily_times("08:00 AM", "03:00 PM")
      reminders_settings_page.remove_time(1)
      reminders_settings_page.expect_no_remove_time
      reminders_settings_page.expect_active_daily_times("08:00 AM")

      reminders_settings_page.save_daily_reminders_form

      reminders_settings_page.expect_and_dismiss_flash

      reminders_settings_page.reload!

      reminders_settings_page.expect_active_daily_times("03:00 PM")
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
