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

module OpenProject
  # An SSRF filter for HTTPX based on the original plugin.
  # See https://gitlab.com/os85/httpx/-/blob/master/lib/httpx/plugins/ssrf_filter.rb
  #
  # The main difference is that we use our own subclass of `SsrfFilter` to perform the matching of unsafe IP addresses.
  # We are thus consulting our own allow list of IP addresses before blocking an IP address.
  module HttpxSsrfFilter
    class ServerSideRequestForgeryError < HTTPX::Error; end

    module ConnectionMethods
      def initialize(*)
        super
      rescue ServerSideRequestForgeryError => e
        # may raise when IPs are passed as options via :addresses
        throw(:resolve_error, e)
      end

      def addresses=(addrs)
        addrs.reject! do |addr|
          # working around an error in IPAddr that fails to check address inclusion if the passed address is not an
          # IPAddr, but a SimpleDelegator to an IPAddr (like HTTPX::Resolver::Entry).
          addr = addr.address if addr.respond_to?(:address)

          SsrfProtection.send(:unsafe_ip_address?, addr)
        end

        raise ServerSideRequestForgeryError, "#{@origin.host} has no public IP addresses" if addrs.empty?

        super
      end
    end
  end
end
