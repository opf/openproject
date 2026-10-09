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

module OpenProject
  module OpenIDConnect
    module SsoLogout
      include ::OmniauthHelper

      def session_expired?
        super || (current_user.logged? && id_token_expired?)
      end

      ##
      # Upon reauthentication just return directly with HTTP 200 OK
      # and do not reset the session.
      # If not call super which will reset the session, set
      # the new user, and redirect to some page the script the
      # reauthentication doesn't care about.
      def successful_authentication(user, reset_stages: true)
        if reauthentication?
          finish_reauthentication!
        else
          super
        end
      end

      def logout
        if params.include? :script
          logout_user

          return finish_logout!
        end

        # If the user may view the site without being logged in we redirect back to it.
        site_open = !(Setting.login_required? && omniauth_direct_login?)
        return_url = site_open && "#{Setting.protocol}://#{Setting.host_name}"

        if logout_at_op! return_url
          logout_user
        else
          super
        end
      end
    end
  end
end
