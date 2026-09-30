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

# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
# Adapted to fit needs for mOTP
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

module Token
  class HashedToken < Base
    # Allow access to the plain value during initial access / creation of the token
    attr_reader :plain_value

    class << self
      def create_and_return_value(user)
        create!(user:).plain_value
      end

      ##
      # Find a token from the token value
      def find_by_plaintext_value(input)
        find_by(value: hash_function(input)) || find_and_upgrade_legacy_token(input)
      end

      def hash_function(input)
        # Use HMAC-SHA256 with a pepper stored in the database.
        # This protects low-entropy inputs (like backup codes) and allows
        # the pepper to survive secret_key_base changes.
        digest = OpenSSL::Digest.new("SHA256")
        OpenSSL::HMAC.hexdigest(digest, Setting.hashed_token_pepper, input)
      end

      ##
      # The previous hashing function used for tokens used the secret_key_base
      # as a fixed salt. This is fine to use, but results in tokens being invalidated
      # when we e.g., switch between on-premises and cloud instances, or move between servers.
      def legacy_hash_function(input)
        # Use a pepper for hashing token values.
        # We still want to be able to index the hash value for fast lookups,
        # so we need to determine the hash without knowing the associated user (and thus its salt) first.
        Digest::SHA256.hexdigest(input + Rails.application.secret_key_base)
      end

      private

      ##
      # When the token is hashed with the legacy hash function
      # upgrade it to the new token.
      def find_and_upgrade_legacy_token(input)
        find_by(value: legacy_hash_function(input))
          &.tap { it.update_column(:value, hash_function(input)) }
      end
    end

    delegate :hash_function, to: :class
    delegate :legacy_hash_function, to: :class

    def display_value
      plain_value.presence || I18n.t("token.hashed_token.display_value_placeholder")
    end

    ##
    # Validate the user input on the token
    # 1. The token is still valid
    # 2. The plain text matches either the new HMAC hash or the legacy hash
    def valid_plaintext?(input)
      valid_hash?(input) || valid_legacy_hash?(input)
    end

    private

    def valid_hash?(input)
      hashed_input = hash_function(input)
      ActiveSupport::SecurityUtils.secure_compare(hashed_input, value)
    end

    def valid_legacy_hash?(input)
      legacy_hashed_input = legacy_hash_function(input)
      ActiveSupport::SecurityUtils.secure_compare(legacy_hashed_input, value)
    end

    def initialize_values
      if new_record? && value.blank?
        @plain_value = self.class.generate_token_value
        self.value = hash_function(@plain_value)
      end
    end
  end
end
