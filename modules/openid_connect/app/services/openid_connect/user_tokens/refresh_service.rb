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

module OpenIDConnect
  module UserTokens
    class RefreshService
      include Dry::Monads::Result(TokenOperationError)
      include Dry::Monads::Do.for(:call)

      def initialize(user:, token_exchange:)
        @user = user
        @token_exchange = token_exchange
      end

      def call(token)
        return exchange_instead_of_refresh(token) if token.refresh_token.blank?

        json = yield refresh_token_request(token.refresh_token)
        access_token, refresh_token, expires_in = json.values_at("access_token",  "refresh_token", "expires_in")
        return failure_with(code: :token_refresh_response_invalid, payload: json) if access_token.blank?

        token.update!(access_token:, refresh_token:, expires_at: expires_in&.seconds&.from_now)
        Success(token)
      end

      private

      def error = TokenOperationError.new(source: self.class)

      def failure_with(**) = Failure(error.with(**))

      def exchange_instead_of_refresh(token)
        # We can attempt a token exchange instead of a refresh, if we previously exchanged the token.
        # For simplicity, we do not consider scenarios where the original token had a wider audience,
        # because all tokens obtained through exchange in this service will have exactly one audience.
        if @token_exchange.supported? && token.audiences.size == 1
          @token_exchange.call(token.audiences.first)
        else
          failure_with(code: :unable_to_exchange_token)
        end
      end

      def refresh_token_request(refresh_token)
        TokenRequest.new(provider:).refresh(refresh_token).alt_map do
          it.with(code: :"token_refresh_#{it.code}", source: self.class)
        end
      end

      def provider
        @user.authentication_provider
      end
    end
  end
end
