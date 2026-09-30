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

module Token
  class AutoLogin < HashedToken
    include ExpirableToken

    prefix :opal

    has_many :autologin_session_links,
             class_name: "Sessions::AutologinSessionLink",
             foreign_key: "token_id",
             dependent: :destroy,
             inverse_of: :token

    ##
    # Set validity time for autologin tokens
    def self.validity_time
      Setting.autologin.days
    end

    ##
    # Find a valid autologin token from the given value.
    # Validates the token by checking its expiration date and the user status.
    #
    # @param key [String] The plaintext token value
    # @return [Token::AutoLogin, nil] The valid token or nil if not
    def self.find_valid_token(key)
      return if key.blank?

      token = find_by_plaintext_value(key)

      return if token.nil?
      return if token.expired?
      return unless token.user&.active?

      token
    end

    protected

    ##
    # Autologin tokens might have multiple data
    def single_value?
      false
    end
  end
end
