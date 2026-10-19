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
  class BackupCode < ::Token::HashedToken
    class << self
      def regenerate!(user)
        backup_codes = []

        transaction do
          where(user_id: user.id).delete_all
          10.times do
            code = new(user:)
            code.save!
            backup_codes << code.plain_value
          end
        end

        backup_codes
      end

      ##
      # The default token value is 32 bytes in hex
      # which is a bit large for a one-use token
      def generate_token_value
        SecureRandom.hex(8)
      end
    end

    ##
    # Allows only a single value of the token?
    def single_value?
      false
    end
  end
end
