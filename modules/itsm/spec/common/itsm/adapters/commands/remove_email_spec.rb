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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe ITSM::Adapters::Commands::RemoveEmail do
  include_context "with a connected IMAP session"

  subject(:result) { described_class.call(session:, uid: 42) }

  let(:uidplus) { "UIDPLUS" }

  before do
    allow(imap).to receive_messages(uid_store: nil, uid_expunge: nil)
    allow(imap).to receive(:capable?) { |capability| capability == uidplus }
  end

  it "expunges only the given email" do
    expect(result).to be_success
    expect(imap).to have_received(:uid_store).with(42, "+FLAGS", [:Deleted])
    expect(imap).to have_received(:uid_expunge).with(42)
  end

  context "when the server cannot expunge single emails" do
    let(:uidplus) { nil }

    it "only flags the email as deleted" do
      expect(result).to be_success
      expect(imap).to have_received(:uid_store).with(42, "+FLAGS", [:Deleted])
      expect(imap).not_to have_received(:uid_expunge)
    end
  end

  context "when the connection drops" do
    before { allow(imap).to receive(:uid_store).and_raise(Errno::ECONNRESET) }

    it "reports the server as unreachable, naming the command" do
      expect(result.failure).to have_attributes(code: :unreachable, source: described_class)
    end
  end
end
