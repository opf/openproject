# frozen_string_literal: true

module TestManagement
  module CiConnections
    # CI connection writes from Project settings and APIv3 (0016). Requires :manage_test_ci.
    # Tokens are write-only (token / trigger_token set the encrypted columns, remove_* clear them).
    class BaseContract < ::ModelContract
      def self.model
        TestManagement::CiConnection
      end

      attribute :name
      attribute :provider
      attribute :repository
      attribute :base_url
      attribute :ingest_mode
      attribute :target_run_name
      attribute :active
      attribute :workflow
      attribute :trigger_ref
      attribute :ci_username
      attribute :ca_certificate
      attribute :inbound_only
      attribute :reference_name
      attribute :e2e_tests
      attribute :scm_repository
      # Write-only secrets and what setting them changes.
      attribute :token
      attribute :remove_token
      attribute :trigger_token
      attribute :remove_trigger_token
      attribute :token_ciphertext
      attribute :token_updated_at
      attribute :trigger_token_ciphertext
      attribute :trigger_token_updated_at
      # Derived from provider / base URL (CiConnection#normalize).
      attribute :server_url

      validate :user_allowed_to_manage

      private

      def user_allowed_to_manage
        return if model.project.nil?

        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_test_ci, model.project)
      end
    end
  end
end
