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

module OpenIDConnect
  module UserTokens
    class CreateService
      def initialize(user, jwt_parser: JwtParser.new(verify_audience: false, required_claims: ["aud"]))
        @user = user
        @jwt_parser = jwt_parser
      end

      def call(access_token:, refresh_token: nil, known_audiences: [], clear_previous: false, expires_in: nil)
        if access_token.blank?
          Rails.logger.error("Could not associate token to user: No access token")
          return
        end

        if @user.nil?
          Rails.logger.error("Could not associate token to user: Can't find user")
          return
        end

        @user.oidc_user_tokens.destroy_all if clear_previous

        token = prepare_token(access_token:, refresh_token:, known_audiences:, expires_in:)
        token.save! if token.audiences.any?
      end

      private

      def prepare_token(access_token:, refresh_token:, expires_in:, known_audiences:)
        expires_at = expires_in&.seconds&.from_now
        @user.oidc_user_tokens.build(access_token:, refresh_token:, expires_at:).tap do |token|
          token.audiences = merge_audiences(known_audiences, discover_audiences(access_token).value_or([]))
        end
      end

      def discover_audiences(access_token)
        @jwt_parser.parse(access_token).fmap { |decoded, _| Array(decoded["aud"]) }
      end

      def merge_audiences(*args)
        args.flatten.uniq
      end
    end
  end
end
