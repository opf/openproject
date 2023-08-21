#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2023 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
#+

module OpenProject::OpenIDConnect
  module Hooks
    class Hook < OpenProject::Hook::Listener
      ##
      # Once the user has signed in and has an oidc session
      # we want to map that to the internal session
      def user_logged_in(context)
        session = context[:session]
        oidc_sid = session['omniauth.oidc_sid']
        return if oidc_sid.nil?

        ::OpenProject::OpenIDConnect::SessionMapper.handle_login(oidc_sid, session)
      end

      ##
      # Once omniauth has returned with an auth hash
      # persist the access token
      def omniauth_user_authorized(context)
        auth_hash = context[:auth_hash]
        controller = context[:controller]

        # fetch the access token if it's present
        access_token = auth_hash.fetch(:credentials, {})[:token]
        # put it into a cookie
        if controller && access_token
          controller.send(:cookies)[:_open_project_session_access_token] = {
            value: access_token,
            secure: !!Rails.configuration.force_ssl
          }
        end
      end
    end
  end
end
