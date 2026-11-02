# frozen_string_literal: true

module TestManagement
  module CiTriggers
    # "Run in CI" (0011): executes the automated cases of a run, a folder or one case in CI.
    #  1. validate (TriggerContract: permission :trigger_test_automation, connection ready, scope);
    #  2. pre-create where the results go:
    #       new_run       – a new run (source automation, specific selection) with the scope's
    #                       cases, and its iteration 1;
    #       new_iteration – a new iteration of the given active run; scope cases missing in a
    #                       specific run are added first;
    #  3. trigger the CI job (Dispatchers::*) with op_run_id, op_iteration_id, op_project and
    #     op_grep (automation references of the automated cases);
    #  4. record the outcome on the run (ci_trigger_status/url/error/triggered_at) and on the
    #     iteration (ci_metadata["trigger"], plus runUrl when the provider returned one).
    # A failed trigger keeps the run / iteration (the error is shown there; the job can be
    # started by hand with the same values) and returns success with outcome.status "failed".
    # Inbound-only connections (0015) send nothing: outcome.status "manual", and the run page
    # shows the variables / command to start the pipeline by hand (ManualStart).
    class TriggerService
      # :grep is the CI filter string (op_grep), not Enumerable#grep.
      Outcome = Struct.new(:run, :iteration, :status, :url, :external_id, :error, :grep, :ref, # rubocop:disable Lint/StructNewOverride
                           keyword_init: true) do
        def triggered? = status == "triggered"
        def manual? = status == "manual"
      end

      GREP_KEEP_CHARS = 8_000

      def initialize(user:)
        @user = user
      end

      # params: project, connection, mode, run, suite, test_case, ref, name, milestone
      def call(params)
        request = Request.new(**params.to_h.symbolize_keys.slice(:project, :connection, :mode, :run, :suite,
                                                                 :test_case, :ref, :name, :milestone).compact)
        contract = TriggerContract.new(request, user)
        return ServiceResult.failure(result: request, errors: contract.errors) unless contract.valid?

        run, iteration = prepare(request)
        inputs = {
          "op_run_id" => run.id, "op_iteration_id" => iteration.id,
          "op_project" => request.project.identifier, "op_grep" => request.grep
        }
        result = Dispatchers::Base.for(request.connection).call(ref: request.effective_ref, inputs:)
        record(run, iteration, request, result)

        ServiceResult.success(result: Outcome.new(run:, iteration:, status: result.status, url: result.url,
                                                  external_id: result.external_id, error: result.error,
                                                  grep: inputs["op_grep"], ref: request.effective_ref))
      end

      private

      attr_reader :user

      def prepare(request)
        TestRun.transaction do
          run = request.new_iteration? ? request.run : create_run(request)
          run.with_lock do
            run.add_cases!(request.cases.order(:id)) if request.new_iteration? && run.selection_mode == "specific"
            iteration = TestRunIterations::Starter.new(run:, user:).start!(
              name: request.name.presence || I18n.t("test_management.ci_triggers.iteration_name",
                                                    connection: request.connection.name),
              source: "automation", connection: request.connection,
              ci_metadata: { "trigger" => { "status" => "pending", "ref" => request.effective_ref } }
            )
            [run, iteration]
          end
        end
      end

      def create_run(request)
        run = TestRun.new(
          project: request.project,
          # Not `scope:` – that is a reserved I18n option (it would become the key's namespace).
          name: (request.name.presence || I18n.t("test_management.ci_triggers.run_name",
                                                 target: request.scope_label, connection: request.connection.name)).first(255),
          source: "automation", selection_mode: "specific", state: "new",
          author: user, connection: request.connection, milestone: request.milestone
        )
        run.save!
        run.add_cases!(request.cases.order(:id))
        run
      end

      def record(run, iteration, request, result)
        now = Time.current
        run.update_columns(ci_trigger_status: result.status, ci_trigger_url: result.url,
                           ci_trigger_error: result.error, ci_triggered_at: now, updated_at: now)
        trigger = { "status" => result.status, "url" => result.url, "externalId" => result.external_id,
                    "error" => result.error, "ref" => request.effective_ref, "connection" => request.connection.name,
                    "triggeredBy" => user.id, "triggeredAt" => now.utc.iso8601 }.compact
        # Inbound only: the values are shown on the run page to start the pipeline by hand.
        trigger["grep"] = request.grep.to_s.first(GREP_KEEP_CHARS) if result.status == "manual"
        metadata = iteration.ci_info.merge("trigger" => trigger)
        metadata["runUrl"] ||= result.url if result.triggered? && result.url
        metadata["provider"] ||= request.connection.provider
        iteration.update_columns(ci_metadata: metadata, updated_at: now)
      end
    end
  end
end
