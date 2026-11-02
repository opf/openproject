# frozen_string_literal: true

module API
  module V3
    module TestManagement
      # A Test Assistant generation (0014): request + status + draft test cases. Generation runs
      # in the background; poll GET …/assistant/generations/:id until status is done or failed.
      #   status        queued | running | done | failed (requests stuck longer than 10 minutes: failed)
      #   drafts        [{ key, title, type, priority, preconditions, steps: [{ action, expectedResult }] }]
      #   savedCaseIds  ids of test cases saved from this generation
      #   usage         { promptTokens, completionTokens, totalTokens, reasoningTokens? } when done
      class AssistantGenerationRepresenter < ::API::Decorators::Single
        include ::API::Decorators::DateProperty

        link :self do
          { href: api_v3_paths.test_management_assistant_generation(represented.id) }
        end

        link :project do
          { href: api_v3_paths.project(represented.project_id) }
        end

        link :save do
          next unless represented.done?

          { href: api_v3_paths.test_management_assistant_generation_save(represented.id), method: :post }
        end

        link :workPackage do
          next unless represented.work_package_id

          { href: api_v3_paths.work_package(represented.work_package_id) }
        end

        property :id
        property :status, exec_context: :decorator, getter: ->(*) { represented.effective_status }
        property :source_type, as: :sourceType
        property :source, exec_context: :decorator, getter: ->(*) {
          data = represented.source_data
          { "workPackageId" => data["work_package_id"].presence&.to_i, "text" => data["text"], "url" => data["url"],
            "code" => data["code"], "language" => data["language"].presence }.compact
        }
        property :count, exec_context: :decorator, getter: ->(*) { represented.count }
        property :types, exec_context: :decorator, getter: ->(*) { represented.case_types }
        property :suite_id, as: :suiteId, exec_context: :decorator, getter: ->(*) { represented.suite_id }, render_nil: true
        property :labels, exec_context: :decorator, getter: ->(*) { represented.label_names }
        property :drafts, exec_context: :decorator, getter: ->(*) {
          represented.draft_list.map do |draft|
            { "key" => draft["key"], "title" => draft["title"], "type" => draft["type"], "priority" => draft["priority"],
              "preconditions" => draft["preconditions"].presence,
              "steps" => Array(draft["steps"]).map { |s| { "action" => s["action"], "expectedResult" => s["expected_result"] } } }
          end
        }
        property :saved_case_ids, as: :savedCaseIds, exec_context: :decorator, getter: ->(*) { represented.saved_ids }
        property :error, exec_context: :decorator, getter: ->(*) { represented.effective_error }, render_nil: true
        property :provider_model, as: :provider, render_nil: true
        property :usage, exec_context: :decorator, getter: ->(*) {
          data = represented.usage_payload
          next unless data

          { "promptTokens" => data["prompt_tokens"], "completionTokens" => data["completion_tokens"],
            "totalTokens" => data["total_tokens"], "reasoningTokens" => data["reasoning_tokens"] }.compact
        }, render_nil: true
        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "TestManagementAssistantGeneration"
        end
      end
    end
  end
end
