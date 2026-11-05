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

module TestManagement
  # AES-256-GCM with a key derived from secret_key_base. Rotating secret_key_base makes stored
  # tokens unreadable (#decrypt returns nil). Deliberately not Redmine::Ciphering, which stores
  # plain text when no database cipher key is configured.
  module CiTokenCipher
    PREFIX = "tmv1:"
    KEY_SALT = "openproject test_management ci connection token"

    module_function

    def encrypt(plain, salt: KEY_SALT)
      return nil if plain.nil? || plain.to_s.empty?

      PREFIX + encryptor(salt).encrypt_and_sign(plain.to_s)
    end

    def decrypt(ciphertext, salt: KEY_SALT)
      return nil if ciphertext.blank? || !ciphertext.start_with?(PREFIX)

      encryptor(salt).decrypt_and_verify(ciphertext.delete_prefix(PREFIX))
    rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def encryptor(salt = KEY_SALT)
      key = Rails.application.key_generator.generate_key(salt, 32)
      ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: ActiveSupport::MessageEncryptor::NullSerializer)
    end
  end
end
