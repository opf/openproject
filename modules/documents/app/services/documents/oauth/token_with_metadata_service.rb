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

module Documents
  module OAuth
    class TokenWithMetadataService < BaseServices::BaseCallable
      include API::V3::Utilities::PathHelper

      attr_reader :user, :document, :project

      def initialize(user:, document:, project:)
        super()

        @user = user
        @document = document
        @project = project
      end

      def perform # rubocop:disable Metrics/AbcSize
        token_result = GenerateTokenService.new(user:).call

        if token_result.failure?
          Rails.logger.error("Failed to generate OAuth token for document #{document.id}: #{token_result.errors}")
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
          Rails.logger.error("Failed to encrypt OAuth token payload for document #{document.id}: #{encrypted_result.errors}")
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
        @resource_url ||= URI.join(
          OpenProject::StaticRouting::StaticUrlHelpers.new.root_url,
          api_v3_paths.document(document.id)
        ).to_s
      end

      def readonly
        @readonly ||= user.allowed_in_project?(:view_documents, project) &&
          !user.allowed_in_project?(:manage_documents, project)
      end
    end
  end
end
