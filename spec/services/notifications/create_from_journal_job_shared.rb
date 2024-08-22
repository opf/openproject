#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.shared_context "with CreateFromJournalJob context" do
  shared_let(:project) { create(:project_with_types) }
  let(:permissions) { [] }
  let(:recipient) do
    create(:user,
           notification_settings: recipient_notification_settings,
           member_with_permissions: { project => permissions },
           login: recipient_login)
  end
  let(:recipient_login) { "johndoe" }
  let(:other_user) do
    notification_settings = [
      build(:notification_setting, **notification_settings_all_false)
    ]

    create(:user,
           notification_settings:)
  end
  let(:notification_settings_all_false) do
    NotificationSetting
      .all_settings
      .index_with(false)
  end

  let(:notification_settings_all_true) do
    NotificationSetting
      .all_settings
      .index_with(true)
  end

  let(:recipient_notification_settings) do
    [
      build(:notification_setting, **notification_settings_all_true)
    ]
  end
  let(:send_notifications) { true }

  shared_examples_for "creates notification" do
    let(:sender) { author }
    let(:notification_channel_reasons) do
      {
        read_ian: false,
        reason: :mentioned,
        mail_reminder_sent: false
      }
    end
    let(:notification) { build_stubbed(:notification) }

    it "creates a notification and returns it" do
      notifications_service = instance_double(Notifications::CreateService)

      allow(Notifications::CreateService)
        .to receive(:new)
              .with(user: sender)
              .and_return(notifications_service)
      allow(notifications_service)
        .to receive(:call)
              .and_return(ServiceResult.success(result: notification))

      expect(call.all_results)
        .to contain_exactly(notification)

      expect(notifications_service)
        .to have_received(:call)
              .with({ recipient_id: recipient.id,
                      actor: sender,
                      journal:,
                      resource: }.merge(notification_channel_reasons))
    end
  end

  shared_examples_for "creates no notification" do
    it "creates no notification" do
      allow(Notifications::CreateService)
        .to receive(:new)
              .and_call_original

      call

      expect(Notifications::CreateService)
        .not_to have_received(:new)
    end
  end
end
