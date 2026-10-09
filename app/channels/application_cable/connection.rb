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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ApplicationCable
  # Authenticates WebSocket and SSE connections from the session cookie, which AnyCable
  # forwards over RPC. Subscriptions are authorized by anycable-go itself via Turbo's
  # signed stream names, so no channel classes are needed.
  class Connection < ActionCable::Connection::Base
    include OpenProject::Authentication::SessionExpiration

    identified_by :current_user

    def connect
      self.current_user = find_session_user || reject_unauthorized_connection
    end

    private

    def find_session_user
      return if session_ttl_expired?

      User.active.find_by(id: session[:user_id])
    end

    def session
      request.session
    end
  end
end
