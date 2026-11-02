# frozen_string_literal: true

module TestManagement
  module Automation
    # Writes matched records into the run:
    # - one TestResult per record (source "automation", duration, reported id, details);
    # - the run case status becomes the worst status of its records in this upload
    #   (e.g. chromium passed + firefox failed → failed);
    # - assignFailedTo assigns failed cases; one "automation_result" history event per case;
    # - the result keeps the printed error (message + stack trace) and, when the report has test
    #   steps, one step result per case step (StepMatcher) plus the unmatched reported steps (0020).
    # Cases not yet in the run are added (addMatchedCasesToRun, default on); for
    # dynamic runs only when they match the run's filter.
    class ResultWriter
      COMMENT_LIMIT = 4000

      def initialize(user:, run:, import:, options:, mapper:, attachments:, unmatched:)
        @user = user
        @run = run
        @import = import
        @options = options
        @mapper = mapper
        @attachments = attachments
        @unmatched = unmatched
        @statuses = Hash.new { |h, k| h[k] = [] }
        @run_cases = {}
      end

      # entries: [[record, [test_case, …]], …]; returns number of matched records.
      def call(entries)
        matched = 0
        entries.each do |record, cases|
          status = map_status(record)
          next if status.nil?

          written = cases.count { |test_case| write(record, test_case, status) }
          matched += 1 if written.positive?
        end
        finish_cases
        run.update!(state: "in_progress") if run.state == "new" && @run_cases.any?
        matched
      end

      private

      attr_reader :user, :run, :import, :options, :mapper, :attachments, :unmatched

      def map_status(record)
        mapper.call(record.raw_status)
      rescue KeyError
        unmatched << unmatched_entry(record, "unknown_status")
        nil
      end

      def write(record, test_case, status)
        run_case = run_case_for(test_case)
        unless run_case
          unmatched << unmatched_entry(record, "not_in_run")
          return false
        end

        attachment_ids = attachments&.attach_for(record, run_case) || []
        result = run_case.results.create!(
          status:,
          comment: comment_for(record, status),
          user:,
          source: "automation",
          duration_ms: record.duration_ms,
          external_id: record.external_id.to_s.first(1024).presence,
          import:,
          iteration_id: import.iteration_id,
          error_message: (record.message unless status == "passed"),
          error_trace: (record.stack unless status == "passed"),
          details: details_for(record, attachment_ids)
        )
        write_steps(result, record, test_case)
        @statuses[run_case.id] << status
        true
      end

      def write_steps(result, record, test_case)
        return if record.steps.empty?

        rows = StepMatcher.new(case_steps: case_steps_for(test_case), steps_after_failure: options.steps_after_failure)
                          .call(record.steps)
        now = Time.current
        rows.each do |row|
          details = row[:details] || {}
          if details["attachments"]
            details["attachments"] = details["attachments"].map do |a|
              a.merge("attachmentId" => attachments&.ids_by_path&.[](a["path"])).compact
            end
          end
          result.step_results.create!(row.merge(details:, created_at: now))
        end
      end

      def case_steps_for(test_case)
        (@case_steps ||= {})[test_case.id] ||= test_case.steps.to_a
      end

      def run_case_for(test_case)
        return @run_cases[test_case.id] if @run_cases.key?(test_case.id)

        run_case = run.run_cases.find_by(test_case_id: test_case.id)
        if run_case.nil? && may_add?(test_case)
          run_case = run.run_cases.create!(test_case:, assigned_to_id: run.assigned_to_id, status: "untested")
        end
        @run_cases[test_case.id] = run_case
      end

      def may_add?(test_case)
        return false unless options.add_matched_cases_to_run?

        run.selection_mode == "dynamic" ? run.matches?(test_case) : true
      end

      def comment_for(record, status)
        return nil if status == "passed"

        text = [record.project_name.presence && "[#{record.project_name}]", record.message].compact.join(" ")
        text.presence&.first(COMMENT_LIMIT)
      end

      def details_for(record, attachment_ids)
        {
          "reference" => record.reference, "rawStatus" => record.raw_status, "projectName" => record.project_name,
          "retry" => record.retry, "flaky" => record.flaky,
          "attachmentIds" => attachment_ids.presence, "ciRunUrl" => options.ci["runUrl"]
        }.compact
      end

      def finish_cases
        assignee = options.assign_failed_to && TestManagement::Assignees.possible?(run.project, options.assign_failed_to) &&
                   options.assign_failed_to
        @run_cases.each_value do |run_case|
          next unless run_case && @statuses.key?(run_case.id)

          final = TestRunCase.worst_status(@statuses[run_case.id])
          run_case.status = final
          run_case.assigned_to_id = assignee if assignee && final == "failed"
          run_case.save!
          TestCaseEvent.create!(test_case_id: run_case.test_case_id, user:, action: "automation_result",
                                details: { "run_id" => run.id, "run_name" => run.name, "status" => final,
                                           "import_id" => import.id })
        end
      end

      def unmatched_entry(record, reason)
        { "reference" => record.reference, "title" => record.display_title, "file" => record.file,
          "status" => record.raw_status, "projectName" => record.project_name, "reason" => reason }.compact
      end
    end
  end
end
