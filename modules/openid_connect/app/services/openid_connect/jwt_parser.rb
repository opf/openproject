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
  class JwtParser
    include Dry::Monads[:result]

    SUPPORTED_JWT_ALGORITHMS = %w[
      RS256
      RS384
      RS512
    ].freeze

    def initialize(verify_audience: true, verify_expiration: true, required_claims: [])
      @verify_audience = verify_audience
      @verify_expiration = verify_expiration
      @required_claims = required_claims
    end

    def parse(token)
      parse_unverified_iss_alg_kid(token).bind do |issuer, alg, kid|
        return Failure("Token signature algorithm #{alg} is not supported") if SUPPORTED_JWT_ALGORITHMS.exclude?(alg)

        fetch_provider(issuer).fmap do |provider|
          verified_payload, = JWT.decode(
            token,
            fetch_key(provider:, kid:),
            true,
            {
              algorithm: alg,
              verify_expiration: @verify_expiration,
              verify_aud: @verify_audience,
              aud: provider.client_id,
              required_claims: all_required_claims
            }
          )

          [verified_payload, provider]
        end
      rescue JWT::DecodeError => e
        Failure(e.message)
      rescue JSON::JWK::Set::KidNotFound
        Failure("The signature key ID is unknown")
      end
    end

    private

    def parse_unverified_iss_alg_kid(token)
      unverified_payload, unverified_header = JWT.decode(token, nil, false)
      return Failure("The token's Key Identifier (kid) is missing") unless unverified_header.key?("kid")

      Success([unverified_payload["iss"], unverified_header.fetch("alg"), unverified_header.fetch("kid")])
    rescue JWT::DecodeError => e
      Failure(e.message)
    end

    def fetch_provider(issuer)
      return Failure("The token has no issuer") if issuer.blank?

      provider = OpenIDConnect::Provider.where(available: true).where("options->>'issuer' = ?", issuer).first
      return Failure("The access token issuer is unknown") if provider.blank?
      return Failure("Unable to validate issuer signature, OpenID Connect provider has no JWKS URI.") if provider.jwks_uri.blank?

      Success(provider)
    end

    def fetch_key(provider:, kid:)
      JSON::JWK::Set::Fetcher.fetch(provider.jwks_uri, kid:).to_key
    end

    def all_required_claims
      claims = ["iss"] + @required_claims
      claims << "aud" if @verify_audience

      claims.uniq
    end
  end
end
