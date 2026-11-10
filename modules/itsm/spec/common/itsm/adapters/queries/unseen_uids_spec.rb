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

RSpec.describe ITSM::Adapters::Queries::UnseenUids do
  include_context "with a connected IMAP session"

  after { session.close }

  subject(:result) { described_class.call(session:, limit:) }

  let(:limit) { 10 }

  before { allow(imap).to receive(:uid_search).with(%w[UNSEEN UNDELETED]).and_return([3, 1]) }

  it "returns the unread emails that are not flagged as deleted, oldest first" do
    expect(result).to eq(Dry::Monads::Success([1, 3]))
  end

  context "when the server lists more emails than the limit, newest first" do
    let(:limit) { 50 }

    before { allow(imap).to receive(:uid_search).and_return(60.downto(1).to_a) }

    it "returns the oldest ones up to the limit" do
      expect(result.value!).to eq((1..50).to_a)
    end
  end

  context "when the connection drops" do
    before { allow(imap).to receive(:uid_search).and_raise(IOError) }

    it "reports the server as unreachable, naming the query" do
      expect(result.failure).to have_attributes(code: :unreachable, source: described_class)
    end
  end

  context "when the server answers with an error" do
    before { allow(imap).to receive(:uid_search).and_raise(Net::IMAP::NoResponseError.new(imap_rejection)) }

    it "reports a server error" do
      expect(result.failure.code).to eq(:server_error)
    end
  end
end
