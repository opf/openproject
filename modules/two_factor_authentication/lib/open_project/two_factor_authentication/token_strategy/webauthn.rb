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

require "webauthn"

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Webauthn < Base
      def verify(webauthn_credential, webauthn_challenge:, webauthn_relying_party:)
        # This will raise WebAuthn::Error
        credential = webauthn_relying_party.verify_authentication(
          webauthn_credential,
          webauthn_challenge,
          sign_count: device.webauthn_sign_count,
          public_key: device.webauthn_public_key
        )

        device.update!(webauthn_sign_count: credential.sign_count)
        true
      end

      def transmit_success_message
        nil
      end

      def self.mobile_token?
        false
      end

      def self.supported_channels
        [:webauthn]
      end

      def self.device_type
        :webauthn
      end

      def self.identifier
        :webauthn
      end

      private

      def send_webauthn
        Rails.logger.info { "[2FA] WebAuthn in progress for #{user.login}" }
        # Nothing to do here
      end
    end
  end
end
