#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Users
  class LoginService
    attr_accessor :controller, :request

    delegate :session, to: :controller

    def initialize(controller:, request:)
      self.controller = controller
      self.request = request
    end

    def call(user)
      # retain custom session values
      retained_values = retain_sso_session_values!

      # retain flash values
      flash_values = controller.flash.to_h

      controller.reset_session

      flash_values.each { |k, v| controller.flash[k] = v }

      User.current = user

      ::Sessions::InitializeSessionService.call(user, session)

      session.merge!(retained_values) if retained_values

      user.log_successful_login

      after_login_hook(user)

      ServiceResult.success(result: user)
    end

    private

    def after_login_hook(user)
      context = { user:, request:, session: }

      OpenProject::Hook.call_hook(:user_logged_in, context)
    end

    def retain_sso_session_values!
      provider_name = session[:omniauth_provider]
      return unless provider_name

      provider = ::OpenProject::Plugins::AuthPlugin.find_provider_by_name(provider_name)
      return unless provider && provider[:retain_from_session]

      retained_keys = provider[:retain_from_session] + ['omniauth_provider']
      controller.session.to_h.slice(*retained_keys)
    end
  end
end
