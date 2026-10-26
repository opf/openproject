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

# Runs without WebMock so that the requests reach the SSRF filter of OpenProject.httpx,
# which checks the addresses a host resolves to on every connection.
RSpec.describe SquashTMIntegration::Client, "SSRF protection" do
  let(:server) do
    build(:squashtm_server, base_url: "https://localhost:1/squash").tap { it.save!(validate: false) }
  end

  subject(:client) { described_class.for(server) }

  it "blocks requests to a previously saved server that now resolves to a private address", :aggregate_failures do
    expect { client.projects }.to raise_error(described_class::SsrfError)
    expect { client.requirement(1) }.to raise_error(described_class::SsrfError)
    expect { client.all_requirements(1) }.to raise_error(described_class::SsrfError)
    expect { client.test_case(1) }.to raise_error(described_class::SsrfError)
    expect { client.test_case_executions(1) }.to raise_error(described_class::SsrfError)
  end
end
