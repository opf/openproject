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

require "open_project/authentication/session_expiration"

module OpenProject
  module Authentication
    module Strategies
      module Warden
        ##
        # Temporary strategy necessary as long as the OpenProject authentication has
        # not been unified in terms of Warden strategies and is only locally
        # applied to the API v3.
        class Session < ::Warden::Strategies::Base
          include ::OpenProject::Authentication::SessionExpiration

          def valid?
            # A session must exist and valid
            return false if session.nil? || session_ttl_expired?

            # We allow GET requests on the API session
            # without headers (e.g., for images on attachments)
            return true if request.get?

            # For all other requests, to mitigate CSRF vectors,
            # require browser indication that this was a same-origin request
            same_origin?
          end

          def authenticate!
            user = user_id ? User.find(user_id) : User.anonymous

            success! user
          end

          def same_origin?
            request.env["HTTP_SEC_FETCH_SITE"] == "same-origin"
          end

          def user_id
            Hash(session)["user_id"]
          end

          def session
            env["rack.session"]
          end
        end
      end
    end
  end
end
