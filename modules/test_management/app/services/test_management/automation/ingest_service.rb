# frozen_string_literal: true

require "digest"

module TestManagement
  module Automation
    # Ingests one automated test report (Playwright JSON, JUnit XML or native JSON)
    # into a test run. Used by the APIv3 endpoints
    #   POST /api/v3/projects/:id/test_management/automation/results
    #   POST /api/v3/projects/:id/test_management/runs/:run_id/results
    #
    # Permission: :upload_test_results (or :add_test_runs). Steps:
    # 1. parse (format auto-detected), 2. CI connection (explicit or by provider+repository)
    #    and mode (new_run | new_iteration), 3. resolve the run (runId / externalRef / new,
    #    or the target run for new_iteration),
    # 4. under a row lock on the run: pick the iteration (new_iteration: the iteration with the
    #    same externalRef – parallel shards – or the next one, which resets the cases; new_run:
    #    the current one), replay check (same payload digest within the iteration → the
    #    earlier import is returned unchanged), match cases, optionally auto-create cases and
    #    write reference back, write results + attachments, record the import,
    # 5. closeRun: complete the run via TestRuns::CompleteService (completion source "automation").
    # Raises Automation::Error (mapped to 4xx by the API).
    class IngestService
      MAX_BYTES = 50 * 1024 * 1024
      MAX_TESTS = 20_000

      Outcome = Struct.new(:import, :run, :created_run, :replay, :iteration, :created_iteration, :mode, :connection,
                           keyword_init: true) do
        def created_run? = created_run
        def replay? = replay
        def created_iteration? = created_iteration
      end

      def initialize(user:, project:)
        @user = user
        @project = project
      end

      def call(content:, options: {}, files: [])
        authorize!
        content = content.to_s
        raise Error.new(:payload_too_large, "The report exceeds #{MAX_BYTES / 1024 / 1024} MB.") if content.bytesize > MAX_BYTES

        opts = options.is_a?(Options) ? options : Options.new(options)
        format, records = Parser.parse(content, opts.format)
        raise Error.new(:payload_too_large, "The report has more than #{MAX_TESTS} tests.") if records.size > MAX_TESTS

        warnings = []
        plan = ConnectionResolver.new(project:, options: opts, warnings:).call
        run, created = RunResolver.new(user:, project:, options: opts, warnings:, plan:).call
        outcome = ingest(run, created, plan, format, records, opts, warnings, files, Digest::SHA256.hexdigest(content))
        close_run(outcome, opts) if opts.close_run?
        outcome
      end

      private

      attr_reader :user, :project

      def authorize!
        return if allowed?(:upload_test_results) || allowed?(:add_test_runs)

        raise Error.new(:forbidden, "You are not allowed to upload test results in this project.")
      end

      def allowed?(permission)
        user.allowed_in_project?(permission, project)
      end

      def ingest(run, created, plan, format, records, opts, warnings, files, digest)
        run.with_lock do
          if run.finished?
            raise Error.new(:conflict,
                            "Test run #{run.formatted_id} is #{run.state}; results can no longer be added.")
          end

          iteration, created_iteration = pick_iteration(run, created, plan, opts)
          base = { run:, iteration:, mode: plan.mode, connection: plan.connection }
          replayed = run.automation_imports.find_by(iteration_id: iteration.id, digest:, state: "done")
          next Outcome.new(import: replayed, created_run: false, replay: true, created_iteration: false, **base) if replayed

          import = run.automation_imports.create!(project:, user:, format:, state: "processing", digest:,
                                                  iteration:, external_ref: opts.external_ref,
                                                  options: opts.to_h, parsed_count: records.size)
          unmatched = []
          references = Reference::Context.new(project:, connection: plan.connection, options: opts, format:)
          entries, created_cases = match(records, opts, unmatched, warnings, references)
          attachments = AttachmentWriter.new(user:, run:, files:, warnings:, paths: opts.attachment_paths) if Array(files).any?
          mapper = StatusMapper.new(skipped_as: opts.skipped_as, flaky_as: opts.flaky_as, status_map: opts.status_map)
          matched = ResultWriter.new(user:, run:, import:, options: opts, mapper:, attachments:, unmatched:).call(entries)
          attachments&.attach_rest
          run.update!(ci_metadata: run.ci_info.merge(opts.ci)) if opts.ci.any?
          run.update!(connection: plan.connection) if plan.connection && run.connection_id.nil?
          iteration.update!(ci_metadata: iteration.ci_info.merge(opts.ci)) if opts.ci.any? && !created_iteration

          import.update!(state: "done", matched_count: matched, created_cases_count: created_cases,
                         unmatched_count: unmatched.size, unmatched: unmatched.first(1000),
                         warnings: warnings.first(200), attachments_count: attachments&.created&.size.to_i)
          Outcome.new(import:, created_run: created, replay: false, created_iteration:, **base)
        end
      end

      # Returns [iteration, created?]. Runs without iterations (created before 0009) get
      # iteration 1 first, holding their earlier results.
      def pick_iteration(run, created, plan, opts)
        starter = TestManagement::TestRunIterations::Starter.new(run:, user:)
        attributes = { name: opts.iteration_name || opts.ci_title, source: "automation", external_ref: opts.external_ref,
                       ci_metadata: opts.ci, connection: plan.connection }
        had_iteration = run.current_iteration.present?

        if opts.iteration_id
          # "Run in CI" pre-created this iteration; the upload fills it, whatever the mode.
          iteration = run.iterations.find_by(id: opts.iteration_id)
          raise Error.new(:not_found, "The test run iteration does not exist.") unless iteration
          unless iteration.id == run.current_iteration&.id
            raise Error.new(:conflict, "Iteration ##{iteration.number} is not the current iteration of the run.")
          end

          [iteration, false]
        elsif created
          [starter.ensure_initial!(attributes), true]
        elsif !had_iteration && !plan.new_iteration?
          # Legacy run: its earlier results become iteration 1.
          [starter.ensure_initial!(attributes.merge(name: nil, source: run.source)), true]
        elsif plan.new_iteration?
          same = opts.external_ref && run.iterations.find_by(external_ref: opts.external_ref)
          same ? [same, false] : [starter.start!(attributes), true]
        else
          [run.current_iteration, false]
        end
      end

      # Returns [[record, cases], …] for matched (or created) cases; unmatched ones are collected.
      def match(records, opts, unmatched, warnings, references)
        matches = CaseMatcher.new(project:, strategy: opts.case_matcher, references:).call(records)
        creator = case_creator(opts, warnings, references)
        created = 0
        entries = records.zip(matches).filter_map do |record, match|
          cases = match.cases
          if cases.empty? && creator && match.reason == "no_matching_case" && record.reference.present?
            cases = [creator.call(record)]
            created += 1
          elsif cases.any? && opts.update_references? && match.matched_by != "reference"
            write_back_reference(record, cases, warnings, references)
          end
          if cases.empty?
            unmatched << { "reference" => record.reference, "title" => record.display_title, "file" => record.file,
                           "status" => record.raw_status, "projectName" => record.project_name,
                           "reason" => match.reason }.compact
            next
          end
          [record, cases]
        end
        [entries, created]
      end

      def case_creator(opts, warnings, references)
        return unless opts.auto_create_cases?
        return CaseCreator.new(user:, project:, options: opts, references:) if allowed?(:add_test_cases)

        warnings << { "code" => "auto_create_not_permitted" }
        nil
      end

      # Store the reported reference on a case matched by id/property/title, only when
      # its reference is blank, the user may edit cases and no other case uses it. With a known
      # repository the reference is stored repo-qualified (0016, Reference::Context#reference_for).
      def write_back_reference(record, cases, warnings, references)
        return if record.reference.blank? || cases.size != 1 || !allowed?(:edit_test_cases)

        test_case = cases.first
        return if test_case.automation_reference.present?

        reference = references.reference_for(record).first(1024)
        clash = project.tm_test_cases.not_deleted.where(automation_reference: [reference,
                                                                               *references.candidates(record.reference)])
                       .where.not(id: test_case.id)
        if clash.exists?
          warnings << { "code" => "reference_conflict", "reference" => reference, "caseId" => test_case.id }
        else
          test_case.update_columns(automation_reference: reference, automated: true)
        end
      end

      def close_run(outcome, _opts)
        run = outcome.run.reload
        return unless run.active?

        call = TestManagement::TestRuns::CompleteService.new(user:, model: run).call(completion_source: "automation")
        return if call.success?

        import = outcome.import
        import.update_columns(warnings: import.warnings_list + [{ "code" => "close_run_failed",
                                                                  "errors" => call.errors.full_messages }])
      end
    end
  end
end
