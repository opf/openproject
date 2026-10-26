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

RSpec.describe ITSM::Adapters::AuthenticationStrategies::BasicAuth do
  subject(:strategy) { described_class.new(credentials) }

  let(:credentials) { ITSM::Mailbox::Credentials.new(username: "support@example.com", password: "secret") }
  let(:imap) { instance_double(Net::IMAP, login: nil) }
  let(:rejection) { Net::IMAP::TaggedResponse.new("RUBY0001", "NO", Net::IMAP::ResponseText.new(nil, "Authentication failed"), "") }

  it "logs in with the username and password" do
    expect(strategy.call(imap)).to be_success
    expect(imap).to have_received(:login).with("support@example.com", "secret")
  end

  context "when the server rejects the login" do
    before { allow(imap).to receive(:login).and_raise(Net::IMAP::NoResponseError.new(rejection)) }

    it "fails with authentication_failed" do
      expect(strategy.call(imap).failure.code).to eq(:authentication_failed)
    end
  end

  it "hides the password when inspected" do
    expect(strategy.inspect).not_to include("secret")
  end
end
