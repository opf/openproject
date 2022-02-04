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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'
require_relative './mentioned_journals_shared'


describe Notifications::MailService, 'Mentioned integration', type: :model do
  include_context 'with a mentioned work package being updated again'

  def expect_mentioned_notification
    expect(mentioned_notification).to be_present
    expect(mentioned_notification.reason).to eq 'mentioned'
    expect(mentioned_notification.read_ian).to eq false
    expect(mentioned_notification.mail_alert_sent).to eq true
  end

  def expect_mentioned_notification_updated
    old_journal_id = mentioned_notification.journal_id
    mentioned_notification.reload
    expect(mentioned_notification.journal_id).not_to eq old_journal_id
    expect(mentioned_notification.journal).to eq work_package.journals.last
    expect(mentioned_notification.reason).to eq 'mentioned'
    expect(mentioned_notification.read_ian).to eq false
    expect(mentioned_notification.mail_alert_sent).to eq true
  end

  def expect_assigned_notification
    expect(assigned_notification).to be_present
    expect(assigned_notification.read_ian).to eq false
    expect(assigned_notification.mail_alert_sent).to eq false
  end

  it 'will trigger only one mention notification mail when editing attributes afterwards' do
    allow(WorkPackageMailer)
      .to(receive(:mentioned))
      .and_call_original

    trigger_comment!

    expect(WorkPackageMailer)
      .to have_received(:mentioned)
      .with(recipient, work_package.journals.last)

    expect_mentioned_notification

    update_assignee!

    expect(WorkPackageMailer)
      .not_to have_received(:mentioned)
      .with(recipient, work_package.journals.last)

    expect_mentioned_notification_updated
    expect_assigned_notification
  end
end
