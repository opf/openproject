# frozen_string_literal: true

module TestManagement
  module Automation
    # Finds or creates the run an upload reports into:
    # - runId: that run (404 unknown, 409 completed/cancelled);
    # - externalRef: the run with that reference (parallel shards / retries of one
    #   CI run share it), created on first use (409 when it is already finished);
    # - otherwise a new automation run named after the CI metadata.
    # In new_iteration mode (0009) the externalRef identifies the iteration, not the run:
    # - runId: that run;
    # - targetRun: the newest active run with that name (case-insensitive), created when
    #   there is none (warning "target_run_created");
    # - neither: 422.
    # - iterationId (0011, "Run in CI"): the run of that iteration (runId, if given, must match).
    # A run created here is assigned to the `milestone` option (id, "M<id>" or name) when it
    # names an open milestone of the project; otherwise the upload goes on with a warning
    # (milestone_not_found / milestones_disabled / milestone_completed).
    # Returns [run, created?].
    class RunResolver
      def initialize(user:, project:, options:, warnings: [], plan: nil)
        @user = user
        @project = project
        @options = options
        @warnings = warnings
        @plan = plan || ConnectionResolver::Plan.new(mode: options.mode || "new_run", target_run: options.target_run)
      end

      def call
        return [existing(run_of_iteration), false] if options.iteration_id
        return [existing(project.tm_test_runs.find_by(id: options.run_id)), false] if options.run_id
        return by_target_run if plan.new_iteration?
        return by_external_ref if options.external_ref

        [create_run, true]
      end

      private

      attr_reader :user, :project, :options, :warnings, :plan

      def run_of_iteration
        iteration = TestRunIteration.joins(:test_run).where(tm_test_runs: { project_id: project.id })
                                    .find_by(id: options.iteration_id)
        raise Error.new(:not_found, "The test run iteration does not exist in this project.") unless iteration
        if options.run_id && options.run_id.to_s != iteration.test_run_id.to_s
          raise Error.new(:unprocessable, "iterationId does not belong to runId.")
        end

        iteration.test_run
      end

      def by_target_run
        name = plan.target_run
        if name.blank?
          raise Error.new(:unprocessable, "mode new_iteration needs runId or targetRun (or a CI connection with a target run).")
        end

        # Serialize "find or create" of the target run, so parallel shards of the first
        # pipeline do not create two runs with the same name.
        project.with_lock do
          run = project.tm_test_runs.active.where("LOWER(tm_test_runs.name) = ?", name.downcase).newest_first.first
          next [run, false] if run

          warnings << { "code" => "target_run_created", "name" => name }
          [create_run(name:), true]
        end
      end

      def existing(run)
        raise Error.new(:not_found, "The test run does not exist in this project.") unless run
        if run.finished?
          raise Error.new(:conflict,
                          "Test run #{run.formatted_id} is #{run.state}; results can no longer be added.")
        end

        run
      end

      def by_external_ref
        run = project.tm_test_runs.find_by(external_ref: options.external_ref)
        return [existing(run), false] if run

        [create_run(external_ref: options.external_ref), true]
      rescue ActiveRecord::RecordNotUnique
        # Another shard created it concurrently.
        [existing(project.tm_test_runs.find_by(external_ref: options.external_ref)), false]
      end

      def create_run(external_ref: nil, name: nil)
        run = project.tm_test_runs.new(
          name: name || options.run_name || default_name,
          description: description,
          source: "automation",
          selection_mode: "specific",
          state: "in_progress",
          author: user,
          external_ref:,
          ci_metadata: options.ci,
          connection: plan.connection
        )
        link_work_packages(run)
        assign_milestone(run)
        run.save!
        run
      end

      def default_name
        options.ci_title || "Automation run #{Time.current.utc.iso8601}"
      end

      def description
        url = options.ci["runUrl"]
        url.present? && url.match?(%r{\Ahttps?://}i) ? "CI run: #{url}" : nil
      end

      def assign_milestone(run)
        ref = options.milestone_ref
        return if ref.blank?

        unless ::TestManagement::ProjectSetting.milestones_enabled?(project)
          warnings << { "code" => "milestones_disabled", "milestone" => ref }
          return
        end

        milestone = ::TestManagement::Milestone.lookup(project, ref)
        if milestone.nil?
          warnings << { "code" => "milestone_not_found", "milestone" => ref }
        elsif milestone.completed?
          warnings << { "code" => "milestone_completed", "milestone" => ref, "id" => milestone.id }
        else
          run.milestone = milestone
        end
      end

      def link_work_packages(run)
        ids = options.work_package_ids
        return if ids.empty?

        visible = ::WorkPackage.visible(user).where(id: ids).pluck(:id)
        (ids - visible).each { |id| warnings << { "code" => "work_package_not_visible", "id" => id } }
        visible.each { |id| run.test_run_work_packages.build(work_package_id: id) }
      end
    end
  end
end
