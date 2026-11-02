# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # Test Assistant API (0014): camelCase request bodies -> service params, error mapping.
      module AssistantHelpers
        def assistant_allowed!(project)
          raise ::API::Errors::NotFound.new unless ::TestManagement::Assistant.enabled_for?(project)

          authorize_in_project(%i[use_test_assistant], project:)
        end

        def assistant_body
          raw = env["api.request.body"]
          raw = params.to_h if raw.blank?
          raw.respond_to?(:to_h) ? raw.to_h.deep_stringify_keys : {}
        end

        # { sourceType, source: { workPackageId | text | url | code, language }, count, types, suiteId, labels }
        def generation_params(body)
          source = body["source"].is_a?(Hash) ? body["source"] : {}
          {
            source_type: body["sourceType"].to_s,
            source: { work_package_id: source["workPackageId"], text: source["text"], url: source["url"],
                      code: source["code"], language: source["language"] }.compact,
            options: { count: body["count"], types: body["types"], suite_id: body["suiteId"],
                       label_names: Array(body["labels"]) }.compact
          }
        end

        # drafts in API shape -> form shape (expectedResult -> expected_result)
        def api_drafts(list)
          Array(list).map do |draft|
            draft = {} unless draft.is_a?(Hash)
            draft.slice("title", "type", "priority", "preconditions").merge(
              "steps" => Array(draft["steps"]).map do |s|
                s.is_a?(Hash) ? { "action" => s["action"], "expected_result" => s["expectedResult"] } : {}
              end
            )
          end
        end

        def find_own_generation!(id)
          generation = ::TestManagement::AssistantGeneration.includes(:project).find_by(id:, user_id: current_user.id)
          raise ::API::Errors::NotFound.new unless generation && ::TestManagement::Assistant.enabled_for?(generation.project)

          authorize_in_project(%i[use_test_assistant], project: generation.project)
          generation
        end

        def assistant_failure!(call)
          symbols = call.errors.details[:base].pluck(:error)
          raise ::API::Errors::Unauthorized if symbols.include?(:error_unauthorized)

          raise ::API::Errors::UnprocessableContent.new(call.errors.full_messages.join(" "))
        end
      end
    end
  end
end
