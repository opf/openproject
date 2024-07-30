# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++
#

# A Cuprite edge-case with our use of select
# fields causes a Ferrum::JavaScriptError to be raised
# when an option HTMLElement is removed from its select field
#
# Use this as a temporary patch

require "ferrum/errors"

def ignore_ferrum_javascript_error
  yield
rescue Ferrum::JavaScriptError
end

# Override Ferrum::Network#pending_connections to only consider connections for current
# page. Any pending connection from previous loaded pages will be ignored as
# they have most likely be aborted anyway.

module Ferrum
  class Network
    class Request
      def loader_id
        @params["loaderId"]
      end
    end

    def pending_connections
      main_frame_id = @traffic.first&.request&.frame_id
      current_navigation = @traffic.reverse.find { |conn| conn.navigation_request?(main_frame_id) }
      current_traffic = @traffic.filter { |exchange| exchange.request.loader_id == current_navigation.request.loader_id }
      current_traffic.count(&:pending?)
    end
  end
end
