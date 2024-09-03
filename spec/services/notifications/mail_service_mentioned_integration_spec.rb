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
require_relative "mentioned_journals_shared"

RSpec.describe Notifications::MailService, "Mentioned integration", type: :model do
  include_context "with a mentioned work package being updated again"

  let(:assignee) do
    create(:user,
           preferences: {
             immediate_reminders: {
               mentioned: true
             }
           },
           notification_settings: [
             build(:notification_setting,
                   mentioned: true,
                   assignee: true,
                   responsible: true)
           ],
           member_with_roles: { project => role })
  end

  let(:assigned_notification) do
    Notification.find_by(recipient: assignee, journal: work_package.journals.last, reason: :assigned)
  end

  def expect_mentioned_notification
    expect(mentioned_notification).to be_present
    mentioned_notification.reload
    expect(mentioned_notification.recipient).to eq recipient
    expect(mentioned_notification.reason).to eq "mentioned"
    expect(mentioned_notification.read_ian).to be false
    expect(mentioned_notification.mail_alert_sent).to be true
  end

  def expect_no_assigned_notification
    expect(Notification.where(recipient:, resource: work_package, reason: :assignee))
      .to be_empty
  end

  def expect_no_responsible_notification
    expect(Notification.where(recipient:, resource: work_package, reason: :responsible))
      .to be_empty
  end

  def expect_assigned_notification
    expect(assigned_notification).to be_present
    expect(assigned_notification.recipient).to eq assignee
    expect(assigned_notification.read_ian).to be false
    expect(assigned_notification.mail_alert_sent).to be_nil
  end

  it "triggers only one mention notification mail when editing attributes afterwards" do
    allow(WorkPackageMailer)
      .to receive(:mentioned)
            .and_call_original

    trigger_comment!

    expect(WorkPackageMailer)
      .to have_received(:mentioned)
            .with(recipient, work_package.journals.last)
            .once

    expect_mentioned_notification

    update_assignee!(recipient)

    # No mailing is to be added but the mailing from before still counts.
    expect(WorkPackageMailer)
      .to have_received(:mentioned)
            .once

    # No assignee and responsible notification since the assignee is also mentioned which trumps
    # being assignee and a user will only get one notification for a journal.
    expect_no_assigned_notification
    expect_no_responsible_notification
    expect_mentioned_notification

    update_assignee!(assignee)

    # No mailing is to be added but the mailing from before still counts.
    expect(WorkPackageMailer)
      .to have_received(:mentioned)
            .once

    expect_assigned_notification
  end
end
