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

module My
  module AccessToken
    class NewAccessTokenDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      attr_reader :token_type

      def initialize(token_type: "api")
        super
        @token_type = token_type
      end

      DIALOG_ID = "new-access-token-dialog"

      private

      def new_token
        @new_token ||= build_token.tap do |token|
          set_default_expiry(token) if token.is_a?(Token::Expirable)
        end
      end

      def build_token
        case token_type
        when "api" then Token::API.new
        when "ical_meeting" then Token::ICalMeeting.new
        end
      end

      def set_default_expiry(token)
        token.user = User.current
        token.expires_on_date = token.user.time_zone.today + Token::Expirable::DEFAULT_EXPIRY
      end

      def i18n_scope
        [:my, :access_token, :dialog, new_token.model_name.i18n_key]
      end
    end
  end
end
