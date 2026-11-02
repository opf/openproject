# frozen_string_literal: true

module TestManagement
  module Assistant
    # Write actions proposed by the chat model. #propose resolves and checks the arguments and
    # builds the confirmation card (preview lines, problems). #execute runs only after the user
    # confirmed, through the module's existing services as the current user, so the usual
    # contracts (permissions, visibility, project scoping) apply once more at that point.
    module Actions
      MAX_CASES = 20
      MAX_RUN_CASES = 2000

      Outcome = Struct.new(:success, :records, :errors, keyword_init: true) do
        def success? = success
      end

      module_function

      # => { "name", "params", "preview" => [String], "errors" => [String] }
      def propose(name, args, user:, project:)
        args = args.to_h.stringify_keys
        case name.to_s
        when "create_test_run" then propose_run(args, user, project)
        when "create_milestone" then propose_milestone(args, user, project)
        when "create_test_cases" then propose_cases(args, user, project)
        else { "name" => name.to_s, "params" => {}, "preview" => [], "errors" => [t("unknown")] }
        end
      end

      def execute(action, user:, project:)
        action = action.to_h.stringify_keys
        params = action["params"].to_h.stringify_keys
        case action["name"]
        when "create_test_run" then execute_run(params, user, project)
        when "create_milestone" then execute_milestone(params, user, project)
        when "create_test_cases" then execute_cases(params, user, project)
        else Outcome.new(success: false, records: [], errors: [t("unknown")])
        end
      end

      # --- create_test_run ------------------------------------------------------------------

      def propose_run(args, user, project)
        errors = []
        errors << t("not_allowed") unless user.allowed_in_project?(:add_test_runs, project)
        name = Drafts.text(args["name"], 255).presence || I18n.t("test_management.assistant.chat.default_run_name",
                                                                 date: Date.current.iso8601)
        folder_ids = ids(args["folder_ids"])
        folders = TestManagement::Suite.where(project_id: project.id, id: folder_ids).to_a
        errors << t("unknown_folders", ids: (folder_ids - folders.map(&:id)).join(", ")) if folders.size < folder_ids.size
        case_ids = ids(args["test_case_ids"])
        cases = project.tm_test_cases.not_deleted
        known_case_ids = cases.where(id: case_ids).pluck(:id)
        errors << t("unknown_cases", ids: (case_ids - known_case_ids).join(", ")) if known_case_ids.size < case_ids.size
        milestone = nil
        if args["milestone_id"].present?
          milestone = TestManagement::Milestone.enabled_for?(project) && TestManagement::Milestone.lookup(project,
                                                                                                          args["milestone_id"])
          errors << t("unknown_milestone") unless milestone
        end
        selected = known_case_ids
        if folders.any?
          selected |= cases.where(suite_id: TestManagement::Suite.subtree_ids(project, folders.map(&:id))).pluck(:id)
        end
        if selected.empty? && milestone && folders.empty? && case_ids.empty?
          selected = cases.where(id: TestManagement::TestCaseWorkPackage.where(work_package_id: milestone.work_package_ids)
                                                                        .select(:test_case_id)).pluck(:id)
        end
        errors << t("no_cases") if selected.empty?
        errors << t("too_many_cases", max: MAX_RUN_CASES) if selected.size > MAX_RUN_CASES
        preview = [t("preview.run", name:, count: selected.size)]
        preview << t("preview.folders", names: folders.map(&:path_name).join(", ")) if folders.any?
        preview << t("preview.milestone", name: milestone.name) if milestone
        { "name" => "create_test_run",
          "params" => { "name" => name, "description" => Drafts.text(args["description"], 4000).presence,
                        "test_case_ids" => selected.sort, "milestone_id" => milestone&.id }.compact,
          "preview" => preview, "errors" => errors }
      end

      def execute_run(params, user, project)
        call = TestManagement::TestRuns::CreateService.new(user:).call(
          project:, name: params["name"], description: params["description"], selection_mode: "specific",
          test_case_ids: Array(params["test_case_ids"]), milestone_id: params["milestone_id"]
        )
        outcome(call) { |run| [{ "type" => "test_run", "id" => run.id, "title" => run.name }] }
      end

      # --- create_milestone -----------------------------------------------------------------

      def propose_milestone(args, user, project)
        errors = []
        errors << t("milestones_disabled") unless TestManagement::Milestone.enabled_for?(project)
        errors << t("not_allowed") unless user.allowed_in_project?(:manage_test_milestones, project)
        name = Drafts.text(args["name"], 255)
        errors << t("name_missing") if name.blank?
        start_date = date(args["start_date"], errors)
        due_date = date(args["due_date"], errors)
        errors << t("dates_order") if start_date && due_date && due_date < start_date
        parent = nil
        if args["parent_id"].present?
          parent = TestManagement::Milestone.lookup(project, args["parent_id"])
          errors << t("unknown_milestone") unless parent
        end
        preview = [t("preview.milestone_new", name:)]
        preview << t("preview.dates", start: start_date&.iso8601 || "–", due: due_date&.iso8601 || "–") if start_date || due_date
        preview << t("preview.parent", name: parent.name) if parent
        { "name" => "create_milestone",
          "params" => { "name" => name, "description" => Drafts.text(args["description"], 4000).presence,
                        "start_date" => start_date&.iso8601, "due_date" => due_date&.iso8601,
                        "parent_id" => parent&.id }.compact,
          "preview" => preview, "errors" => errors }
      end

      def execute_milestone(params, user, project)
        call = TestManagement::Milestones::CreateService.new(user:).call(
          project:, **params.slice("name", "description", "start_date", "due_date", "parent_id").symbolize_keys
        )
        outcome(call) { |milestone| [{ "type" => "milestone", "id" => milestone.id, "title" => milestone.name }] }
      end

      # --- create_test_cases ----------------------------------------------------------------

      def propose_cases(args, user, project)
        errors = []
        errors << t("not_allowed") unless user.allowed_in_project?(:add_test_cases, project)
        folder = nil
        if args["folder_id"].present?
          folder = TestManagement::Suite.find_by(project_id: project.id, id: args["folder_id"].to_i)
          errors << t("unknown_folders", ids: args["folder_id"]) unless folder
        end
        drafts = Drafts.normalize_all(Array(args["cases"]).first(MAX_CASES))
        errors << t("no_cases") if drafts.empty?
        preview = [t("preview.cases", count: drafts.size,
                                      folder: folder&.path_name || I18n.t("test_management.assistant.no_folder"))]
        preview.concat(drafts.map { |d| "• #{d['title']} (#{d['steps'].size})" })
        { "name" => "create_test_cases",
          "params" => { "suite_id" => folder&.id, "cases" => drafts }.compact,
          "preview" => preview, "errors" => errors }
      end

      def execute_cases(params, user, project)
        records = []
        errors = []
        TestManagement::TestCase.transaction do
          Array(params["cases"]).each do |draft|
            draft = draft.to_h.stringify_keys
            call = TestManagement::TestCases::CreateService.new(user:).call(
              project:, title: draft["title"], preconditions: draft["preconditions"].presence,
              priority: draft["priority"].presence || "medium", status: "draft", suite_id: params["suite_id"],
              steps_attributes: Array(draft["steps"]).each_with_index.map do |s, i|
                { position: i + 1, action: s["action"], expected_result: s["expected_result"] }
              end
            )
            if call.success?
              records << { "type" => "test_case", "id" => call.result.id, "title" => call.result.title }
            else
              errors << "#{draft['title']}: #{call.errors.full_messages.join(', ')}"
            end
          end
          raise ActiveRecord::Rollback if errors.any?
        end
        errors.any? ? Outcome.new(success: false, records: [], errors:) : Outcome.new(success: true, records:, errors: [])
      end

      # --- helpers --------------------------------------------------------------------------

      def outcome(call)
        return Outcome.new(success: true, records: yield(call.result), errors: []) if call.success?

        Outcome.new(success: false, records: [], errors: call.errors.full_messages.presence || [t("failed")])
      end

      def ids(raw)
        Array(raw).flat_map { |v| v.to_s.split(/[\s,]+/) }.map { |v| v.delete_prefix("#") }
          .grep(/\A\d+\z/).map(&:to_i).uniq.first(MAX_RUN_CASES + 1)
      end

      def date(value, errors)
        return nil if value.blank?

        Date.iso8601(value.to_s)
      rescue Date::Error
        errors << t("invalid_date", value: value.to_s.first(20))
        nil
      end

      def t(key, **)
        I18n.t("test_management.assistant.actions.#{key}", **)
      end
    end
  end
end
