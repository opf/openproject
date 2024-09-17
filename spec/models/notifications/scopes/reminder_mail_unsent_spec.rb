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

RSpec.describe Notifications::Scopes::MailReminderUnsent do
  describe ".unread_digest_mail" do
    subject(:scope) { Notification.mail_reminder_unsent }

    let(:no_mail_notification) { create(:notification, mail_reminder_sent: nil) }
    let(:unread_mail_notification) { create(:notification, mail_reminder_sent: false) }
    let(:read_mail_notification) { create(:notification, mail_reminder_sent: true) }

    before do
      no_mail_notification
      unread_mail_notification
      read_mail_notification
    end

    it "contains the notifications with read_mail: false" do
      expect(scope)
        .to contain_exactly(unread_mail_notification)
    end
  end
end
