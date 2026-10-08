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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Documents
  module OAuth
    ##
    # Decrypts a collaboration token created by {EncryptTokenService}.
    #
    # Fails when the token was tampered with, was encrypted with another secret
    # or is not a valid encrypted message at all.
    class DecryptTokenService < BaseServices::BaseCallable
      include TokenEncryptor

      def initialize(token:)
        super()

        @token = token
      end

      def perform
        decrypted = message_encryptor.decrypt_and_verify(token.to_s)

        if decrypted.nil?
          ServiceResult.failure(message: "Token could not be decrypted.")
        else
          ServiceResult.success(result: decrypted)
        end
      rescue StandardError => e
        ServiceResult.failure(errors: e, message: "Token could not be decrypted.")
      end

      private

      attr_reader :token

      def cipher_operation
        "decrypt"
      end
    end
  end
end
