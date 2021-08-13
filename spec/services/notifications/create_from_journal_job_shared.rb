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

shared_context 'with CreateFromJournalJob context' do
  shared_let(:project) { FactoryBot.create(:project_with_types) }
  let(:permissions) { [] }
  let(:recipient) do
    FactoryBot.create(:user,
                      notification_settings: recipient_notification_settings,
                      member_in_project: project,
                      member_through_role: FactoryBot.create(:role, permissions: permissions),
                      login: recipient_login,
                      preferences: {
                        no_self_notified: recipient_no_self_notified
                      })
  end
  let(:recipient_login) { "johndoe" }
  let(:recipient_no_self_notified) { true }
  let(:other_user) do
    notification_settings = [
      FactoryBot.build(:mail_notification_setting, **notification_settings_all_false),
      FactoryBot.build(:in_app_notification_setting, **notification_settings_all_false),
      FactoryBot.build(:mail_digest_notification_setting, **notification_settings_all_false)
    ]

    FactoryBot.create(:user,
                      notification_settings: notification_settings)
  end
  let(:notification_settings_all_false) do
    {
      all: false,
      involved: false,
      watched: false,
      mentioned: false,
      work_package_commented: false,
      work_package_processed: false,
      work_package_created: false,
      work_package_scheduled: false,
      work_package_prioritized: false
    }
  end
  let(:recipient_notification_settings) do
    [
      FactoryBot.build(:mail_notification_setting, all: true),
      FactoryBot.build(:in_app_notification_setting, all: true),
      FactoryBot.build(:mail_digest_notification_setting, all: true)
    ]
  end
  let(:send_notifications) { true }

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
    let(:notification) { FactoryBot.build_stubbed(:notification) }

    it 'creates a notification and returns it' do
      notifications_service = instance_double(Notifications::CreateService)

      allow(Notifications::CreateService)
        .to receive(:new)
              .with(user: sender)
              .and_return(notifications_service)
      allow(notifications_service)
        .to receive(:call)
              .and_return(ServiceResult.new(success: true, result: notification))

      expect(call.all_results)
        .to match_array([notification])

      expect(notifications_service)
        .to have_received(:call)
              .with({ recipient_id: recipient.id,
                      project: project,
                      actor: sender,
                      journal: journal,
                      resource: resource }.merge(notification_channel_reasons))
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
end
