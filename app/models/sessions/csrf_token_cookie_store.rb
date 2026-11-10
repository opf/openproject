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

module Sessions
  # This store is the Rails cookie store used only for the CSRF cookie
  # We want to take over the logic on the relative path
  class CsrfTokenCookieStore < ActionController::RequestForgeryProtection::CookieStore
    def self.cookie_name
      "#{OpenProject::Configuration['session_cookie_name']}_csrf"
    end

    def initialize
      super(self.class.cookie_name)
    end

    def store(request, csrf_token)
      request.cookie_jar.encrypted.permanent[self.class.cookie_name] = {
        value: { token: csrf_token, session_id: request.session.id }.to_json,
        httponly: true,
        same_site: :lax,
        secure:,
        path:
      }
    end

    def reset(request)
      request.cookie_jar.delete(self.class.cookie_name, path:, secure:)
    end

    private

    def secure
      OpenProject::Configuration.https?
    end

    def path
      OpenProject::Configuration["rails_relative_url_root"].presence || "/"
    end
  end
end
