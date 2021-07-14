#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe Notifications::JournalWpNotificationService, with_settings: { journal_aggregation_time_minutes: 0 } do
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
  let(:recipient) do
    FactoryBot.create(:user,
                      notification_settings: recipient_notification_settings,
                      member_in_project: project,
                      member_through_role: role,
                      login: recipient_login)
  end
  let(:recipient_login) { "johndoe" }
  let(:other_user) do
    FactoryBot.create(:user,
                      notification_settings: other_user_notification_settings)
  end
  let(:author) { user_property == :author ? recipient : other_user }
  let(:recipient_notification_settings) do
    [
      FactoryBot.build(:mail_notification_setting, all: true),
      FactoryBot.build(:in_app_notification_setting, all: true),
      FactoryBot.build(:mail_digest_notification_setting, all: true)
    ]
  end
  let(:other_user_notification_settings) do
    [
      FactoryBot.build(:mail_notification_setting, all: false, involved: false, watched: false, mentioned: false),
      FactoryBot.build(:in_app_notification_setting, all: false, involved: false, watched: false, mentioned: false),
      FactoryBot.build(:mail_digest_notification_setting, all: false, involved: false, watched: false, mentioned: false)
    ]
  end
  let(:user_property) { nil }
  let(:work_package) do
    wp_attributes = { project: project,
                      author: other_user,
                      responsible: other_user,
                      assigned_to: other_user,
                      type: project.types.first }

    if %i[responsible assigned_to].include?(user_property)
      FactoryBot.create(:work_package,
                        **wp_attributes.merge(user_property => recipient))
    elsif user_property == :watcher
      FactoryBot.create(:work_package,
                        **wp_attributes).tap do |wp|
        Watcher.new(watchable: wp, user: recipient).save(validate: false)
      end
    else
      # Initialize recipient to have the same behaviour as if the recipient is assigned/responsible
      recipient
      FactoryBot.create(:work_package,
                        **wp_attributes)
    end

  end
  let(:journal) { journal_1 }
  let(:journal_1) { work_package.journals.first }
  let(:journal_2_with_notes) do
    work_package.add_journal author, 'something I have to say'
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:journal_2_with_status) do
    work_package.status = FactoryBot.create(:status)
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:journal_2_with_priority) do
    work_package.priority = FactoryBot.create(:priority)
    work_package.save(validate: false)
    work_package.journals.last
  end
  let(:send_notifications) { true }
  let(:notification_setting) do
    %w(work_package_added work_package_updated work_package_note_added status_updated work_package_priority_updated)
  end

  def call
    described_class.call(journal, send_notifications)
  end

  before do
    # make sure no other calls are made due to WP creation/update
    allow(OpenProject::Notifications).to receive(:send) # ... and do nothing

    login_as(author)
    allow(Setting).to receive(:notified_events).and_return(notification_setting)
  end

  shared_examples_for 'creates notification' do
    let(:sender) { author }
    let(:notification_channel_reasons) do
      {
        read_ian: false,
        reason_ian: :mentioned,
        read_mail: false,
        reason_mail: :mentioned,
        read_mail_digest: false,
        reason_mail_digest: :mentioned
      }
    end

    it 'creates a notification' do
      notifications_service = instance_double(Notifications::CreateService)

      allow(Notifications::CreateService)
        .to receive(:new)
              .with(user: sender)
              .and_return(notifications_service)
      allow(notifications_service)
        .to receive(:call)

      call

      expect(notifications_service)
        .to have_received(:call)
              .with({ recipient_id: recipient.id,
                      project: journal.project,
                      actor: sender,
                      journal: journal,
                      resource: journal.journable }.merge(notification_channel_reasons))
    end
  end

  shared_examples_for 'creates no notification' do
    it 'creates no notification' do
      allow(Notifications::CreateService)
        .to receive(:new)
              .and_call_original

      call

      expect(Notifications::CreateService)
        .not_to have_received(:new)
    end
  end

  context 'when user is assignee' do
    let(:user_property) { :assigned_to }
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, involved: true),
        FactoryBot.build(:in_app_notification_setting, involved: true),
        FactoryBot.build(:mail_digest_notification_setting, involved: true)
      ]
    end

    it_behaves_like 'creates notification' do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason_ian: :involved,
          read_mail: false,
          reason_mail: :involved,
          read_mail_digest: false,
          reason_mail_digest: :involved
        }
      end
    end

    context 'assignee has in app notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: false, all: true),
          FactoryBot.build(:mail_digest_notification_setting, involved: true),
          FactoryBot.build(:in_app_notification_setting, involved: false)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: nil,
            reason_ian: nil,
            read_mail: false,
            reason_mail: :subscribed,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end

    context 'assignee has mail notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: false),
          FactoryBot.build(:mail_digest_notification_setting, involved: false),
          FactoryBot.build(:in_app_notification_setting, involved: true)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: nil,
            reason_mail: nil,
            read_mail_digest: nil,
            reason_mail_digest: nil
          }
        end
      end
    end

    context 'assignee has all notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: false),
          FactoryBot.build(:mail_digest_notification_setting, involved: false),
          FactoryBot.build(:in_app_notification_setting, involved: false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'assignee has all in app notifications enabled but only involved for mail' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: true),
          FactoryBot.build(:mail_digest_notification_setting, involved: true),
          FactoryBot.build(:in_app_notification_setting, involved: false, watched: false, mentioned: false, all: true)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :subscribed,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end

    context 'assignee is not allowed to view work packages' do
      let(:role) { FactoryBot.create(:role, permissions: []) }

      it_behaves_like 'creates no notification'
    end

    context 'assignee is placeholder user' do
      let(:recipient) { FactoryBot.create :placeholder_user }

      it_behaves_like 'creates no notification'
    end
  end

  context 'when user is responsible' do
    let(:user_property) { :responsible }
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, involved: true),
        FactoryBot.build(:mail_digest_notification_setting, involved: true),
        FactoryBot.build(:in_app_notification_setting, involved: true)
      ]
    end

    it_behaves_like 'creates notification' do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason_ian: :involved,
          read_mail: false,
          reason_mail: :involved,
          read_mail_digest: false,
          reason_mail_digest: :involved
        }
      end
    end

    context 'when responsible has in app notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: false, all: true),
          FactoryBot.build(:mail_digest_notification_setting, involved: false, all: true),
          FactoryBot.build(:in_app_notification_setting, involved: false)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: nil,
            reason_ian: nil,
            read_mail: false,
            reason_mail: :subscribed,
            read_mail_digest: false,
            reason_mail_digest: :subscribed
          }
        end
      end
    end

    context 'when responsible has mail notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: false),
          FactoryBot.build(:mail_digest_notification_setting, involved: false),
          FactoryBot.build(:in_app_notification_setting, involved: true)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: nil,
            reason_mail: nil,
            read_mail_digest: nil,
            reason_mail_digest: nil
          }
        end
      end
    end

    context 'when responsible has all notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: false),
          FactoryBot.build(:mail_digest_notification_setting, involved: false),
          FactoryBot.build(:in_app_notification_setting, involved: false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when responsible is not allowed to view work packages' do
      let(:role) { FactoryBot.create(:role, permissions: []) }

      it_behaves_like 'creates no notification'
    end

    context 'when responsible is placeholder user' do
      let(:recipient) { FactoryBot.create :placeholder_user }

      it_behaves_like 'creates no notification'
    end
  end

  context 'when user is watcher' do
    let(:user_property) { :watcher }
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, watched: true),
        FactoryBot.build(:mail_digest_notification_setting, watched: true),
        FactoryBot.build(:in_app_notification_setting, watched: true)
      ]
    end

    it_behaves_like 'creates notification' do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason_ian: :watched,
          read_mail: false,
          reason_mail: :watched,
          read_mail_digest: false,
          reason_mail_digest: :watched
        }
      end
    end

    context 'when watcher has in app notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, watched: true),
          FactoryBot.build(:mail_digest_notification_setting, watched: true),
          FactoryBot.build(:in_app_notification_setting, watched: false)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: nil,
            reason_ian: nil,
            read_mail: false,
            reason_mail: :watched,
            read_mail_digest: false,
            reason_mail_digest: :watched
          }
        end
      end
    end

    context 'when watcher has mail notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, watched: false),
          FactoryBot.build(:mail_digest_notification_setting, watched: false),
          FactoryBot.build(:in_app_notification_setting, watched: true)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :watched,
            read_mail: nil,
            reason_mail: nil,
            read_mail_digest: nil,
            reason_mail_digest: nil
          }
        end
      end
    end

    context 'when watcher has all notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, watched: false),
          FactoryBot.build(:mail_digest_notification_setting, watched: false),
          FactoryBot.build(:in_app_notification_setting, watched: false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when watcher is not allowed to view work packages' do
      let(:role) { FactoryBot.create(:role, permissions: []) }

      it_behaves_like 'creates no notification'
    end
  end

  context 'when user is notified about everything' do
    let(:user_property) { nil }

    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, all: true),
        FactoryBot.build(:mail_digest_notification_setting, all: true),
        FactoryBot.build(:in_app_notification_setting, all: true)
      ]
    end

    it_behaves_like 'creates notification' do
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason_ian: :subscribed,
          read_mail: false,
          reason_mail: :subscribed,
          read_mail_digest: false,
          reason_mail_digest: :subscribed
        }
      end
    end

    context 'with in app notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: true),
          FactoryBot.build(:mail_digest_notification_setting, all: true),
          FactoryBot.build(:in_app_notification_setting, all: false)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: nil,
            reason_ian: nil,
            read_mail: false,
            reason_mail: :subscribed,
            read_mail_digest: false,
            reason_mail_digest: :subscribed
          }
        end
      end
    end

    context 'with mail notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: false),
          FactoryBot.build(:mail_digest_notification_setting, all: false),
          FactoryBot.build(:in_app_notification_setting, all: true)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :subscribed,
            read_mail: nil,
            reason_mail: nil,
            read_mail_digest: nil,
            reason_mail_digest: nil
          }
        end
      end
    end

    context 'with all disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: false),
          FactoryBot.build(:mail_digest_notification_setting, all: false),
          FactoryBot.build(:in_app_notification_setting, all: false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'with all disabled as a default but enabled in the project' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: false),
          FactoryBot.build(:mail_digest_notification_setting, all: false),
          FactoryBot.build(:in_app_notification_setting, all: false),
          FactoryBot.build(:mail_notification_setting, project: project, all: true),
          FactoryBot.build(:mail_digest_notification_setting, project: project, all: true),
          FactoryBot.build(:in_app_notification_setting, project: project, all: true)
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :subscribed,
            read_mail: false,
            reason_mail: :subscribed,
            read_mail_digest: false,
            reason_mail_digest: :subscribed
          }
        end
      end
    end

    context 'with all enabled as a default but disabled in the project' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: true),
          FactoryBot.build(:mail_digest_notification_setting, all: true),
          FactoryBot.build(:in_app_notification_setting, all: true),
          FactoryBot.build(:mail_notification_setting, project: project, all: false),
          FactoryBot.build(:mail_digest_notification_setting, project: project, all: false),
          FactoryBot.build(:in_app_notification_setting, project: project, all: false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when not allowed to view work packages' do
      let(:role) { FactoryBot.create(:role, permissions: []) }

      it_behaves_like 'creates no notification'
    end
  end

  context 'when notification for work_package_added disabled' do
    let(:notification_setting) { %w(work_package_updated work_package_note_added) }
    let(:user_property) { :assigned_to }

    it_behaves_like 'creates no notification'
  end

  context 'when the journal has a note' do
    let(:journal) { journal_2_with_notes }
    let(:user_property) { :assigned_to }

    context 'notification for work_package_updated and work_package_note_added disabled' do
      let(:notification_setting) { %w(work_package_added status_updated work_package_priority_updated) }

      it_behaves_like 'creates no notification'
    end

    context 'notification for work_package_updated enabled' do
      let(:notification_setting) { %w(work_package_updated) }

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end

    context 'notification for work_package_note_added enabled' do
      let(:notification_setting) { %w(work_package_note_added) }

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end
  end

  context 'when the journal has status update' do
    let(:journal) { journal_2_with_status }
    let(:user_property) { :assigned_to }

    context 'notification for work_package_updated and status_updated disabled' do
      let(:notification_setting) { %w(work_package_added work_package_note_added work_package_priority_updated) }

      it_behaves_like 'creates no notification'
    end

    context 'notification for work_package_updated enabled' do
      let(:notification_setting) { %w(work_package_updated) }

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end

    context 'notification for status_updated enabled' do
      let(:notification_setting) { %w(status_updated) }

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end
  end

  context 'when the journal has priority' do
    let(:journal) { journal_2_with_priority }
    let(:user_property) { :assigned_to }

    context 'notification for work_package_updated and work_package_priority_updated disabled' do
      let(:notification_setting) { %w(work_package_added work_package_note_added status_updated) }

      it_behaves_like 'creates no notification'
    end

    context 'notification for work_package_updated enabled' do
      let(:notification_setting) { %w(work_package_updated) }

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end

    context 'notification for work_package_priority_updated enabled' do
      let(:notification_setting) { %w(work_package_priority_updated) }

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :involved,
            read_mail: false,
            reason_mail: :involved,
            read_mail_digest: false,
            reason_mail_digest: :involved
          }
        end
      end
    end
  end

  context 'when the author has been deleted' do
    let!(:deleted_user) { DeletedUser.first }
    let(:user_property) { :assigned_to }

    before do
      work_package
      author.destroy
    end

    it_behaves_like 'creates notification' do
      let(:sender) { deleted_user }
      let(:notification_channel_reasons) do
        {
          read_ian: false,
          reason_ian: :involved,
          read_mail: false,
          reason_mail: :involved,
          read_mail_digest: false,
          reason_mail_digest: :involved
        }
      end
    end
  end

  context 'when user is mentioned' do
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, mentioned: true),
        FactoryBot.build(:mail_digest_notification_setting, mentioned: true),
        FactoryBot.build(:in_app_notification_setting, mentioned: true)
      ]
    end

    shared_examples_for 'group mention' do
      context 'group member is allowed to view the work package' do
        context 'user wants to receive notifications' do
          it_behaves_like 'creates notification' do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason_ian: :mentioned,
                read_mail: false,
                reason_mail: :mentioned,
                read_mail_digest: false,
                reason_mail_digest: :mentioned
              }
            end
          end
        end

        context 'user disabled mention notifications' do
          let(:recipient_notification_settings) do
            [
              FactoryBot.build(:mail_notification_setting, mentioned: false),
              FactoryBot.build(:mail_digest_notification_setting, mentioned: false),
              FactoryBot.build(:in_app_notification_setting, mentioned: false)
            ]
          end

          it_behaves_like 'creates no notification'
        end
      end

      context 'group is not allowed to view the work package' do
        let(:group_role) { FactoryBot.create(:role, permissions: []) }
        let(:role) { FactoryBot.create(:role, permissions: []) }

        it_behaves_like 'creates no notification'

        context 'but group member is allowed individually' do
          let(:role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }

          it_behaves_like 'creates notification' do
            let(:notification_channel_reasons) do
              {
                read_ian: false,
                reason_ian: :mentioned,
                read_mail: false,
                reason_mail: :mentioned,
                read_mail_digest: false,
                reason_mail_digest: :mentioned
              }
            end
          end
        end
      end
    end

    shared_examples_for 'mentioned' do
      context 'for users' do
        context "mentioned is allowed to view the work package" do
          context "The added text contains a login name" do
            let(:note) { "Hello user:\"#{recipient_login}\"" }

            context "that is pretty normal word" do
              it_behaves_like 'creates notification' do
                let(:notification_channel_reasons) do
                  {
                    read_ian: false,
                    reason_ian: :mentioned,
                    read_mail: false,
                    reason_mail: :mentioned,
                    read_mail_digest: false,
                    reason_mail_digest: :mentioned
                  }
                end
              end
            end

            context "that is an email address" do
              let(:recipient_login) { "foo@bar.com" }

              it_behaves_like 'creates notification' do
                let(:notification_channel_reasons) do
                  {
                    read_ian: false,
                    reason_ian: :mentioned,
                    read_mail: false,
                    reason_mail: :mentioned,
                    read_mail_digest: false,
                    reason_mail_digest: :mentioned
                  }
                end
              end
            end
          end

          context "The added text contains a user ID" do
            let(:note) { "Hello user##{recipient.id}" }

            it_behaves_like 'creates notification' do
              let(:notification_channel_reasons) do
                {
                  read_ian: false,
                  reason_ian: :mentioned,
                  read_mail: false,
                  reason_mail: :mentioned,
                  read_mail_digest: false,
                  reason_mail_digest: :mentioned
                }
              end
            end
          end

          context "The added text contains a user mention tag in one way" do
            let(:note) do
              <<~NOTE
                Hello <mention class="mention" data-id="#{recipient.id}" data-type="user" data-text="@#{recipient.name}">@#{recipient.name}</mention>
              NOTE
            end

            it_behaves_like 'creates notification' do
              let(:notification_channel_reasons) do
                {
                  read_ian: false,
                  reason_ian: :mentioned,
                  read_mail: false,
                  reason_mail: :mentioned,
                  read_mail_digest: false,
                  reason_mail_digest: :mentioned
                }
              end
            end
          end

          context "The added text contains a user mention tag in the other way" do
            let(:note) do
              <<~NOTE
                Hello <mention class="mention" data-type="user" data-id="#{recipient.id}" data-text="@#{recipient.name}">@#{recipient.name}</mention>
              NOTE
            end

            it_behaves_like 'creates notification' do
              let(:notification_channel_reasons) do
                {
                  read_ian: false,
                  reason_ian: :mentioned,
                  read_mail: false,
                  reason_mail: :mentioned,
                  read_mail_digest: false,
                  reason_mail_digest: :mentioned
                }
              end
            end
          end

          context "the recipient turned off mention notifications" do
            let(:recipient_notification_settings) do
              [
                FactoryBot.build(:mail_notification_setting, mentioned: false),
                FactoryBot.build(:mail_digest_notification_setting, mentioned: false),
                FactoryBot.build(:in_app_notification_setting, mentioned: false)
              ]
            end

            let(:note) do
              "Hello user:\"#{recipient.login}\", hey user##{recipient.id}"
            end

            it_behaves_like 'creates no notification'
          end
        end

        context "mentioned user is not allowed to view the work package" do
          let(:role) { FactoryBot.create(:role, permissions: []) }
          let(:note) do
            "Hello user:#{recipient.login}, hey user##{recipient.id}"
          end

          it_behaves_like 'creates no notification'
        end
      end

      context 'for groups' do
        let(:group_role) { FactoryBot.create(:role, permissions: %i[view_work_packages]) }
        let(:group) do
          FactoryBot.create(:group, members: recipient) do |group|
            Members::CreateService
              .new(user: nil, contract_class: EmptyContract)
              .call(project: project, principal: group, roles: [group_role])
          end
        end

        context 'on a hash/id based mention' do
          let(:note) do
            "Hello group##{group.id}"
          end

          it_behaves_like 'group mention'
        end

        context 'on a tag based mention with the type after' do
          let(:note) do
            <<~NOTE
              Hello <mention class="mention" data-id="#{group.id}" data-type="group" data-text="@#{group.name}">@#{group.name}</mention>
            NOTE
          end

          it_behaves_like 'group mention'
        end

        context 'on a tag based mention with the type before' do
          let(:note) do
            <<~NOTE
              Hello <mention data-type="group" class="mention" data-id="#{group.id}" data-text="@#{group.name}">@#{group.name}</mention>
            NOTE
          end

          it_behaves_like 'group mention'
        end
      end
    end

    context 'in the journal notes' do
      let(:journal) { journal_2_with_notes }
      let(:journal_2_with_notes) do
        work_package.add_journal author, note
        work_package.save(validate: false)
        work_package.journals.last
      end

      it_behaves_like 'mentioned'
    end

    context 'in the description' do
      let(:journal) { journal_2_with_description }
      let(:journal_2_with_description) do
        work_package.description = note
        work_package.save(validate: false)
        work_package.journals.last
      end

      it_behaves_like 'mentioned'
    end

    context 'in the subject' do
      let(:journal) { journal_2_with_subject }
      let(:journal_2_with_subject) do
        work_package.subject = note
        work_package.save(validate: false)
        work_package.journals.last
      end

      it_behaves_like 'mentioned'
    end
  end

  context 'when aggregated journal is empty' do
    let(:journal) { journal_2_empty_change }
    let(:journal_2_empty_change) do
      work_package.add_journal(author, 'temp')
      work_package.save(validate: false)
      work_package.journals.last.tap do |j|
        j.update_column(:notes, nil)
      end
    end

    it_behaves_like 'creates no notification'
  end
end

describe 'initialization' do
  it 'subscribes the listener' do
    allow(Notifications::JournalWpNotificationService)
      .to receive(:call)

    OpenProject::Notifications.send(
      OpenProject::Events::AGGREGATED_WORK_PACKAGE_JOURNAL_READY,
      journal: FactoryBot.build(:journal)
    )

    expect(Notifications::JournalWpNotificationService)
      .to have_received(:call)
  end
end
# rubocop:enable Rspec/MultipleMemoizedHelpers
