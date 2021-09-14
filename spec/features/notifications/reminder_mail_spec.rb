require 'spec_helper'
require_relative '../users/notifications/shared_examples'

describe "Reminder email", type: :feature, js: true do
  shared_examples 'reminder settings' do
    it 'allows to configure the reminder settings' do
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

      reminders_settings_page.expect_and_dismiss_notification(message: I18n.t('js.notice_successful_update'))

      reminders_settings_page.reload!

      # Deactivate the second time but then remove the first one will activate the second (then only) one
      # so that one time is always enabled.
      reminders_settings_page.expect_active_daily_times("08:00 am", "03:00 pm")
      reminders_settings_page.deactivate_time("Time 2")
      reminders_settings_page.remove_time("Time 1")

      reminders_settings_page.save

      reminders_settings_page.expect_and_dismiss_notification(message: I18n.t('js.notice_successful_update'))

      reminders_settings_page.reload!

      reminders_settings_page.expect_active_daily_times("03:00 pm")
    end
  end

  context 'configuring via the my page' do
    let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }

    current_user do
      FactoryBot.create :user
    end

    it_behaves_like 'reminder settings'
  end

  context 'configuring via the user administration page' do
    let(:reminders_settings_page) { Pages::Reminders::Settings.new(other_user) }

    let(:other_user) { FactoryBot.create :user }

    current_user do
      FactoryBot.create :admin
    end

    it_behaves_like 'reminder settings'
  end

  context 'sending' do
    let!(:project) { FactoryBot.create :project, members: { current_user => role } }
    let!(:mute_project) { FactoryBot.create :project, members: { current_user => role } }
    let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages]) }
    let(:other_user) { FactoryBot.create(:user) }
    let(:work_package) { FactoryBot.create(:work_package, project: project) }
    let(:watched_work_package) { FactoryBot.create(:work_package, project: project, watcher_users: [current_user]) }
    let(:involved_work_package) { FactoryBot.create(:work_package, project: project, assigned_to: current_user) }

    current_user do
      FactoryBot.create :user,
                        notification_settings: [
                          FactoryBot.build(:mail_digest_notification_setting,
                                           involved: true,
                                           watched: true,
                                           mentioned: true,
                                           work_package_commented: true,
                                           work_package_created: true,
                                           work_package_processed: true,
                                           work_package_prioritized: true,
                                           work_package_scheduled: true,
                                           all: false)
                        ]
    end

    before do
      allow(Setting).to receive(:notification_email_digest_time)
                          .and_return(hitting_reminder_slot_for(current_user))

      watched_work_package
      work_package
      involved_work_package

      allow(CustomStyle.current)
        .to receive(:logo).and_return(nil)

      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end

    it 'sends a digest mail based on the configuration', with_settings: { journal_aggregation_time_minutes: 0 } do
      # Perform some actions the user listens to
      User.execute_as other_user do
        note = <<~NOTE
          Hey <mention class=\"mention\"
                       data-id=\"#{current_user.id}\"
                       data-type=\"user\"
                       data-text=\"@#{current_user.name}\">
                @#{current_user.name}
              </mention>
        NOTE

        work_package.add_journal(other_user, note)
        work_package.save!

        watched_work_package.subject = 'New watched work package subject'
        watched_work_package.save!

        involved_work_package.description = 'New involved work package description'
        involved_work_package.save!
      end

      # The Job is triggered by time so we mock it and the jobs started by it being triggered
      Notifications::ScheduleReminderMailsJob.perform_later
      2.times { perform_enqueued_jobs }

      expect(ActionMailer::Base.deliveries.length)
        .to be 1

      expect(ActionMailer::Base.deliveries.first.subject)
        .to eql "OpenProject - 1 unread notification including a mention"
    end

  end
end
