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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Notifications::Scopes::UnsentRemindersBefore, type: :model do
  describe '.unsent_reminders_before' do
    subject(:scope) { ::Notification.unsent_reminders_before(recipient: recipient, time: time) }

    let(:recipient) do
      create(:user)
    end
    let(:time) do
      Time.current
    end

    let(:notification) do
      create(:notification,
                        recipient: notification_recipient,
                        read_ian: notification_read_ian,
                        mail_reminder_sent: notification_mail_reminder_sent,
                        created_at: notification_created_at)
    end
    let(:notification_mail_reminder_sent) { false }
    let(:notification_read_ian) { false }
    let(:notification_created_at) { Time.current - 10.minutes }
    let(:notification_recipient) { recipient }

    let!(:notifications) { notification }

    shared_examples_for 'is empty' do
      it 'is empty' do
        expect(scope)
          .to be_empty
      end
    end

    context 'with a unread and not reminded notification that was created before the time and for the user' do
      it 'returns the notification' do
        expect(scope)
          .to match_array([notification])
      end
    end

    context 'with a unread and not reminded notification that was created after the time and for the user' do
      let(:notification_created_at) { Time.current + 10.minutes }

      it_behaves_like 'is empty'
    end

    context 'with a unread and not reminded notification that was created before the time and for different user' do
      let(:notification_recipient) { create(:user) }

      it_behaves_like 'is empty'
    end

    context 'with a unread and not reminded notification created before the time and for the user' do
      let(:notification_mail_reminder_sent) { nil }

      it_behaves_like 'is empty'
    end

    context 'with a unread but reminded notification created before the time and for the user' do
      let(:notification_mail_reminder_sent) { true }

      it_behaves_like 'is empty'
    end

    context 'with a read notification that was created before the time' do
      let(:notification_read_ian) { true }

      it_behaves_like 'is empty'
    end
  end
end
