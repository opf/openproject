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

module ::TwoFactorAuthentication
  module My
    class SecuritySectionComponent < ViewComponent::Base
      def initialize(user:, cookies:)
        @user = user
        @cookies = cookies

        super()
      end

      def render?
        strategy_manager.enabled?
      end

      def before_render
        @default_device = @user.otp_devices.get_default
        @two_factor_devices = @user.otp_devices.reload
        @available_devices = strategy_manager.available_devices
        @has_remember_token_for_user = any_remember_token_present?
        @remember_token = current_remember_token
      end

      private

      def strategy_manager
        ::OpenProject::TwoFactorAuthentication::TokenStrategyManager
      end

      def any_remember_token_present?
        return false unless remember_2fa_enabled?

        ::TwoFactorAuthentication::RememberedAuthToken.not_expired.exists?(user: @user)
      end

      def current_remember_token
        return false unless remember_2fa_enabled?

        value = @cookies.encrypted[:op2fa_remember_token]
        return false if value.blank?

        ::TwoFactorAuthentication::RememberedAuthToken.where(user: @user).find_by_plaintext_value(value)
      end

      def remember_2fa_enabled?
        strategy_manager.allow_remember_for_days > 0
      end
    end
  end
end
