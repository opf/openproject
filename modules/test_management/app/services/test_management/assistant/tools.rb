# frozen_string_literal: true

module TestManagement
  module Assistant
    # Chat tools (OpenAI "function" schemas). Read tools run server-side immediately with the
    # user's permissions; write tools never run directly: they become a proposal (Actions) that
    # the user confirms on a card.
    module Tools
      READ = %w[search_test_cases summarize_failures work_package_coverage].freeze
      WRITE = %w[create_test_run create_milestone create_test_cases].freeze
      MAX_RESULTS = 25
      COMMENT_CHARS = 300

      module_function

      def write?(name) = WRITE.include?(name.to_s)
      def read?(name) = READ.include?(name.to_s)

      def schemas
        [
          function("search_test_cases", "Find test cases by words in the title, optionally in a folder or with a status.",
                   { query: { type: "string" }, folder_id: { type: "integer" },
                     status: { type: "string", enum: TestManagement::TestCase::STATUSES } }),
          function("summarize_failures", "Failed and blocked cases with their latest result comments, for a run, " \
                                         "a milestone, or (default) the latest runs.",
                   { run_id: { type: "integer" }, milestone_id: { type: "integer" } }),
          function("work_package_coverage", "Which work packages have linked test cases and how those cases did in " \
                                            "their latest runs. Optionally for one work package.",
                   { work_package_id: { type: "integer" } }),
          function("create_test_run", "Propose a new test run. The user must confirm it before it is created.",
                   { name: { type: "string" }, description: { type: "string" },
                     folder_ids: { type: "array", items: { type: "integer" } },
                     test_case_ids: { type: "array", items: { type: "integer" } },
                     milestone_id: { type: "integer" } }, required: %w[name]),
          function("create_milestone", "Propose a new milestone. The user must confirm it before it is created.",
                   { name: { type: "string" }, description: { type: "string" },
                     start_date: { type: "string", description: "YYYY-MM-DD" },
                     due_date: { type: "string", description: "YYYY-MM-DD" }, parent_id: { type: "integer" } },
                   required: %w[name]),
          function("create_test_cases", "Propose new test cases (saved as drafts). The user must confirm first.",
                   { folder_id: { type: "integer" },
                     cases: { type: "array", items: {
                       type: "object", required: %w[title],
                       properties: { title: { type: "string" }, preconditions: { type: "string" },
                                     priority: { type: "string", enum: TestManagement::TestCase::PRIORITIES },
                                     steps: { type: "array", items: { type: "object", properties: {
                                       action: { type: "string" }, expected_result: { type: "string" }
                                     } } } }
                     } } }, required: %w[cases])
        ]
      end

      def function(name, description, properties = {}, required: [])
        { type: "function",
          function: { name:, description:,
                      parameters: { type: "object", properties:, required: } } }
      end

      # Returns a JSON string (fenced as data by the caller).
      def run(name, args, user:, project:)
        args = args.to_h.stringify_keys
        result = case name.to_s
                 when "search_test_cases" then search_test_cases(args, project)
                 when "summarize_failures" then summarize_failures(args, user, project)
                 when "work_package_coverage" then work_package_coverage(args, user, project)
                 else { error: "unknown tool" }
                 end
        result.to_json
      end

      def search_test_cases(args, project)
        scope = project.tm_test_cases.not_deleted.includes(:suite).order(:id)
        words = args["query"].to_s.split.first(5)
        words.each { |w| scope = scope.where("LOWER(tm_test_cases.title) LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(w.downcase)}%") }
        if args["folder_id"].present?
          scope = scope.where(suite_id: TestManagement::Suite.subtree_ids(project, [args["folder_id"].to_i]))
        end
        scope = scope.where(status: args["status"]) if TestManagement::TestCase::STATUSES.include?(args["status"])
        { total: scope.count,
          cases: scope.limit(MAX_RESULTS).map do |c|
            { id: c.id, title: c.title, folder: c.suite&.path_name, status: c.status, priority: c.priority,
              automated: c.automated }
          end }
      end

      def summarize_failures(args, user, project)
        return { error: "not permitted to see test runs" } unless user.allowed_in_project?(:view_test_runs, project)

        runs = project.tm_test_runs
        runs = if args["run_id"].present? then runs.where(id: args["run_id"].to_i)
               elsif args["milestone_id"].present? then runs.where(milestone_id: args["milestone_id"].to_i)
               else runs.newest_first.limit(5)
               end
        run_ids = runs.pluck(:id)
        failing = TestManagement::TestRunCase.where(test_run_id: run_ids)
                    .where(TestManagement::TestRunCase.effective_status_sql.in(%w[failed blocked]))
                    .includes(:test_case, :test_run).order(:id).limit(MAX_RESULTS).to_a
        comments = TestManagement::TestResult.where(run_case_id: failing.map(&:id)).where.not(comment: [nil, ""])
                     .order(:id).pluck(:run_case_id, :comment).to_h
        { runs: runs.map do |r|
          { id: r.id, name: r.name, state: r.state, counts: r.status_counts.select do |_, n|
            n.positive?
          end }
        end,
          failing: failing.map do |rc|
            { run_id: rc.test_run_id, case_id: rc.test_case_id, title: rc.test_case&.title, status: rc.effective_status,
              comment: comments[rc.id].to_s.first(COMMENT_CHARS).presence }.compact
          end }
      end

      def work_package_coverage(args, user, project)
        links = TestManagement::TestCaseWorkPackage.joins(:test_case)
                  .where(tm_test_cases: { project_id: project.id, deleted_at: nil })
        links = links.where(work_package_id: args["work_package_id"].to_i) if args["work_package_id"].present?
        by_wp = links.pluck(:work_package_id, :test_case_id).group_by(&:first).transform_values { |v| v.map(&:last) }
        visible = ::WorkPackage.visible(user).where(id: by_wp.keys).order(:id).limit(MAX_RESULTS).pluck(:id, :subject)
        latest = latest_statuses(by_wp.values.flatten, user, project)
        { work_packages: visible.map do |id, subject|
          statuses = by_wp[id].map { |cid| latest[cid] || "not run" }.tally
          { id:, subject:, cases: by_wp[id].size, latest_results: statuses }
        end }
      end

      def latest_statuses(case_ids, user, project)
        return {} if case_ids.empty? || !user.allowed_in_project?(:view_test_runs, project)

        TestManagement::TestRunCase.joins(:test_run).where(test_case_id: case_ids, tm_test_runs: { project_id: project.id })
          .order(:id).pluck(:test_case_id, TestManagement::TestRunCase.effective_status_sql).to_h
      end
    end
  end
end
