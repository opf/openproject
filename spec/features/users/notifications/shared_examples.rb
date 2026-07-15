# frozen_string_literal: true

RSpec.shared_examples "notification settings workflow" do
  describe "with another project the user can see",
           with_ee: %i[date_alerts] do
    shared_let(:project) { create(:project) }
    shared_let(:project_alt) { create(:project) }
    shared_let(:role) { create(:project_role, permissions: %i[view_project]) }
    shared_let(:member) { create(:member, user:, project:, roles: [role]) }
    shared_let(:member_two) { create(:member, user:, project: project_alt, roles: [role]) }

    it "allows to control notification settings" do
      # Expect default settings
      settings_page.expect_represented

      # Set settings for global email
      settings_page.configure_global assignee: true,
                                     responsible: true,
                                     shared: true
      settings_page.save_participating

      settings_page.configure_global work_package_commented: true,
                                     work_package_created: true,
                                     work_package_processed: true,
                                     work_package_prioritized: true,
                                     work_package_scheduled: true
      settings_page.save_non_participating

      # Set settings for global date alerts
      settings_page.set_reminder("start_date", "3 days before")
      settings_page.enable_date_alert("overdue", true)
      settings_page.set_reminder("overdue", "7 days after")

      settings_page.save_date_alerts

      # Set settings for project email
      settings_page.configure_project project:,
                                      assignee: true,
                                      responsible: true,
                                      shared: true,
                                      work_package_commented: false,
                                      work_package_created: false,
                                      work_package_processed: false,
                                      work_package_prioritized: false,
                                      work_package_scheduled: false

      # Set settings for project date alerts
      settings_page.set_project_reminder("start_date", "3 days before")
      settings_page.set_project_reminder("due_date", "3 days before")
      settings_page.set_project_reminder("overdue", "7 days after")

      settings_page.save_project

      notification_settings = user.reload.notification_settings
      expect(notification_settings.count).to eq 2
      expect(notification_settings.where(project: nil).count).to eq(1)
      expect(notification_settings.where(project:).count).to eq 1

      global_settings = notification_settings.find_by(project: nil)
      expect(global_settings.assignee).to be_truthy
      expect(global_settings.responsible).to be_truthy
      expect(global_settings.mentioned).to be_truthy
      expect(global_settings.watched).to be_truthy
      expect(global_settings.shared).to be_truthy
      expect(global_settings.work_package_commented).to be_truthy
      expect(global_settings.work_package_created).to be_truthy
      expect(global_settings.work_package_processed).to be_truthy
      expect(global_settings.work_package_prioritized).to be_truthy
      expect(global_settings.work_package_scheduled).to be_truthy
      expect(global_settings.start_date).to eq(3)
      expect(global_settings.due_date).to eq(1)
      expect(global_settings.overdue).to eq(7)

      project_settings = notification_settings.find_by(project:)
      expect(project_settings.assignee).to be_truthy
      expect(project_settings.responsible).to be_truthy
      expect(project_settings.mentioned).to be_truthy
      expect(project_settings.watched).to be_truthy
      expect(project_settings.shared).to be_truthy
      expect(project_settings.work_package_commented).to be_falsey
      expect(project_settings.work_package_created).to be_falsey
      expect(project_settings.work_package_processed).to be_falsey
      expect(project_settings.work_package_prioritized).to be_falsey
      expect(project_settings.work_package_scheduled).to be_falsey
      expect(project_settings.start_date).to eq(3)
      expect(project_settings.due_date).to eq(3)
      expect(project_settings.overdue).to eq(7)

      # Unset global date alert settings
      settings_page.enable_date_alert("start_date", false)
      settings_page.enable_date_alert("overdue", false)
      settings_page.enable_date_alert("due_date", false)

      settings_page.save_date_alerts

      # Unset project date alert settings
      settings_page.edit_project project
      settings_page.disable_project_date_alert("start_date")
      settings_page.disable_project_date_alert("due_date")
      settings_page.disable_project_date_alert("overdue")

      settings_page.save_project

      notification_settings = user.reload.notification_settings
      expect(notification_settings.count).to eq 2
      expect(notification_settings.where(project: nil).count).to eq(1)
      expect(notification_settings.where(project:).count).to eq 1

      global_settings = notification_settings.find_by(project: nil)
      expect(global_settings.start_date).to be_nil
      expect(global_settings.due_date).to be_nil
      expect(global_settings.overdue).to be_nil

      project_settings = notification_settings.find_by(project:)
      expect(project_settings.start_date).to be_nil
      expect(project_settings.due_date).to be_nil
      expect(project_settings.overdue).to be_nil

      # Trying to add the same project again will not be possible (Regression #38072)
      click_link "Add project-specific notifications"
      container = page.find('[data-test-selector="my-notifications-project-autocompleter"] ng-select')
      settings_page.search_autocomplete container, query: project.name, results_selector: "body"
      expect(page).to have_no_css(".ng-option", text: project.name)
    end

    it "deletes project-specific notification settings without a routing error" do
      create(:notification_setting, user:, project:)
      settings_page.visit!

      settings_page.delete_project project
      settings_page.expect_and_dismiss_flash

      expect(page).to have_current_path(settings_page.path)
      expect(user.reload.notification_settings.where(project:)).to be_empty
      expect(page).to have_no_test_selector("project-specific-settings-list", text: project.name)
    end

    context "when overdue alerts are disabled for one project, enabled for another" do
      let!(:setting) { build(:notification_setting, user:, project:) }
      let!(:setting_alt) { build(:notification_setting, user:, project: project_alt) }
      let(:mail_settings_page) { Pages::My::Reminders.new(user) }

      it "allows to save with a partially disabled overdue alert" do
        setting.start_date = nil
        setting.due_date = nil
        setting.save!

        setting_alt.start_date = 1
        setting_alt.due_date = 1
        setting_alt.save!

        mail_settings_page.visit!
        mail_settings_page.save_daily_reminders_form
        mail_settings_page.expect_and_dismiss_flash
      end
    end

    context "without enterprise", with_ee: false do
      it "does not render the date alerts" do
        # Expect default settings
        settings_page.expect_represented

        # Expect no date alert fields
        settings_page.expect_no_date_alert_setting("start_date")
        settings_page.expect_no_date_alert_setting("due_date")
        settings_page.expect_no_date_alert_setting("overdue")

        # Add projects columns
        settings_page.add_project project

        settings_page.expect_no_project_date_alert_setting("start_date")
        settings_page.expect_no_project_date_alert_setting("due_date")
        settings_page.expect_no_project_date_alert_setting("overdue")
      end
    end
  end
end
