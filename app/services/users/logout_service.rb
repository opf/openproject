#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  class LogoutService
    attr_accessor :controller, :cookies

    def initialize(controller:)
      self.controller = controller
      self.cookies = controller.send(:cookies)
    end

    def call!(user)
      OpenProject.logger.info { "Logging out ##{user.id}" }

      if OpenProject::Configuration.drop_old_sessions_on_logout?
        remove_all_autologin_tokens! user
        remove_all_sessions! user
      else
        remove_matching_autologin_token! user
      end

      controller.reset_session

      User.current = User.anonymous
    end

    private

    def remove_all_sessions!(user)
      ::Sessions::UserSession.for_user(user.id).delete_all
    end

    def remove_all_autologin_tokens!(user)
      cookies.delete(OpenProject::Configuration.autologin_cookie_name)
      Token::AutoLogin.where(user_id: user.id).delete_all
    end

    def remove_matching_autologin_token!(user)
      value = cookies.delete(OpenProject::Configuration.autologin_cookie_name)
      return if value.blank?

      Token::AutoLogin
        .where(user:)
        .find_by_plaintext_value(value)&.destroy
    end
  end
end
