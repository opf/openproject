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
require_relative './create_from_journal_job_shared'

describe Notifications::CreateFromModelService,
         'work_package',
         with_settings: { journal_aggregation_time_minutes: 0 } do
  subject(:call) do
    described_class.new(journal).call(send_notifications)
  end

  include_context 'with CreateFromJournalJob context'

  let(:permissions) { [:view_work_packages] }
  let(:author) { user_property == :author ? recipient : other_user }
  let(:user_property) { nil }
  let(:work_package) do
    wp_attributes = {
      project: project,
      author: other_user,
      responsible: other_user,
      assigned_to: other_user,
      type: project.types.first
    }

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
  let(:resource) { work_package }
  let(:journal) { work_package.journals.first }
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

  context 'when user is assignee' do
    let(:user_property) { :assigned_to }
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true)),
        FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true)),
        FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true))
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

    context 'when assignee has in app notifications disabled' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: false, all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: false)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'assignee has all in app notifications enabled but only involved for mail' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: false, all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true))
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
      let(:permissions) { [] }

      it_behaves_like 'creates no notification'
    end

    context 'assignee is placeholder user' do
      let(:recipient) { FactoryBot.create :placeholder_user }

      it_behaves_like 'creates no notification'
    end

    context 'when assignee has all notifications enabled but made the change himself and has deactivated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true, all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true, all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: false, all: true))
        ]
      end
      let(:author) { recipient }

      it_behaves_like 'creates no notification'
    end

    context 'when assignee has all notifications enabled, made the change himself and has activated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true, all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true, all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true, all: true))
        ]
      end
      let(:author) { recipient }
      let(:recipient_no_self_notified) { false }

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

  context 'when user is responsible' do
    let(:user_property) { :responsible }
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: true)),
        FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true)),
        FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(involved: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(involved: false, all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(all: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(involved: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when responsible is not allowed to view work packages' do
      let(:permissions) { [] }

      it_behaves_like 'creates no notification'
    end

    context 'when responsible is placeholder user' do
      let(:recipient) { FactoryBot.create :placeholder_user }

      it_behaves_like 'creates no notification'
    end

    context 'when responsible has all notifications enabled but made the change himself and has deactivated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: true, all: true),
          FactoryBot.build(:mail_digest_notification_setting, involved: true, all: true),
          FactoryBot.build(:in_app_notification_setting, involved: true, all: true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like 'creates no notification'
    end

    context 'when responsible has all notifications enabled, made the change himself and has activated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, involved: true, all: true),
          FactoryBot.build(:mail_digest_notification_setting, involved: true, all: true),
          FactoryBot.build(:in_app_notification_setting, involved: true, all: true)
        ]
      end
      let(:author) { recipient }
      let(:recipient_no_self_notified) { false }

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

  context 'when user is watcher' do
    let(:user_property) { :watcher }
    let(:recipient_notification_settings) do
      [
        FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
        FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
        FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when watcher is not allowed to view work packages' do
      let(:permissions) { [] }

      it_behaves_like 'creates no notification'
    end

    context 'when watcher has all notifications enabled but made the change himself and has deactivated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true, all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true, all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true, all: true))
        ]
      end
      let(:author) { recipient }

      it_behaves_like 'creates no notification'
    end

    context 'when watcher has all notifications enabled, made the change himself and has activated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(watched: true, all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(watched: true, all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(watched: true, all: true))
        ]
      end
      let(:author) { recipient }
      let(:recipient_no_self_notified) { false }

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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false)
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(all: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'with all disabled as a default but enabled in the project' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_notification_setting, project: project, **notification_settings_all_false.merge(all: true)),
          FactoryBot.build(:mail_digest_notification_setting, project: project, **notification_settings_all_false
                                                                                    .merge(all: true)),
          FactoryBot.build(:in_app_notification_setting, project: project, **notification_settings_all_false.merge(all: true))
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
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(all: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(all: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(all: true)),
          FactoryBot.build(:mail_notification_setting, project: project, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, project: project, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, project: project, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when not allowed to view work packages' do
      let(:permissions) { [] }

      it_behaves_like 'creates no notification'
    end

    context 'when recipient has all notifications enabled but made the change himself and has deactivated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: true),
          FactoryBot.build(:mail_digest_notification_setting, all: true),
          FactoryBot.build(:in_app_notification_setting, all: true)
        ]
      end
      let(:author) { recipient }

      it_behaves_like 'creates no notification'
    end

    context 'when recipient has all notifications enabled, made the change himself and has activated self notification' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, all: true),
          FactoryBot.build(:mail_digest_notification_setting, all: true),
          FactoryBot.build(:in_app_notification_setting, all: true)
        ]
      end
      let(:author) { recipient }
      let(:recipient_no_self_notified) { false }

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
  end

  context 'when a work package is created' do
    context 'when the user configured to be notified on work package creation' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_created: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_created: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_created: true))
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :created,
            read_mail: false,
            reason_mail: :created,
            read_mail_digest: false,
            reason_mail_digest: :created
          }
        end
      end
    end

    context 'when the user configured to be notified on work package status changes' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_processed: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_processed: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_processed: true))
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when the user configured to be notified on work package priority changes' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_prioritized: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_prioritized: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_prioritized: true))
        ]
      end

      it_behaves_like 'creates no notification'
    end

    context 'when the user did not configure to be notified' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has a note' do
    let(:journal) { journal_2_with_notes }

    context 'when the user has commented notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_commented: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_commented: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_commented: true))
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :commented,
            read_mail: false,
            reason_mail: :commented,
            read_mail_digest: false,
            reason_mail_digest: :commented
          }
        end
      end
    end

    context 'when the user has commented notifications deactivated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has no note' do
    let(:journal) { journal_2_with_status }

    context 'with the user having commented notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_commented: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_commented: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_commented: true))
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has status update' do
    let(:journal) { journal_2_with_status }

    context 'when the user has processed notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_processed: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_processed: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_processed: true))
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :processed,
            read_mail: false,
            reason_mail: :processed,
            read_mail_digest: false,
            reason_mail_digest: :processed
          }
        end
      end
    end

    context 'when the user has processed notifications deactivated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has no status update' do
    let(:journal) { journal_2_with_notes }

    context 'with the user having processed notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_processed: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_processed: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_processed: true))
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has priority' do
    let(:journal) { journal_2_with_priority }

    context 'when the user has prioritized notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_prioritized: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_prioritized: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_prioritized: true))
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :prioritized,
            read_mail: false,
            reason_mail: :prioritized,
            read_mail_digest: false,
            reason_mail_digest: :prioritized
          }
        end
      end
    end

    context 'when the user has prioritized notifications deactivated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has no priority update' do
    let(:journal) { journal_2_with_status }

    context 'with the user having prioritized notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_prioritized: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_prioritized: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_prioritized: true))
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has a start date update' do
    let(:journal) { journal_2_with_start_date }

    context 'when the user has scheduled notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_scheduled: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_scheduled: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_scheduled: true))
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :scheduled,
            read_mail: false,
            reason_mail: :scheduled,
            read_mail_digest: false,
            reason_mail_digest: :scheduled
          }
        end
      end
    end

    context 'when the user has scheduled notifications deactivated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has no start or due date update' do
    let(:journal) { journal_2_with_notes }

    context 'with the user having scheduled notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_scheduled: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_scheduled: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_processed: true))
        ]
      end

      it_behaves_like 'creates no notification'
    end
  end

  context 'when the journal has a due date update' do
    let(:journal) { journal_2_with_due_date }

    context 'when the user has scheduled notifications activated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false
                                                           .merge(work_package_scheduled: true)),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false
                                                             .merge(work_package_scheduled: true)),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false
                                                                  .merge(work_package_scheduled: true))
        ]
      end

      it_behaves_like 'creates notification' do
        let(:notification_channel_reasons) do
          {
            read_ian: false,
            reason_ian: :scheduled,
            read_mail: false,
            reason_mail: :scheduled,
            read_mail_digest: false,
            reason_mail_digest: :scheduled
          }
        end
      end
    end

    context 'when the user has scheduled notifications deactivated' do
      let(:recipient_notification_settings) do
        [
          FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
          FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
        ]
      end

      it_behaves_like 'creates no notification'
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
        FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(mentioned: true)),
        FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(mentioned: true)),
        FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(mentioned: true))
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
              FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(mentioned: false)),
              FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(mentioned: false)),
              FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(mentioned: false))
            ]
          end

          it_behaves_like 'creates no notification'
        end
      end

      context 'group is not allowed to view the work package' do
        let(:group_role) { FactoryBot.create(:role, permissions: []) }
        let(:permissions) { [] }

        it_behaves_like 'creates no notification'

        context 'but group member is allowed individually' do
          let(:permissions) { [:view_work_packages] }

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
      context 'with users' do
        context "when the added text contains a login name as a pretty normal word" do
          let(:note) { "Hello user:\"#{recipient_login}\"" }

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

        context "when the added text contains an email login" do
          let(:note) { "Hello user:\"#{recipient_login}\"" }
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

        context "when the added text contains a user ID" do
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

        context "when the added text contains a user mention tag in one way" do
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

        context "when the added text contains a user mention tag in the other way" do
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

        context "when the recipient turned off mention notifications" do
          let(:recipient_notification_settings) do
            [
              FactoryBot.build(:mail_notification_setting, **notification_settings_all_false.merge(mentioned: false)),
              FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false.merge(mentioned: false)),
              FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false.merge(mentioned: false))
            ]
          end

          let(:note) do
            "Hello user:\"#{recipient.login}\", hey user##{recipient.id}"
          end

          it_behaves_like 'creates no notification'
        end

        context "with the mentioned user not being allowed to view the work package" do
          let(:permissions) { [] }
          let(:note) do
            "Hello user:#{recipient.login}, hey user##{recipient.id}"
          end

          it_behaves_like 'creates no notification'
        end

        context 'when the mentioned user made the change himself and has deactivated self notification' do
          let(:note) do
            "Hello user:#{recipient.login}, hey user##{recipient.id}"
          end
          let(:author) { recipient }

          it_behaves_like 'creates no notification'
        end

        context 'when the mentioned user made the change himself, but has activated self notification' do
          let(:note) do
            "Hello user:#{recipient.login}, hey user##{recipient.id}"
          end
          let(:author) { recipient }
          let(:recipient_no_self_notified) { false }

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

      context 'for groups' do
        let(:group_role) { FactoryBot.create(:role, permissions: %i[view_work_packages]) }
        let(:group) do
          FactoryBot.create(:group, members: recipient) do |group|
            Members::CreateService
              .new(user: User.system, contract_class: EmptyContract)
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

        context 'with the group member making the change himself and having deactivated self notification' do
          let(:note) do
            <<~NOTE
              Hello <mention class="mention" data-id="#{group.id}" data-type="group" data-text="@#{group.name}">@#{group.name}</mention>
            NOTE
          end
          let(:author) { recipient }

          it_behaves_like 'creates no notification'
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

  context 'when the journal is deleted' do
    before do
      journal.destroy
    end

    it_behaves_like 'creates no notification'
  end
end
