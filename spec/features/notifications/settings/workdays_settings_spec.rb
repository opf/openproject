require "spec_helper"

RSpec.describe "Workday notification settings", :js, :with_cuprite do
  shared_examples "workday settings" do
    before do
      current_user.language = locale
      current_user.save! && pref.save!
    end

    context "with english locale" do
      let(:locale) { :en }

      it "allows to configure the workdays" do
        # Configure the reminders
        settings_page.visit!

        settings_page.expect_workdays %w[Monday Tuesday Wednesday Thursday Friday]
        settings_page.expect_non_workdays %w[Saturday Sunday]

        settings_page.set_workdays Monday: true,
                                   Tuesday: true,
                                   Wednesday: false,
                                   Thursday: false,
                                   Friday: true,
                                   Saturday: true,
                                   Sunday: true

        settings_page.save

        settings_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

        settings_page.reload!

        settings_page.expect_workdays %w[Monday Tuesday Friday Saturday Sunday]
        settings_page.expect_non_workdays %w[Wednesday Thursday]

        expect(pref.reload.workdays).to eq [1, 2, 5, 6, 7]
      end

      it "can unselect all working days" do
        # Configure the reminders
        settings_page.visit!

        settings_page.expect_workdays %w[Monday Tuesday Wednesday Thursday Friday]
        settings_page.expect_non_workdays %w[Saturday Sunday]

        settings_page.set_workdays Monday: false,
                                   Tuesday: false,
                                   Wednesday: false,
                                   Thursday: false,
                                   Friday: false,
                                   Saturday: false,
                                   Sunday: false

        settings_page.save

        settings_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_update"))

        settings_page.reload!

        settings_page.expect_non_workdays %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

        expect(pref.reload.workdays).to eq []
      end
    end

    context "with german locale" do
      let(:locale) { :de }

      it "allows to configure the workdays" do
        I18n.locale = :de

        # Configure the reminders
        settings_page.visit!

        # Expect Mo-Fr to be checked
        settings_page.expect_workdays %w[Montag Dienstag Mittwoch Donnerstag Freitag]
        settings_page.expect_non_workdays %w[Samstag Sonntag]

        settings_page.set_workdays Montag: true,
                                   Dienstag: true,
                                   Mittwoch: false,
                                   Donnerstag: false,
                                   Freitag: true,
                                   Samstag: true,
                                   Sonntag: false

        settings_page.save

        settings_page.expect_and_dismiss_toaster message: I18n.t("js.notice_successful_update")

        settings_page.reload!

        settings_page.expect_workdays %w[Montag Dienstag Freitag Samstag]
        settings_page.expect_non_workdays %w[Mittwoch Donnerstag Sonntag]

        expect(pref.reload.workdays).to eq [1, 2, 5, 6]
      end
    end

    context "with Chinese Simplified locale and start of week setting defined",
            with_settings: {
              start_of_week: 1,
              first_week_of_year: 1
            } do
      let(:locale) { "zh-CN" }

      it "displays week days in Chinese (bug #49848)" do
        settings_page.visit!

        I18n.t("date.day_names", locale:).map(&:strip).each do |day_name|
          expect(page).to have_field(day_name)
        end
      end
    end
  end

  context "with the my page" do
    let(:settings_page) { Pages::My::Reminders.new(current_user) }
    let(:pref) { current_user.pref }

    current_user do
      create(:user)
    end

    it_behaves_like "workday settings"
  end

  context "with the user administration page" do
    let(:settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { create(:user) }
    let(:pref) { other_user.pref }

    current_user do
      create(:admin)
    end

    it_behaves_like "workday settings"
  end
end
