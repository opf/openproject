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

# This test disables WebMock and tests if the SquashTM client respects the SSRF protection in OpenProject.
RSpec.describe SquashTMIntegration::Client, "SSRF protection" do
  subject(:client) { described_class.new(base_url: "https://localhost:1/squash", api_token: "the-token") }

  it "blocks requests to a host that resolves to a private address", :aggregate_failures do
    expect { client.projects }.to raise_error(described_class::SsrfError)
    expect { client.requirement(1) }.to raise_error(described_class::SsrfError)
    expect { client.all_requirements(1) }.to raise_error(described_class::SsrfError)
    expect { client.test_case(1) }.to raise_error(described_class::SsrfError)
    expect { client.test_case_executions(1) }.to raise_error(described_class::SsrfError)
  end

  context "when the private address is allowlisted" do
    before do
      allow(OpenProject::Configuration).to receive(:ssrf_protection_ip_allowlist)
        .and_return([IPAddr.new("127.0.0.1"), IPAddr.new("::1")])
    end

    it "lets the request through to the host" do
      expect { client.projects }.to raise_error(described_class::ConnectionError) { |error|
        expect(error).not_to be_a(described_class::SsrfError)
      }
    end
  end
end
