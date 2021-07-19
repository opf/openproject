require 'spec_helper'
require 'support/pages/my/notifications'

describe "Digest email", type: :feature, js: true do
  let!(:project) { FactoryBot.create :project, members: { current_user => role } }
  let!(:mute_project) { FactoryBot.create :project, members: { current_user => role } }
  let(:notification_settings_page) { Pages::My::Notifications.new(current_user) }
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
                                         all: false),
                        FactoryBot.build(:in_app_notification_setting,
                                         involved: false,
                                         watched: false,
                                         mentioned: false,
                                         all: false),
                        FactoryBot.build(:mail_digest_notification_setting,
                                         involved: true,
                                         watched: true,
                                         mentioned: true,
                                         all: false)
                      ]
  end

  before do
    watched_work_package
    work_package
    involved_work_package

    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  it 'sends a digest mail based on the configuration', with_settings: { journal_aggregation_time_minutes: 0 } do
    # Configure the digest
    notification_settings_page.visit!

    notification_settings_page.expect_setting channel: :mail_digest,
                                              project: nil,
                                              involved: true,
                                              mentioned: true,
                                              watched: true,
                                              all: false

    notification_settings_page.configure_channel :mail_digest,
                                                 project: nil,
                                                 involved: false,
                                                 mentioned: true,
                                                 watched: true,
                                                 all: false

    notification_settings_page.add_row(mute_project)

    notification_settings_page.configure_channel :mail_digest,
                                                 project: mute_project,
                                                 involved: false,
                                                 mentioned: false,
                                                 watched: false,
                                                 all: false

    notification_settings_page.save

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

    # Have to explicitly execute the delayed jobs. If we were to execute all
    # by wrapping the above, work package altering code, inside a
    # perform_enqueued_jobs block, the digest job would be executed right away
    # so that the second update would trigger a new digest. But we want to test
    # that only one digest is sent out
    perform_enqueued_jobs
    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.length)
      .to eql 1

    expect(ActionMailer::Base.deliveries.first.subject)
      .to eql I18n.t(:'mail.digests.work_packages.subject',
                     date: Time.current.strftime('%m/%d/%Y'),
                     number: 2)
  end
end
