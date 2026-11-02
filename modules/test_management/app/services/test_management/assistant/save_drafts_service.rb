# frozen_string_literal: true

module TestManagement
  module Assistant
    # Saves selected (and possibly edited) drafts of a generation as test cases, through
    # TestCases::CreateService as the current user (so "Add test cases", folder and work package
    # visibility are checked by TestCases::CreateContract). All or nothing.
    #
    # * status "draft" (reviewed and promoted to "ready" by a person), chosen folder and labels;
    # * the source work package is linked when it was the source;
    # * a pull request source is kept as a note at the end of the description
    #   ("Generated from pull request <url>"), not as the automation reference, which is
    #   reserved for matching automated results.
    class SaveDraftsService
      Result = Struct.new(:success, :cases, :errors, keyword_init: true) do
        def success? = success
      end

      def initialize(user:, generation:)
        @user = user
        @generation = generation
      end

      # drafts: draft hashes (edited in the form), each with "selected"; suite_id / label_names
      # default to the generation's options.
      def call(drafts:, suite_id: generation.suite_id, label_names: generation.label_names)
        chosen = Drafts.normalize_all(Array(drafts).select { |d| selected?(d) })
        return failure([I18n.t("test_management.assistant.generate.nothing_selected")]) if chosen.empty?
        return failure([I18n.t(:notice_not_authorized)]) unless generation.user_id == user.id && Assistant.allowed?(user,
                                                                                                                    generation.project)

        cases = []
        errors = []
        ::TestManagement::TestCase.transaction do
          chosen.each do |draft|
            call = ::TestManagement::TestCases::CreateService.new(user:).call(case_params(draft, suite_id, label_names))
            if call.success?
              cases << call.result
            else
              errors << "#{draft['title']}: #{call.errors.full_messages.join(', ')}"
            end
          end
          raise ActiveRecord::Rollback if errors.any?
        end
        return failure(errors) if errors.any?

        generation.update!(saved_case_ids: (generation.saved_ids + cases.map(&:id)).uniq)
        Result.new(success: true, cases:, errors: [])
      end

      private

      attr_reader :user, :generation

      def selected?(draft)
        draft = draft.to_h.stringify_keys
        !draft.key?("selected") || ActiveModel::Type::Boolean.new.cast(draft["selected"])
      end

      def case_params(draft, suite_id, label_names)
        params = {
          project: generation.project,
          title: draft["title"],
          description: description(draft),
          preconditions: draft["preconditions"].presence,
          priority: draft["priority"],
          status: "draft",
          suite_id: suite_id.presence,
          label_names: Array(label_names),
          steps_attributes: draft["steps"].each_with_index.map do |step, index|
            { position: index + 1, action: step["action"], expected_result: step["expected_result"] }
          end
        }
        params[:work_package_ids] = [generation.work_package_id] if generation.work_package_id
        params
      end

      def description(draft)
        lines = []
        lines << I18n.t("test_management.assistant.generate.type_note", type: draft["type"]) if draft["type"].present?
        if generation.pull_request_url
          lines << I18n.t("test_management.assistant.generate.pull_request_note", url: generation.pull_request_url)
        end
        lines.join("\n\n").presence
      end

      def failure(errors)
        Result.new(success: false, cases: [], errors:)
      end
    end
  end
end
