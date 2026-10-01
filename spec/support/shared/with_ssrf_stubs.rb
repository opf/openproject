# frozen_string_literal: true

#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module WithSsrfStubsMixin
  ##
  # A safe public IP returned by the stubbed resolver for any hostname.
  # It is not in SsrfFilter's private-address blocklist, so SSRF validation passes.
  # ssrf_filter 1.3+ makes requests to the original hostname URL (not the resolved IP),
  # passing the resolved IP via the `ipaddr:` option to Net::HTTP.start instead.
  SSRF_TEST_IP = "93.184.216.34"

  def ip_address?(host)
    [Resolv::IPv4::Regex, Resolv::IPv6::Regex].any? { host.match? it }
  end
end

RSpec.shared_context "with ssrf stubs" do
  include WithSsrfStubsMixin

  before do
    safe_ip = IPAddr.new(WithSsrfStubsMixin::SSRF_TEST_IP)
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(
      ->(hostname) { ip_address?(hostname) ? [IPAddr.new(hostname)] : [safe_ip] }
    )
  end
end
