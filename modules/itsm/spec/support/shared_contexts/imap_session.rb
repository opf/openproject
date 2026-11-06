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

RSpec.shared_context "with a connected IMAP session" do
  let(:imap_mail_server) { build(:itsm_mail_server, :imap) }
  let(:imap_credentials) { ITSM::Mailbox::Credentials.new(username: "support@example.com", password: "secret") }
  let(:imap_auth_strategy) { ITSM::Adapters::AuthenticationStrategies::BasicAuth.new(imap_credentials) }
  let(:imap) do
    instance_double(Net::IMAP, starttls: nil, login: nil, select: nil, logout: nil, disconnect: nil, disconnected?: false)
  end
  let(:imap_rejection) do
    Net::IMAP::TaggedResponse.new("RUBY0001", "NO", Net::IMAP::ResponseText.new(nil, "Rejected"), "")
  end
  let(:session) do
    ITSM::Adapters::ImapSession.new(mail_server: imap_mail_server, auth_strategy: imap_auth_strategy).tap(&:connect)
  end

  before do
    with_ssrf_ip_allowlist(["203.0.113.10"])
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [IPAddr.new("203.0.113.10")] })
    allow(Net::IMAP).to receive(:new).and_return(imap)
  end
end
