# frozen_string_literal: true

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

RSpec.describe Cron::ClearOutboundMailRecipientsJob, type: :job do
  it "is a no-op when the limit is disabled" do
    create(:outbound_mail_recipient, sent_on: Date.yesterday)

    expect { described_class.perform_now }.not_to change(OutboundMailRecipient, :count)
  end

  context "when the limit is enabled", with_settings: { mail_recipient_limits: 10 } do
    it "deletes recipients from previous days and keeps today's" do
      create(:outbound_mail_recipient, mail: "old@example.com", sent_on: Date.yesterday)
      today = create(:outbound_mail_recipient, mail: "today@example.com", sent_on: Date.current)

      described_class.perform_now

      expect(OutboundMailRecipient.all).to contain_exactly(today)
    end
  end
end
