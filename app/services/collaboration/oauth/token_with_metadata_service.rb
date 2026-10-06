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

module Collaboration
  module OAuth
    class TokenWithMetadataService < BaseServices::BaseCallable
      attr_reader :user, :resource

      def initialize(user:, resource:)
        super()

        @user = user
        @resource = resource
      end

      def perform # rubocop:disable Metrics/AbcSize
        token_result = GenerateTokenService.new(user:).call

        if token_result.failure?
          Rails.logger.error("Failed to generate OAuth token for #{resource_label}: #{token_result.errors}")
          return token_result
        end

        access_token = token_result.result
        expires_at = access_token.expires_in.seconds.from_now.iso8601

        payload = {
          resource_url:,
          oauth_token: access_token.plaintext_token,
          expires_at:,
          readonly:
        }

        encrypted_result = EncryptTokenService.new(token: payload.to_json).call

        if encrypted_result.failure?
          Rails.logger.error("Failed to encrypt OAuth token payload for #{resource_label}: #{encrypted_result.errors}")
          return encrypted_result
        end

        ServiceResult.success(
          result: {
            encrypted_token: encrypted_result.result,
            resource_url:,
            readonly:,
            expires_at:,
            expires_in_seconds: access_token.expires_in
          }
        )
      end

      private

      def resource_url
        @resource_url ||= resource.collaboration_resource_url
      end

      def readonly
        @readonly ||= resource.collaboration_readonly_for?(user)
      end

      def resource_label
        "#{resource.model_name.singular} #{resource.id}"
      end
    end
  end
end
