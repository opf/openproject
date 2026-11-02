# frozen_string_literal: true

module API
  module V3
    module TestManagement
      module PlanHelpers
        ATTRIBUTE_MAP = {
          "name" => :name,
          "description" => :description,
          "startDate" => :start_date,
          "endDate" => :end_date,
          "milestoneId" => :milestone_id,
          "assignedToId" => :assigned_to_id,
          "workPackageIds" => :work_package_ids
        }.freeze

        ENTRY_ATTRIBUTE_MAP = {
          "name" => :name,
          "description" => :description,
          "selectionMode" => :selection_mode,
          "assignedToId" => :assigned_to_id,
          "position" => :position,
          "caseIds" => :case_ids,
          "configurationIds" => :configuration_ids,
          "filterOptions" => :filter_options
        }.freeze

        def plans_enabled!(project)
          raise ::API::Errors::NotFound.new unless ::TestManagement::TestPlan.enabled_for?(project)
        end

        def find_visible_plan!(id)
          plan = ::TestManagement::TestPlan.includes(:project).find_by(id:)
          raise ::API::Errors::NotFound.new unless plan &&
                                                   ::TestManagement::TestPlan.enabled_for?(plan.project) &&
                                                   current_user.allowed_in_project?(:view_test_plans, plan.project)

          plan
        end

        def plan_attributes
          body = plan_request_body
          ATTRIBUTE_MAP.each_with_object({}) do |(key, attribute), attributes|
            next unless body.key?(key)

            value = body[key]
            value = value["raw"] if attribute == :description && value.is_a?(Hash)
            attributes[attribute] = value
          end
        end

        def plan_entry_attributes
          body = plan_request_body
          ENTRY_ATTRIBUTE_MAP.each_with_object({}) do |(key, attribute), attributes|
            next unless body.key?(key)

            value = body[key]
            if attribute == :filter_options && value.is_a?(Hash)
              value = {
                "label_ids" => Array(value["labelIds"] || value["label_ids"]),
                "suite_ids" => Array(value["suiteIds"] || value["suite_ids"]),
                "automation" => value["automation"]
              }
            end
            attributes[attribute] = value
          end
        end

        def plan_request_body
          raw = env["api.request.body"]
          raw = params.to_h if raw.blank?
          raw.respond_to?(:to_h) ? raw.to_h.stringify_keys : {}
        end

        def plan_result!(call, status_code)
          if call.success?
            status status_code
            return PlanRepresenter.new(call.result.reload, current_user:)
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
