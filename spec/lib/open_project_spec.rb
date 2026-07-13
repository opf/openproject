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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject do
  describe ".httpx" do
    subject(:httpx) { described_class.httpx }

    let(:public_endpoint) { "https://openproject.org/rspec-test" }
    let(:private_endpoint) { "https://localhost/rspec-test" }

    it "sets a proper User-Agent header", :webmock do
      stub_request(:get, public_endpoint).to_return(status: 204)

      httpx.get(public_endpoint)
      expect(WebMock).to have_requested(:get, public_endpoint)
        .with(headers: { "User-Agent": /OpenProject \d+\.\d+\.\d+ HTTPX Client/ })
    end

    # We can't use webmock for these tests, as it would interfere too early and thus we couldn't test
    # whether corresponding requests would've been made
    describe "SSRF filtering" do
      it "includes SSRF filtering for private IP addresses" do
        result = httpx.get(private_endpoint)
        expect(result.error).to be_a(OpenProject::HttpxSsrfFilter::ServerSideRequestForgeryError)
      end

      it "does not filter requests to public IP addresses" do
        result = httpx.get(public_endpoint)
        expect(result.error).to be_nil
      end

      context "when local IP addresses are allowed" do
        before do
          allow(OpenProject::Configuration).to receive(:ssrf_protection_ip_allowlist)
            .and_return([IPAddr.new("127.0.0.1"), IPAddr.new("::1")])
        end

        it "does not filter local requests" do
          result = httpx.get(private_endpoint)
          expect(result.error).not_to be_a(OpenProject::HttpxSsrfFilter::ServerSideRequestForgeryError)
        end
      end
    end
  end
end
