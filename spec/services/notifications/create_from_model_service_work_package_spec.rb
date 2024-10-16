#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
require "spec_helper"
require_relative "create_from_journal_job_shared"

RSpec.describe Notifications::CreateFromModelService,
               "work_package",
               with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:call) do
    described_class.new(journal).call(send_notifications)
  end

  include_context "with CreateFromJournalJob context"

  let(:permissions) { [:view_work_packages] }
  let(:author) { user_property == :author ? recipient : other_user }
  let(:user_property) { nil }
  let(:work_package) do
    wp_attributes = {
      project:,
      author: other_user,
      responsible: other_user,
      assigned_to: other_user,
      type: project.types.first
    }

    if %i[responsible assigned_to].include?(user_property)
      create(:work_package,
             **wp_attributes.merge(user_property => recipient))
    elsif user_property == :watcher
      create(:work_package,
             **wp_attributes) do |wp|
        Watcher.new(watchable: wp, user: recipient).save(validate: false)
      end
    elsif user_property == :shared
      create(:work_package,
             **wp_attributes) do |wp|
        Member.new(entity: wp,
                   project: wp.project,
                   principal: recipient,
                   roles: [create(:work_package_role)])
              .save(validate: false)
      end
    else
      # Initialize recipient to have the same behaviour as if the recipient is assigned/responsible
      recipient
      create(:work_package,
             **wp_attributes)
    end
  end
  let(:resource) { work_package }
  let(:journal) { work_package.journals.first }
  let(:journal_2_with_notes) do
    work_package.add_journal user: author, notes: "something I have to say"
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:journal_2_with_status) do
    work_package.status = create(:status)
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:journal_2_with_priority) do
    work_package.priority = create(:priority)
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:journal_2_with_start_date) do
    work_package.start_date = Time.zone.today
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:journal_2_with_due_date) do
    work_package.due_date = Time.zone.today
    work_package.save(validate: false)
    work_package.journals.last
  end

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing

    login_as(author)
  end

  context "when user is assignee" do
    let(:user_property) { :assigned_to }
    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_false.merge(assignee: true))
      ]
    end

    it_behaves_like "creates notification" do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason: :assigned,
          mail_alert_sent: nil,
          mail_reminder_sent: false
        }
      end
    end

    context "when assignee has all app notification reasons enabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :assigned,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when assignee has all notifications disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when assignee has all in app notifications enabled but only assignee for mail" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false.merge(assignee: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :assigned,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when assignee is not allowed to view work packages" do
      let(:permissions) { [] }

      it_behaves_like "creates no notification"
    end

    context "when assignee is placeholder user" do
      let(:recipient) { create(:placeholder_user) }

      it_behaves_like "creates no notification"
    end

    context "when assignee has all notifications enabled but made the change himself" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like "creates no notification"
    end
  end

  context "when user is responsible" do
    let(:user_property) { :responsible }
    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_false.merge(responsible: true))
      ]
    end

    it_behaves_like "creates notification" do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason: :responsible,
          mail_alert_sent: nil,
          mail_reminder_sent: false
        }
      end
    end

    context "when responsible has all notifications disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when responsible is not allowed to view work packages" do
      let(:permissions) { [] }

      it_behaves_like "creates no notification"
    end

    context "when responsible is placeholder user" do
      let(:recipient) { create(:placeholder_user) }

      it_behaves_like "creates no notification"
    end

    context "when responsible has all notifications enabled but made the change himself" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like "creates no notification"
    end
  end

  context "when user is watcher" do
    let(:user_property) { :watcher }
    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_true)
      ]
    end

    it_behaves_like "creates notification" do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason: :watched,
          mail_alert_sent: nil,
          mail_reminder_sent: false
        }
      end
    end

    context "when watcher has in app notifications disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false.merge(watched: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :watched,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when watcher has all notifications disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when watcher is not allowed to view work packages" do
      let(:permissions) { [] }

      it_behaves_like "creates no notification"
    end

    context "when watcher has all notifications enabled but made the change himself" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like "creates no notification"
    end
  end

  context "when user is notified about everything" do
    let(:user_property) { nil }

    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_true)
      ]
    end

    it_behaves_like "creates notification" do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason: :created,
          mail_alert_sent: nil,
          mail_reminder_sent: false
        }
      end
    end

    context "with in app notifications disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :created,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "with all disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "with all disabled as a default but enabled in the project" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false),
          build(:notification_setting, project:, **notification_settings_all_true)
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :created,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "with all enabled as a default but disabled in the project" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true),
          build(:notification_setting, project:, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when not allowed to view work packages" do
      let(:permissions) { [] }

      it_behaves_like "creates no notification"
    end

    context "when recipient has all notifications enabled but made the change himself" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like "creates no notification"
    end
  end

  context "when the work package is shared with the user" do
    let(:user_property) { :shared }
    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_false.merge(shared: true))
      ]
    end

    it_behaves_like "creates notification" do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason: :shared,
          mail_alert_sent: nil,
          mail_reminder_sent: false
        }
      end
    end

    context "when the shared with user has all notifications disabled" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when the shared with user is not allowed to view work packages" do
      let(:permissions) { [] }

      it_behaves_like "creates no notification"
    end

    context "when the shared with user has all notifications enabled but made the change himself" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like "creates no notification"
    end
  end

  context "when a work package is created" do
    context "when the user configured to be notified on work package creation" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_created: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :created,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when the user configured to be notified on work package status changes" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_processed: true))
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when the user configured to be notified on work package priority changes" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_prioritized: true))
        ]
      end

      it_behaves_like "creates no notification"
    end

    context "when the user did not configure to be notified" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has a note" do
    let(:journal) { journal_2_with_notes }

    context "when the user has commented notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_commented: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :commented,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when the user has commented notifications deactivated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has no note" do
    let(:journal) { journal_2_with_status }

    context "with the user having commented notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_commented: true))
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has status update" do
    let(:journal) { journal_2_with_status }

    context "when the user has processed notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_processed: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :processed,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when the user has processed notifications deactivated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has no status update" do
    let(:journal) { journal_2_with_notes }

    context "with the user having processed notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_processed: true))
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has priority" do
    let(:journal) { journal_2_with_priority }

    context "when the user has prioritized notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_prioritized: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :prioritized,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when the user has prioritized notifications deactivated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has no priority update" do
    let(:journal) { journal_2_with_status }

    context "with the user having prioritized notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_prioritized: true))
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has a start date update" do
    let(:journal) { journal_2_with_start_date }

    context "when the user has scheduled notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_scheduled: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :scheduled,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when the user has scheduled notifications deactivated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has no start or due date update" do
    let(:journal) { journal_2_with_notes }

    context "with the user having scheduled notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_scheduled: true))
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the journal has a due date update" do
    let(:journal) { journal_2_with_due_date }

    context "when the user has scheduled notifications activated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false
                                                           .merge(work_package_scheduled: true))
        ]
      end

      it_behaves_like "creates notification" do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason: :scheduled,
            mail_alert_sent: nil,
            mail_reminder_sent: false
          }
        end
      end
    end

    context "when the user has scheduled notifications deactivated" do
      let(:recipient_notification_settings) do
        [
          build(:notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like "creates no notification"
    end
  end

  context "when the author has been deleted" do
    let!(:deleted_user) { DeletedUser.first }
    let(:user_property) { :assigned_to }

    before do
      work_package
      author.destroy
    end

    it_behaves_like "creates notification" do
      let(:sender) { deleted_user }
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason: :assigned,
          mail_alert_sent: nil,
          mail_reminder_sent: false
        }
      end
    end
  end

  context "when user is mentioned" do
    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_false.merge(mentioned: true))
      ]
    end

    shared_examples_for "group mention" do
      context "with a group member allowed to view the work package" do
        context "when the user wants to receive notifications" do
          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the user disabled mention notifications" do
          let(:recipient_notification_settings) do
            [
              build(:notification_setting, **notification_settings_all_false.merge(mentioned: false))
            ]
          end

          it_behaves_like "creates no notification"
        end
      end

      context "with the group not allowed to view the work package" do
        let(:group_role) { create(:project_role, permissions: []) }
        let(:permissions) { [] }

        it_behaves_like "creates no notification"

        context "with the group member allowed individually" do
          let(:permissions) { [:view_work_packages] }

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end
      end
    end

    shared_examples_for "mentioned" do
      context "with users" do
        context "when the added text contains a login name as a pretty normal word" do
          let(:note) { "Hello user:\"#{recipient_login}\"" }

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the added text contains an email login" do
          let(:note) { "Hello user:\"#{recipient_login}\"" }
          let(:recipient_login) { "foo@bar.com" }

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the added text contains a user ID" do
          let(:note) { "Hello user##{recipient.id}" }

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the added text contains a user mention tag with the attributes in one order" do
          let(:note) do
            <<~NOTE
              Hello <mention class="mention" data-id="#{recipient.id}" data-type="user" data-text="@#{recipient.name}">@#{recipient.name}</mention>
            NOTE
          end

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the added text contains a user mention tag with the attributes in another order" do
          let(:note) do
            <<~NOTE
              Hello <mention class="mention" data-type="user" data-id="#{recipient.id}" data-text="@#{recipient.name}">@#{recipient.name}</mention>
            NOTE
          end

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the added text contains a user mention tag inside a quote" do
          let(:note) do
            <<~NOTE
              #{recipient.name} wrote:
              > Hello <mention class="mention" data-id="#{recipient.id}" data-type="user" data-text="@#{recipient.name}">@#{recipient.name}</mention>
            NOTE
          end

          it_behaves_like "creates no notification"
        end

        context "when the added text contains a user mention tag inside an invalid quote" do
          let(:note) do
            <<~NOTE
              #{recipient.name} wrote:
              >Hello <mention class="mention" data-id="#{recipient.id}" data-type="user" data-text="@#{recipient.name}">@#{recipient.name}</mention>
            NOTE
          end

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the added text contains a user mention tag inside a quote and outside" do
          let(:note) do
            <<~NOTE
              Hi <mention class="mention" data-id="#{recipient.id}" data-type="user" data-text="@#{recipient.name}">@#{recipient.name}</mention> :
              > Hello <mention class="mention" data-id="#{recipient.id}" data-type="user" data-text="@#{recipient.name}">@#{recipient.name}</mention>
            NOTE
          end

          it_behaves_like "creates notification" do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason: :mentioned,
                mail_alert_sent: false,
                mail_reminder_sent: false
              }
            end
          end
        end

        context "when the recipient turned off mention notifications" do
          let(:recipient_notification_settings) do
            [
              build(:notification_setting, **notification_settings_all_false.merge(mentioned: false))
            ]
          end

          let(:note) do
            "Hello user:\"#{recipient.login}\", hey user##{recipient.id}"
          end

          it_behaves_like "creates no notification"
        end

        context "with the mentioned user not being allowed to view the work package" do
          let(:permissions) { [] }
          let(:note) do
            "Hello user:#{recipient.login}, hey user##{recipient.id}"
          end

          it_behaves_like "creates no notification"
        end

        context "when the mentioned user made the change himself" do
          let(:note) do
            "Hello user:#{recipient.login}, hey user##{recipient.id}"
          end
          let(:author) { recipient }

          it_behaves_like "creates no notification"
        end

        context "when there is already a notification for the journal (because it was aggregated)" do
          let(:note) { "Hello user:\"#{recipient_login}\"" }
          let!(:existing_notification) do
            create(:notification, resource:, journal:, recipient:, reason: :mentioned, read_ian: true, mail_alert_sent: nil)
          end

          it_behaves_like "creates no notification"

          it "resets the read_ian of the existing notification to false" do
            call

            expect(existing_notification.reload.read_ian)
              .to be(false)
          end

          it "changes the mail_alert_sent of the existing notification from nil to false" do
            call

            expect(existing_notification.reload.mail_alert_sent)
              .to be(false)
          end

          context "and the mail alert has already been sent" do
            before do
              existing_notification.update(mail_alert_sent: true)
            end

            it "keeps the mail_alert_sent of the existing notification to true" do
              call

              expect(existing_notification.reload.mail_alert_sent)
                .to be(true)
            end
          end
        end

        context "when there is already a notification for the journal (aggregation) but the user is no longer mentioned" do
          let(:note) { "Hello you" }
          let!(:existing_notification) do
            create(:notification, resource:, journal:, recipient:, reason: :mentioned, read_ian: true)
          end

          it_behaves_like "creates no notification"

          it "removes the existing notification" do
            call

            expect(Notification)
              .not_to exist(id: existing_notification.id)
          end
        end
      end

      context "for groups" do
        let(:group_role) { create(:project_role, permissions: %i[view_work_packages]) }
        let(:group) do
          create(:group, members: recipient) do |group|
            Members::CreateService
              .new(user: User.system, contract_class: EmptyContract)
              .call(project:, principal: group, roles: [group_role])
          end
        end

        context "with a hash/id based mention" do
          let(:note) do
            "Hello group##{group.id}"
          end

          it_behaves_like "group mention"
        end

        context "with a tag based mention with the type after" do
          let(:note) do
            <<~NOTE
              Hello <mention class="mention" data-id="#{group.id}" data-type="group" data-text="@#{group.name}">@#{group.name}</mention>
            NOTE
          end

          it_behaves_like "group mention"
        end

        context "with a tag based mention with the type before" do
          let(:note) do
            <<~NOTE
              Hello <mention data-type="group" class="mention" data-id="#{group.id}" data-text="@#{group.name}">@#{group.name}</mention>
            NOTE
          end

          it_behaves_like "group mention"
        end

        context "with the group member making the change himself" do
          let(:note) do
            <<~NOTE
              Hello <mention class="mention" data-id="#{group.id}" data-type="group" data-text="@#{group.name}">@#{group.name}</mention>
            NOTE
          end
          let(:author) { recipient }

          it_behaves_like "creates no notification"
        end
      end

      context "with users and groups" do
        let(:group_role) { create(:project_role, permissions: %i[view_work_packages]) }
        let(:group) do
          create(:group, members: recipient) do |group|
            Members::CreateService
              .new(user: User.system, contract_class: EmptyContract)
              .call(project:, principal: group, roles: [group_role])
          end
        end
        let(:other_recipient) do
          create(:user,
                 member_with_permissions: { project => permissions },
                 notification_settings: [build(:notification_setting, **notification_settings_all_true)])
        end
        let(:notification_group_recipient) { build_stubbed(:notification, recipient:) }
        let(:notification_other_recipient) { build_stubbed(:notification, recipient: other_recipient) }

        context "with two tag based mention in the same line" do
          let(:note) do
            <<~NOTE.squish
              Hello
              <mention class="mention"
                       data-id="#{group.id}"
                       data-type="group"
                       data-text="@#{group.name}">@#{group.name}
              </mention>
              <mention class="mention"
                       data-id="#{other_recipient.id}"
                       data-type="user"
                       data-text="@#{other_recipient.name}">@#{other_recipient.name}
              </mention>,
              check this.
            NOTE
          end

          let(:notification_channel_reasons) do
            {
              read_ian: false,
              reason: :mentioned,
              mail_alert_sent: false,
              mail_reminder_sent: false
            }
          end

          it "creates two notification and returns them" do
            notifications_service = instance_double(Notifications::CreateService)

            allow(Notifications::CreateService)
              .to receive(:new)
                    .with(user: author)
                    .and_return(notifications_service)

            allow(notifications_service)
              .to receive(:call) do |args|
              if args[:recipient_id] == recipient.id &&
                args.slice(*notification_channel_reasons.keys) == notification_channel_reasons
                ServiceResult.success(result: notification_group_recipient)
              elsif args[:recipient_id] == other_recipient.id &&
                args.slice(*notification_channel_reasons.keys) == notification_channel_reasons
                ServiceResult.success(result: notification_other_recipient)
              else
                expect(true)
                  .to be(false),
                      "Notification::CreateService received unexpected args: #{args.inspect}"
              end
            end

            expect(call.all_results)
              .to contain_exactly(notification_group_recipient, notification_other_recipient)
          end
        end
      end
    end

    describe "in the journal notes" do
      let(:journal) { journal_2_with_notes }
      let(:journal_2_with_notes) do
        work_package.add_journal user: author, notes: note
        work_package.save(validate: false)
        work_package.journals.last
      end
      let(:note) do
        <<~NOTE
          Hello <mention class="mention" data-type="user" data-id="#{recipient.id}" data-text="@#{recipient.name}">@#{recipient.name}</mention>
        NOTE
      end

      it_behaves_like "mentioned"
    end

    describe "in the description" do
      let(:journal) { journal_2_with_description }
      let(:journal_2_with_description) do
        work_package.description = note
        work_package.save(validate: false)
        work_package.journals.last
      end

      it_behaves_like "mentioned"
    end

    describe "in the subject" do
      let(:journal) { journal_2_with_subject }
      let(:journal_2_with_subject) do
        work_package.subject = note
        work_package.save(validate: false)
        work_package.journals.last
      end

      it_behaves_like "mentioned"
    end
  end

  context "when on aggregating the journal, sending of notifications is prevented" do
    let!(:existing_notification) do
      create(:notification, resource:, journal:, recipient:, reason: :mentioned, read_ian: true)
    end
    let(:send_notifications) { false }
    let(:user_property) { :watcher }
    let(:recipient_notification_settings) do
      [
        build(:notification_setting, **notification_settings_all_true)
      ]
    end

    it_behaves_like "creates no notification"

    it "removes the existing notifications" do
      call

      expect(Notification)
        .not_to exist(id: existing_notification.id)
    end
  end

  context "when the journal is deleted" do
    before do
      journal.destroy
    end

    it_behaves_like "creates no notification"
  end
end
