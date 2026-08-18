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

RSpec.describe OpenProject::MailRecipientLimit do
  describe ".allow?" do
    context "when the limit is 0" do
      it "allows every address without writing rows" do
        expect do
          expect(described_class.allow?("one@example.com")).to be true
          expect(described_class.allow?("two@example.com")).to be true
        end.not_to change(OutboundMailRecipient, :count)
      end
    end

    context "when a limit is configured", with_settings: { mail_recipient_limits: 2 } do
      it "allows the same address repeatedly without consuming extra slots" do
        expect(described_class.allow?("one@example.com")).to be true
        expect(described_class.allow?("ONE@example.com")).to be true
        expect(described_class.allow?("two@example.com")).to be true
        expect(described_class.allow?("three@example.com")).to be false
      end

      it "extracts the address from a display-name mailbox" do
        expect(described_class.allow?("User <one@example.com>")).to be true
        expect(described_class.allow?("one@example.com")).to be true
        expect(described_class.allow?("two@example.com")).to be true
        expect(described_class.allow?("three@example.com")).to be false
      end

      it "does not count recipients from previous days" do
        create(:outbound_mail_recipient, mail: "old@example.com", sent_on: Date.yesterday)

        expect(described_class.allow?("one@example.com")).to be true
        expect(described_class.allow?("two@example.com")).to be true
        expect(described_class.allow?("three@example.com")).to be false
      end

      it "treats a concurrent insert of the same address as allowed" do
        create(:outbound_mail_recipient, mail: "one@example.com")

        scope = instance_double(ActiveRecord::Relation, exists?: false, count: 0)
        allow(OutboundMailRecipient).to receive(:on).and_return(scope)

        expect(described_class.allow?("one@example.com")).to be true
      end
    end
  end
end
