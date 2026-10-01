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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  # An encrypting version of OpenProject::Cache. Should be used for caching values that should be kept
  # confidential to the application. Especially secrets such as access tokens, passwords an private keys
  # should not be cached in plain text, but through this cache accessor.
  module ConfidentialCache
    class << self
      delegate :delete, :clear, to: Cache

      # Rubocop wants to convert this to ... but we need the first positional args
      # for the delete case.
      # rubocop:disable Style/ArgumentsForwarding
      def fetch(*, **, &)
        fetch_and_decrypt(*, **, &)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        # Drop the unreadable value and recompute once. The recompute is a guaranteed
        # cache miss, so the second attempt returns the freshly computed plaintext
        # without decrypting. If it still raises, the error propagates rather than
        # looping, since this second attempt is not rescued.
        delete(*)
        fetch_and_decrypt(*, **, &)
      end
      # rubocop:enable Style/ArgumentsForwarding

      def read(name, **)
        ciphertext = Cache.read(name, **)
        return nil if ciphertext.blank?

        token_encryptor.decrypt_and_verify(ciphertext)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        # Drop values that can't be read, ensuring the cache heals from unreadable values
        delete(name)
        nil
      end

      def write(name, value, **)
        ciphertext = token_encryptor.encrypt_and_sign(value)
        Cache.write(name, ciphertext, **)
      end

      private

      # Reads the cached ciphertext and decrypts it, computing and storing an
      # encrypted value on a cache miss. On a miss we already hold the plaintext,
      # so we return it directly instead of decrypting what we just encrypted.
      def fetch_and_decrypt(*, **)
        recomputed = false
        value = nil

        ciphertext = Cache.fetch(*, **) do
          recomputed = true
          value = yield
          token_encryptor.encrypt_and_sign(value)
        end

        return value if recomputed

        token_encryptor.decrypt_and_verify(ciphertext)
      end

      def token_encryptor
        @token_encryptor ||= begin
          key = Rails.application.key_generator.generate_key("op-cache:confidential-values:v1", 32)
          # MessagePack avoids YAML's alias emission (which broke decryption for hashes
          # that reuse the same object for multiple keys, e.g. Saml::Provider#to_h) and,
          # unlike :message_pack_allow_marshal, never falls back to Marshal on load.
          ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: :message_pack)
        end
      end
    end
  end
end
