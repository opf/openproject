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

RSpec.describe ITSM::Adapters::CheckedAddresses, with_ssrf_ip_allowlist: %w[203.0.113.10 203.0.113.11] do
  subject(:result) { described_class.call("mail.example.com") }

  let(:addresses) { [IPAddr.new("203.0.113.10"), IPAddr.new("203.0.113.11")] }

  before { allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { addresses }) }

  it "returns every address of the host" do
    expect(result).to eq(Dry::Monads::Success(%w[203.0.113.10 203.0.113.11]))
  end

  context "when one of the addresses is private" do
    let(:addresses) { [IPAddr.new("203.0.113.10"), IPAddr.new("10.0.0.5")] }

    it "allows none of them" do
      expect(result.failure).to have_attributes(code: :address_not_allowed, source: described_class)
    end

    context "and it is on the allowlist", with_ssrf_ip_allowlist: %w[203.0.113.10 10.0.0.5] do
      it "returns every address of the host" do
        expect(result).to eq(Dry::Monads::Success(%w[203.0.113.10 10.0.0.5]))
      end
    end
  end

  context "when the host cannot be resolved" do
    let(:addresses) { [] }

    it "reports the host as unreachable" do
      expect(result.failure).to have_attributes(code: :unreachable, source: described_class)
    end
  end
end
