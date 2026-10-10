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
    # Shared cipher configuration for the collaboration token sent to the Hocuspocus server.
    # Including classes define `cipher_operation` ("encrypt" or "decrypt") for error messages.
    #
    # The Hocuspocus server decrypts the token with the same algorithm and the SHA256 digest
    # of the shared secret, so both directions must stay in sync.
    module TokenEncryptor
      ALGORITHM = "aes-256-gcm"

      private

      def message_encryptor
        ActiveSupport::MessageEncryptor.new(
          key,
          cipher: ALGORITHM,
          serializer: ActiveSupport::MessageEncryptor::NullSerializer
        )
      end

      def key
        @key ||= begin
          secret = Setting.collaborative_editing_hocuspocus_secret
          raise "Collaborative editing secret is not set. Cannot #{cipher_operation} token." if secret.blank?

          Digest::SHA256.digest(secret)
        end
      end
    end
  end
end
