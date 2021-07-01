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

describe Notifications::Scopes::MailDigestBefore, type: :model do
  describe '.mail_digest_before' do
    subject(:scope) { ::Notification.mail_digest_before(recipient: recipient, time: time) }

    let(:recipient) do
      FactoryBot.create(:user)
    end
    let(:time) do
      Time.current
    end

    let(:notification) do
      FactoryBot.create(:notification,
                        recipient: notification_recipient,
                        read_mail_digest: notification_read_mail_digest,
                        created_at: notification_created_at)
    end
    let(:notification_read_mail_digest) { false }
    let(:notification_created_at) { Time.current - 10.minutes }
    let(:notification_recipient) { recipient }

    let!(:notifications) { notification }

    shared_examples_for 'is empty' do
      it 'is empty' do
        expect(scope)
          .to be_empty
      end
    end

    context 'with a notification of the user for mail digests before the time' do
      it 'returns the notification' do
        expect(scope)
          .to match_array([notification])
      end
    end

    context 'with a notification of the user for mail digests after the time' do
      let(:notification_created_at) { Time.current + 10.minutes }

      it_behaves_like 'is empty'
    end

    context 'with a notification of a different user for mail digests before the time' do
      let(:notification_recipient) { FactoryBot.create(:user) }

      it_behaves_like 'is empty'
    end

    context 'with a notification of a different user not for mail digests before the time' do
      let(:notification_read_mail_digest) { nil }

      it_behaves_like 'is empty'
    end

    context 'with a notification of a different user for already covered mail digests before the time' do
      let(:notification_read_mail_digest) { true }

      it_behaves_like 'is empty'
    end
  end
end
