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

module TwoFactorAuthentication
  class UseBackupCodeService
    attr_reader :user

    ##
    # Create a token service for the given user.
    def initialize(user:)
      @user = user
    end

    ##
    # Validate a backup code that was input by the user
    def verify(code)
      token = user.otp_backup_codes.find_by_plaintext_value(code)

      raise I18n.t("two_factor_authentication.error_invalid_backup_code") if token.nil?

      use_valid_token! token
    rescue StandardError => e
      Rails.logger.error "[2FA plugin] Error during backup code validation for user##{user.id}: #{e}"

      result = ServiceResult.failure
      result.errors.add(:base, e.message)

      result
    end

    private

    def use_valid_token!(token)
      token.destroy!

      Rails.logger.info { "[2FA plugin] User ##{user.id} has used backup code." }
      ServiceResult.success(result: token)
    end
  end
end
