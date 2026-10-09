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
    # Creates a collaboration token for the document.
    #
    # When a `previous_token` is given, it is revoked 30 seconds after the new token is created,
    # so the collaboration server can keep using it until the client has handed the new token over.
    # The previous token may be expired, but must not be revoked (i.e. must not have been sent before).
    class TokenWithMetadataService < BaseServices::BaseCallable
      PREVIOUS_TOKEN_REVOCATION_DELAY = 30.seconds

      attr_reader :user, :document, :project, :previous_token

      def initialize(user:, document:, project:, previous_token: nil)
        super()

        @user = user
        @document = document
        @project = project
        @previous_token = previous_token
      end

      def perform
        return invalid_previous_token_result if previous_token && previous_access_token.nil?

        token_result = nil

        ::Doorkeeper::AccessToken.transaction do
          token_result = previous_token ? revoke_previous_and_create_token : create_token_with_metadata
          raise ActiveRecord::Rollback if token_result.failure?
        end

        token_result
      end

      def self.resource_url_for(document)
        URI.join(
          OpenProject::StaticRouting::StaticUrlHelpers.new.root_url,
          ::API::V3::Utilities::PathHelper::ApiV3Path.document(document.id)
        ).to_s
      end

      def self.readonly?(user:, project:)
        user.allowed_in_project?(:view_documents, project) &&
          !user.allowed_in_project?(:manage_documents, project)
      end

      def resource_url
        @resource_url ||= self.class.resource_url_for(document)
      end

      private

      def create_token_with_metadata # rubocop:disable Metrics/AbcSize
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

      def revoke_previous_and_create_token
        return invalid_previous_token_result if revoke_previous_token.zero?

        token_result = create_token_with_metadata
        return token_result if token_result.success?

        ServiceResult.failure(message: I18n.t("api_v3.errors.code_500"))
      end

      def readonly
        @readonly ||= self.class.readonly?(user:, project:)
      end

      def previous_access_token
        @previous_access_token ||= find_previous_access_token
      end

      def find_previous_access_token
        payload = decrypted_payload
        return if payload.nil?
        return if payload["resource_url"] != resource_url

        access_token = ::Doorkeeper::AccessToken.by_token(payload["oauth_token"])
        return unless access_token&.includes_scope?(EDIT_DOCUMENTS_SCOPE)
        return if access_token.resource_owner_id != user.id
        return if access_token.revoked_at.present?

        access_token
      end

      def decrypted_payload
        decrypt_result = DecryptTokenService.new(token: previous_token).call
        return unless decrypt_result.success?

        payload = JSON.parse(decrypt_result.result)
        payload if payload.is_a?(Hash)
      rescue JSON::ParserError
        nil
      end

      # Doorkeeper considers a token revoked once `revoked_at <= now`, so a value in the
      # future keeps it valid until then.
      # Only revokes if not revoked yet, so that concurrent requests cannot both revoke the same token.
      def revoke_previous_token
        ::Doorkeeper::AccessToken
          .where(id: previous_access_token.id, revoked_at: nil)
          .update_all(revoked_at: PREVIOUS_TOKEN_REVOCATION_DELAY.from_now)
      end

      def invalid_previous_token_result
        ServiceResult
          .failure(message: I18n.t("documents.collaboration_token.errors.invalid_previous_token"))
          .tap { |result| result.errors.add(:token, :invalid) }
      end
    end
  end
end
