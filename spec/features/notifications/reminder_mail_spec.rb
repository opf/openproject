require "spec_helper"
require_relative "../users/notifications/shared_examples"

RSpec.describe "Reminder email sending", js: false do
  let!(:project) { create(:project, members: { current_user => role }) }
  let!(:mute_project) { create(:project, members: { current_user => role }) }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:other_user) { create(:user) }
  let(:work_package) { create(:work_package, project:) }
  let(:watched_work_package) { create(:work_package, project:, watcher_users: [current_user]) }
  let(:involved_work_package) { create(:work_package, project:, assigned_to: current_user) }
  # GoodJob::Job#cron_at is used for scheduling the reminder mails.
  # It needs to be within a time frame eligible for sending out mails for the chosen
  # time zone. For the time zone Hawaii (UTC-10) this means 8:00:00 as the job has a cron tab to be run every 15 min.
  let(:job_run_at) { ActiveSupport::TimeZone["Pacific/Honolulu"].parse("2021-09-30T08:00:00").utc }

  let(:scheduled_job) do
    Notifications::ScheduleReminderMailsJob.perform_later.tap do |job|
      GoodJob::Job
        .where(id: job.job_id)
        .update_all(cron_at: job_run_at)
    end
  end

  # The reminder mail is sent out after notifications have been created which might have happened way earlier.
  # This spec will be fixed to this time ensure a consistent run and to mimic the time that typically has passed
  # between the changes to a work package and the reminder mail being sent out.
  let(:work_package_update_time) { ActiveSupport::TimeZone["Pacific/Honolulu"].parse("2021-09-30T01:50:34").utc }

  around do |example|
    Timecop.travel(work_package_update_time) do
      example.run
    end
  end

  current_user do
    create(
      :user,
      preferences: {
        time_zone: "Pacific/Honolulu",
        daily_reminders: {
          enabled: true,
          times: [hitting_reminder_slot_for("Pacific/Honolulu", job_run_at)]
        },
        immediate_reminders: {
          mentioned: false
        }
      },
      notification_settings: [
        build(:notification_setting,
              assignee: true,
              responsible: true,
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

    ActiveJob::Base.disable_test_adapter

    scheduled_job
  end

  it "sends a digest mail based on the configuration", with_settings: { journal_aggregation_time_minutes: 0 } do
    # Perform some actions the user listens to
    User.execute_as other_user do
      note = <<~NOTE
        Hey <mention class="mention"
                     data-id="#{current_user.id}"
                     data-type="user"
                     data-text="@#{current_user.name}">
              @#{current_user.name}
            </mention>
      NOTE

      work_package.add_journal(user: other_user, notes: note)
      work_package.save!

      watched_work_package.subject = "New watched work package subject"
      watched_work_package.save!

      involved_work_package.description = "New involved work package description"
      involved_work_package.save!
    end

    2.times { GoodJob.perform_inline }

    expect(ActionMailer::Base.deliveries.length).to be 1
    expect(ActionMailer::Base.deliveries.first.subject)
      .to eql "OpenProject - 1 unread notification including a mention"
  end
end
