# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "digest"

module TestManagement
  module Automation
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

      def call(content:, options: {}) # rubocop:disable Metrics/AbcSize
        authorize!
        content = content.to_s
        raise Error.new(:payload_too_large, "The report exceeds #{MAX_BYTES / 1024 / 1024} MB.") if content.bytesize > MAX_BYTES

        opts = options.is_a?(Options) ? options : Options.new(options)
        format, records = Parser.parse(content, opts.format)
        raise Error.new(:payload_too_large, "The report has more than #{MAX_TESTS} tests.") if records.size > MAX_TESTS

        warnings = []
        plan = ConnectionResolver.new(project:, options: opts, warnings:).call
        run, created = RunResolver.new(user:, project:, options: opts, warnings:, plan:).call
        outcome = ingest(run, created, plan, format, records, opts, warnings, Digest::SHA256.hexdigest(content))
        close_run(outcome) if opts.close_run?
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

      def ingest(run, created, plan, format, records, opts, warnings, digest) # rubocop:disable Metrics/AbcSize
        run.with_lock do
          if run.finished?
            raise Error.new(:conflict, "Test run #{run.formatted_id} is #{run.state}; results can no longer be added.")
          end

          iteration, created_iteration = pick_iteration(run, created, plan, opts)
          base = { run:, iteration:, mode: plan.mode, connection: plan.connection }
          replayed = run.automation_imports.find_by(iteration_id: iteration.id, digest:, state: "done")
          next Outcome.new(import: replayed, created_run: false, replay: true, created_iteration: false, **base) if replayed

          import = run.automation_imports.create!(project:, user:, format:, state: "processing", digest:,
                                                  iteration:, external_ref: opts.external_ref,
                                                  options: opts.to_h, parsed_count: records.size)
          unmatched = []
          entries, created_cases = match(records, opts, unmatched, warnings)
          mapper = StatusMapper.new(skipped_as: opts.skipped_as, flaky_as: opts.flaky_as, status_map: opts.status_map)
          matched = ResultWriter.new(user:, run:, import:, options: opts, mapper:, unmatched:).call(entries)
          run.update!(ci_metadata: run.ci_info.merge(opts.ci)) if opts.ci.any?
          run.update!(connection: plan.connection) if plan.connection && run.connection_id.nil?
          iteration.update!(ci_metadata: iteration.ci_info.merge(opts.ci)) if opts.ci.any? && !created_iteration

          import.update!(state: "done", matched_count: matched, created_cases_count: created_cases,
                         unmatched_count: unmatched.size, unmatched: unmatched.first(1000),
                         warnings: warnings.first(200))
          Outcome.new(import:, created_run: created, replay: false, created_iteration:, **base)
        end
      end

      def pick_iteration(run, created, plan, opts) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        starter = TestManagement::TestRunIterations::Starter.new(run:, user:)
        attributes = { name: opts.iteration_name || opts.ci_title, source: "automation", external_ref: opts.external_ref,
                       ci_metadata: opts.ci, connection: plan.connection }
        had_iteration = run.current_iteration.present?

        if opts.iteration_id
          iteration = run.iterations.find_by(id: opts.iteration_id)
          raise Error.new(:not_found, "The test run iteration does not exist.") unless iteration
          unless iteration.id == run.current_iteration&.id
            raise Error.new(:conflict, "Iteration ##{iteration.number} is not the current iteration of the run.")
          end

          [iteration, false]
        elsif created
          [starter.ensure_initial!(attributes), true]
        elsif !had_iteration && !plan.new_iteration?
          [starter.ensure_initial!(attributes.merge(name: nil, source: run.source)), true]
        elsif plan.new_iteration?
          same = opts.external_ref && run.iterations.find_by(external_ref: opts.external_ref)
          same ? [same, false] : [starter.start!(attributes), true]
        else
          [run.current_iteration, false]
        end
      end

      def match(records, opts, unmatched, warnings) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        matches = CaseMatcher.new(project:, strategy: opts.case_matcher).call(records)
        creator = case_creator(opts, warnings)
        created = 0
        entries = records.zip(matches).filter_map do |record, match|
          cases = match.cases
          if cases.empty? && creator && match.reason == "no_matching_case" && record.reference.present?
            cases = [creator.call(record)]
            created += 1
          elsif cases.any? && opts.update_references? && match.matched_by != "reference"
            write_back_reference(record, cases, warnings)
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

      def case_creator(opts, warnings)
        return unless opts.create_missing?
        return CaseCreator.new(user:, project:) if allowed?(:add_test_cases)

        warnings << { "code" => "create_missing_not_permitted" }
        nil
      end

      def write_back_reference(record, cases, warnings) # rubocop:disable Metrics/AbcSize
        return if record.reference.blank? || cases.size != 1 || !allowed?(:edit_test_cases)

        test_case = cases.first
        return if test_case.automation_reference.present?

        reference = record.reference.first(1024)
        if project.tm_test_cases.where(automation_reference: reference).where.not(id: test_case.id).exists?
          warnings << { "code" => "reference_conflict", "reference" => reference, "caseId" => test_case.id }
        else
          test_case.update_columns(automation_reference: reference, automated: true)
        end
      end

      def close_run(outcome)
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
