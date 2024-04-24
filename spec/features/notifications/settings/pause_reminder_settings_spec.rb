require "spec_helper"

RSpec.describe "Pause reminder settings", :js, :with_cuprite do
  shared_examples "pause reminder settings" do
    let(:first) { Time.zone.today.beginning_of_month }
    let(:last) { (Time.zone.today.beginning_of_month + 10.days) }
    it "allows to configure the reminder settings" do
      # Save prefs so we can reload them later
      pref.save!

      # Configure the reminders
      reminders_settings_page.visit!

      # By default the pause reminder is unchecked
      reminders_settings_page.expect_paused false

      reminders_settings_page.set_paused(true,
                                         first:,
                                         last:)

      reminders_settings_page.save

      reminders_settings_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

      reminders_settings_page.reload!

      reminders_settings_page.expect_paused(true,
                                            first:,
                                            last:)

      pref.reload
      expect(pref.pause_reminders[:enabled]).to be true
      expect(pref.pause_reminders[:first_day]).to eq first.iso8601
      expect(pref.pause_reminders[:last_day]).to eq last.iso8601
    end
  end

  context "with the my page" do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }
    let(:pref) { current_user.pref }

    current_user do
      create(:user)
    end

    it_behaves_like "pause reminder settings"
  end

  context "with the user administration page" do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { create(:user) }
    let(:pref) { other_user.pref }

    current_user do
      create(:admin)
    end

    it_behaves_like "pause reminder settings"
  end
end
