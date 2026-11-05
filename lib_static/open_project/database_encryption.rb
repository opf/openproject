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

module OpenProject
  module DatabaseEncryption
    KEY_DERIVATION_SALT = "openproject/active_record_encryption"

    INSECURE_SECRETS = [
      "OVERWRITE_ME", # default value in Dockerfile
      "secret", # old sample from documentation
      "<your-secret-key-base>" # new sample from documentation
    ].freeze

    class << self
      def primary_keys
        # Rails encrypts with the last key and decrypts with all keys.
        [OpenProject::Configuration["database_encryption_previous_key"], secret_key_base, explicit_key].compact_blank
      end

      def current_key
        explicit_key.presence || secret_key_base
      end

      def insecure_secret?(value)
        value.blank? || INSECURE_SECRETS.include?(value)
      end

      def validate_secret!
        return unless Rails.env.production?
        return if ENV["OPENPROJECT_DISABLE__SECRET_KEY_BASE__CHECK"] == "true"
        return unless insecure_secret?(current_key)

        raise ArgumentError, <<~ERROR
          The key used to encrypt SCM and LDAP credentials is missing or a well-known default value.
          Set a strong, random SECRET_KEY_BASE or OPENPROJECT_DATABASE__ENCRYPTION__KEY before you migrate.
        ERROR
      end

      private

      def explicit_key
        OpenProject::Configuration["database_encryption_key"]
      end

      def secret_key_base
        Rails.application.secret_key_base
      end
    end
  end
end
