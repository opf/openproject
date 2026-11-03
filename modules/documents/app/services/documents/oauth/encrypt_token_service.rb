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

module Documents
  module OAuth
    class EncryptTokenService < BaseServices::BaseCallable
      ALGORITHM = "aes-256-gcm"

      def initialize(token:)
        super()

        @token = token
      end

      def perform
        encryptor = ActiveSupport::MessageEncryptor.new(
          key,
          cipher: ALGORITHM,
          serializer: ActiveSupport::MessageEncryptor::NullSerializer
        )
        encrypted = encryptor.encrypt_and_sign(token)

        ServiceResult.success(result: encrypted)
      rescue StandardError => e
        ServiceResult.failure(errors: e)
      end

      private

      attr_reader :token

      def key
        @key ||= begin
          secret = Setting.collaborative_editing_hocuspocus_secret
          raise "Collaborative editing secret is not set. Cannot encrypt token." if secret.blank?

          Digest::SHA256.digest(secret)
        end
      end
    end
  end
end
