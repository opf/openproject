# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Shared by the project-scoped and the global milestone endpoints.
      module MilestoneHelpers
        ATTRIBUTE_MAP = {
          "name" => :name,
          "description" => :description,
          "startDate" => :start_date,
          "dueDate" => :due_date,
          "parentId" => :parent_id,
          "versionId" => :version_id,
          "workPackageIds" => :work_package_ids
        }.freeze

        # Run in CI (0012): `milestone` as id, "M12" or name. Blank -> none; unknown -> 422.
        def api_trigger_milestone(project, ref)
          return nil if ref.blank?

          ::TestManagement::Milestone.lookup(project, ref.to_s) ||
            raise(::API::Errors::UnprocessableContent.new("Unknown milestone."))
        end

        def milestones_enabled!(project)
          raise ::API::Errors::NotFound.new unless ::TestManagement::Milestone.enabled_for?(project)
        end

        # camelCase request body -> model attributes; description may be a string or { raw: }.
        def milestone_attributes
          body = request_body_hash
          ATTRIBUTE_MAP.each_with_object({}) do |(key, attribute), attributes|
            next unless body.key?(key)

            value = body[key]
            value = value["raw"] if attribute == :description && value.is_a?(Hash)
            attributes[attribute] = value
          end
        end

        def request_body_hash
          raw = env["api.request.body"]
          raw = params.to_h if raw.blank?
          raw.respond_to?(:to_h) ? raw.to_h.stringify_keys : {}
        end

        def milestone_result!(call, status_code)
          if call.success?
            status status_code
            return MilestoneRepresenter.new(call.result.reload, current_user:)
          end

          symbols = call.errors.details[:base].pluck(:error)
          raise ::API::Errors::Unauthorized if symbols.include?(:error_unauthorized)
          raise ::API::Errors::Conflict.new(message: call.errors.full_messages.join(" ")) if symbols.include?(:tm_invalid_transition)

          raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" "))
        end
      end
    end
  end
end
