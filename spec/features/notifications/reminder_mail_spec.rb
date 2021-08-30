require 'spec_helper'
require 'support/pages/my/notifications'

describe "Reminder email", type: :feature, js: true do
  let!(:project) { FactoryBot.create :project, members: { current_user => role } }
  let!(:mute_project) { FactoryBot.create :project, members: { current_user => role } }
  let(:reminders_settings_page) { Pages::My::Reminders.new(current_user) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_work_packages]) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:watched_work_package) { FactoryBot.create(:work_package, project: project, watcher_users: [current_user]) }
  let(:involved_work_package) { FactoryBot.create(:work_package, project: project, assigned_to: current_user) }

  current_user do
    FactoryBot.create :user,
                      notification_settings: [
                        FactoryBot.build(:mail_notification_setting,
                                         involved: false,
                                         watched: false,
                                         mentioned: false,
                                         work_package_commented: false,
                                         work_package_created: false,
                                         work_package_processed: false,
                                         work_package_prioritized: false,
                                         work_package_scheduled: false,
                                         all: false),
                        FactoryBot.build(:in_app_notification_setting,
                                         involved: false,
                                         watched: false,
                                         mentioned: false,
                                         work_package_commented: false,
                                         work_package_created: false,
                                         work_package_processed: false,
                                         work_package_prioritized: false,
                                         work_package_scheduled: false,
                                         all: false),
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
    watched_work_package
    work_package
    involved_work_package

    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  it 'sends a reminder mail based on the configuration', with_settings: { journal_aggregation_time_minutes: 0 } do
    # Configure the digest
    reminders_settings_page.visit!

    # By default a reminder timed for 8:00 should be configured
    reminders_settings_page.expect_active_daily_times("08:00")
  end
end
