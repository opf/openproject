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

      def fetch(*, **)
        ciphertext = Cache.fetch(*, **) { token_encryptor.encrypt_and_sign(yield) }

        token_encryptor.decrypt_and_verify(ciphertext)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        # Drop values that can't be read, ensuring the cache heals from unreadable values
        delete(*)
        retry
      end

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

      def token_encryptor
        @token_encryptor ||= begin
          key = Rails.application.key_generator.generate_key("op-cache:confidential-values:v1", 32)
          ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: YAML)
        end
      end
    end
  end
end
