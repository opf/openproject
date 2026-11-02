# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # CI connection writes (0016): POST /projects/:id/test_management/ci_connections,
      # PATCH / DELETE /test_management/ci_connections/:id. Same services and contracts as Project
      # settings (manage_test_ci). Secrets are write-only: token / triggerToken set them, blank keeps
      # them, removeToken / removeTriggerToken clear them; responses never contain them.
      module CiConnectionHelpers
        ATTRIBUTE_MAP = {
          "name" => :name,
          "provider" => :provider,
          "repository" => :repository,
          "baseUrl" => :base_url,
          "ingestMode" => :ingest_mode,
          "targetRunName" => :target_run_name,
          "active" => :active,
          "token" => :token,
          "removeToken" => :remove_token,
          "workflow" => :workflow,
          "ref" => :trigger_ref,
          "username" => :ci_username,
          "triggerToken" => :trigger_token,
          "removeTriggerToken" => :remove_trigger_token,
          "caCertificate" => :ca_certificate,
          "inboundOnly" => :inbound_only,
          "referenceName" => :reference_name,
          "e2eTests" => :e2e_tests,
          "scmRepositoryId" => :scm_repository_id
        }.freeze
        BOOLEAN_KEYS = %w[active removeToken removeTriggerToken inboundOnly].freeze
        STRING_KEYS = (ATTRIBUTE_MAP.keys - BOOLEAN_KEYS - %w[scmRepositoryId]).freeze

        def ci_connection_attributes
          body = ci_connection_body
          ATTRIBUTE_MAP.each_with_object({}) do |(key, attribute), attributes|
            next unless body.key?(key)

            value = body[key]
            unless ci_connection_value_type_ok?(key, value)
              raise ::API::Errors::UnprocessableContent.new("#{key} has an invalid type.")
            end

            attributes[attribute] = value
          end
        end

        def ci_connection_body
          raw = env["api.request.body"]
          raw = params.to_h.except("id") if raw.blank?
          raw.respond_to?(:to_h) ? raw.to_h.stringify_keys : {}
        end

        def ci_connection_value_type_ok?(key, value)
          return true if value.nil?
          return [true, false].include?(value) if BOOLEAN_KEYS.include?(key)
          return value.is_a?(Integer) || value.to_s.match?(/\A\d+\z/) if key == "scmRepositoryId"

          value.is_a?(String) && STRING_KEYS.include?(key)
        end

        def ci_connection_result!(call, status_code)
          if call.success?
            status status_code
            return CiConnectionRepresenter.new(call.result.reload, current_user:)
          end

          raise ::API::Errors::Unauthorized if call.errors.details[:base].pluck(:error).include?(:error_unauthorized)

          raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" "))
        end

        def visible_ci_connection!(id, permissions)
          connection = ::TestManagement::CiConnection.includes(:project).find_by(id:)
          raise ::API::Errors::NotFound.new unless connection && allowed_any?(permissions, connection.project)

          connection
        end
      end
    end
  end
end
