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

module OpenProject::TwoFactorAuthentication
  module TokenStrategy
    class Developer < Base
      def self.validate!
        if Rails.env.production?
          raise "You're trying to use the developer strategy in production. Don't!"
        end
      end

      def self.identifier
        :developer
      end

      def self.supported_channels
        %i[sms voice]
      end

      def self.mobile_token?
        true
      end

      def transmit_success_message
        I18n.t(:notice_developer_strategy_otp, token:, channel:)
      end

      private

      def send_sms
        Rails.logger.info { "[2FA] Mocked SMS token #{token} for #{user.login}" }
      end

      def send_voice
        Rails.logger.info { "[2FA] Mocked voice token #{token} for #{user.login}" }
      end
    end
  end
end
