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

describe Notifications::ScheduleJournalMailsService do
  subject(:call) { described_class.call(journal) }

  let(:mail_digest_before) { false }
  let(:notification) { FactoryBot.build_stubbed(:notification) }
  let(:journal) do
    FactoryBot.build_stubbed(:journal).tap do |j|
      allow(j)
        .to receive(:notifications)
              .and_return(notifications)
    end
  end
  let(:notifications) do
    [notification].tap do |n|
      allow(n)
        .to receive(:unread_mail)
              .and_return(unread_mail_notifications)

      allow(n)
        .to receive(:unread_mail_digest)
              .and_return(unread_mail_digest_notifications)
    end
  end
  let(:unread_mail_notifications) { [] }
  let(:unread_mail_digest_notifications) { [] }

  before do
    scope = double('scope')

    allow(Notification)
      .to receive(:mail_digest_before)
            .with(recipient: notification.recipient, time: notification.created_at)
            .and_return(scope)

    allow(scope)
      .to receive(:where)
            .and_return(scope)

    allow(scope)
      .to receive(:not)
            .and_return(scope)

    allow(scope)
      .to receive(:exists?)
            .and_return(mail_digest_before)

  end

  describe '#call', { with_settings: { notification_email_delay_minutes: 30 } } do
    context 'with notifications to be sent as mail' do
      let(:unread_mail_notifications) { [notification] }

      it 'schedules a delayed notification job' do
        allow(Time)
          .to receive(:now)
                .and_return(Time.now)

        expect { call }
          .to have_enqueued_job(Mails::NotificationJob)
                .with({ "_aj_globalid" => "gid://open-project/Notification/#{notification.id}" })
                .at(Time.now + Setting.notification_email_delay_minutes.minutes)
      end
    end

    context 'without notifications to be sent as mail' do
      let(:unread_mail_notifications) { [] }

      it 'schedules no delayed notification job' do
        expect { call }
          .not_to have_enqueued_job(Mails::NotificationJob)
      end
    end

    context 'with notifications to be sent as digest mail and no digest being scheduled before' do
      let(:unread_mail_digest_notifications) { [notification] }

      before do
        allow(notification.recipient)
          .to receive(:time_zone)
                .and_return(ActiveSupport::TimeZone['Tijuana'])
      end

      it 'schedules a digest mail job in the time zone of the recipient' do
        expected_time = ActiveSupport::TimeZone['Tijuana'].parse(Setting.notification_email_digest_time) + 1.day

        expect { subject }
          .to have_enqueued_job(Mails::DigestJob)
                .with({ "_aj_globalid" => "gid://open-project/User/#{notification.recipient.id}" })
                .at(expected_time)
      end
    end

    context 'with notifications to be sent as digest mail and a digest being scheduled before' do
      let(:unread_mail_digest_notifications) { [notification] }
      let(:mail_digest_before) { true }

      it 'schedules no digest mail job' do
        expect { subject }
          .not_to have_enqueued_job(Mails::DigestJob)
      end
    end

    context 'with no notification to be sent as digest mail' do
      let(:unread_mail_digest_notifications) { [] }

      it 'schedules no digest mail job' do
        expect { subject }
          .not_to have_enqueued_job(Mails::DigestJob)
      end
    end
  end
end
