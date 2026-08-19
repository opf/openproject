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
    ##
    # Provides APIs to obtain access tokens of a given user for use at a third-party
    # application for which we know the audience name, which is typically the application's
    # client_id at an identity provider that OpenProject and the application have in common.
    class FetchService
      include Dry::Monads::Result(TokenOperationError)
      include Dry::Monads::Do.for(:access_token_for)

      TOKEN_OBTAINED_EVENT = "access_token_obtained"

      attr_reader :user

      def initialize(user:,
                     exchange_scope: nil,
                     jwt_parser: JwtParser.new(verify_audience: false, verify_expiration: false),
                     token_exchange: ExchangeService.new(user:, scope: exchange_scope),
                     token_refresh: RefreshService.new(user:, token_exchange:))
        @user = user
        @token_exchange = token_exchange
        @token_refresh = token_refresh
        @jwt_parser = jwt_parser
        @error = TokenOperationError.new(source: self.class)
      end

      ##
      # Obtains an access token that can be used to make requests in the user's name at the
      # remote service identified by the +audience+ parameter.
      #
      # The access token will be refreshed before being returned by this method, if it can be
      # identified as being expired. There is no guarantee that all access tokens will be properly
      # recognized as expired, so client's still need to make sure to handle rejected access tokens
      # properly. Also see #refreshed_access_token_for.
      #
      # A token exchange is attempted, if the provider supports OAuth 2.0 Token Exchange and a token
      # for the target audience either can't be found or it has expired, but has no available refresh token.
      def access_token_for(audience:)
        token = yield token_with_audience(audience)
        token = yield @token_refresh.call(token) if expired?(token)

        emit_event(token, audience)
        Success(token.access_token)
      end

      private

      def emit_event(token, audience)
        OpenProject::Notifications.send(TOKEN_OBTAINED_EVENT, audience:, token:)
      end

      def token_with_audience(aud)
        token = @user.oidc_user_tokens.with_audience(aud).first
        return Success(token) if token

        if @token_exchange.supported?
          @token_exchange.call(aud)
        else
          Failure(@error.with(code: :no_token_for_audience, payload: "No token for audience '#{aud}'"))
        end
      end

      def expired?(token)
        exp_time = expires_at(token)
        return false if exp_time.nil?

        exp_time.past?
      end

      def expires_at(token)
        return token.expires_at if token.expires_at.present?

        exp = @jwt_parser.parse(token.access_token).fmap { |decoded, _| decoded["exp"] }.value_or(nil)
        return nil if exp.nil?

        Time.zone.at(exp)
      end
    end
  end
end
