require 'spec_helper'
require_relative '../users/notifications/shared_examples'

describe "Reminder email sending", type: :feature, js: true do
  let!(:project) { create :project, members: { current_user => role } }
  let!(:mute_project) { create :project, members: { current_user => role } }
  let(:role) { create(:role, permissions: %i[view_work_packages]) }
  let(:other_user) { create(:user) }
  let(:work_package) { create(:work_package, project: project) }
  let(:watched_work_package) { create(:work_package, project: project, watcher_users: [current_user]) }
  let(:involved_work_package) { create(:work_package, project: project, assigned_to: current_user) }
  # The run_at time of the delayed job used for scheduling the reminder mails
  # needs to be within a time frame eligible for sending out mails for the chose
  # time zone. For the time zone Hawaii (UTC-10) this means between 8:00:00 and 8:14:59 UTC.
  # The job is scheduled to run every 15 min so the run_at will in production always move between the quarters of an hour.
  # The current time can be way behind that.
  let(:current_utc_time) {ActiveSupport::TimeZone['Pacific/Honolulu'].parse("2021-09-30T08:34:10").utc }
  let(:job_run_at) { ActiveSupport::TimeZone['Pacific/Honolulu'].parse("2021-09-30T08:00:00").utc }

  # Fix the time of the specs to ensure a consistent run
  around do |example|
    Timecop.travel(current_utc_time) do
      example.run
    end
  end

  current_user do
    create(
      :user,
      preferences: {
        time_zone: 'Pacific/Honolulu',
        daily_reminders: {
          enabled: true,
          times: [hitting_reminder_slot_for('Pacific/Honolulu', current_utc_time)]
        }
      },
      notification_settings: [
        build(:notification_setting,
                         involved: true,
                         watched: true,
                         mentioned: true,
                         work_package_commented: true,
                         work_package_created: true,
                         work_package_processed: true,
                         work_package_prioritized: true,
                         work_package_scheduled: true)
      ]
    )
  end

  before do
    watched_work_package
    work_package
    involved_work_package

    ActiveJob::Base.queue_adapter.enqueued_jobs.clear

    # There is no delayed_job associated when using the testing backend of ActiveJob
    # so we have to mock it.
    allow(Notifications::ScheduleReminderMailsJob)
      .to receive(:delayed_job)
            .and_return(instance_double(Delayed::Backend::ActiveRecord::Job, run_at: job_run_at))
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
