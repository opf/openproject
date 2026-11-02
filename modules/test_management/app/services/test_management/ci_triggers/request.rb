# frozen_string_literal: true

module TestManagement
  module CiTriggers
    # What a "Run in CI" asks for (UI form or APIv3), validated by TriggerContract.
    #   connection – the CI connection to trigger
    #   mode       – new_run (a new run with the selected cases) or new_iteration (a new
    #                iteration of the existing run `run`)
    #   scope      – exactly one of run / suite (folder, incl. sub-folders) / test_case.
    #                In new_iteration mode without suite / test case, the run is the scope.
    #   ref        – git ref (branch / tag); default: the connection's ref, else "main"
    #   milestone  – optional (0012): the milestone the new run is assigned to (new_run only;
    #                a new iteration belongs to the run's milestone)
    class Request
      include ActiveModel::Model
      include ActiveModel::Attributes

      MODES = %w[new_run new_iteration].freeze
      GREP_MAX_LENGTH = 1000

      attr_accessor :project, :connection, :run, :suite, :test_case, :milestone

      attribute :mode, :string, default: "new_run"
      attribute :ref, :string
      attribute :name, :string

      def self.model_name = ActiveModel::Name.new(self, nil, "CiTrigger")

      def new_iteration? = mode == "new_iteration"

      def effective_ref = ref.to_s.strip.presence || connection&.effective_trigger_ref

      # The cases this trigger executes (not deleted, of the project).
      def cases
        return TestCase.none if project.nil?

        scope = TestCase.where(project_id: project.id).not_deleted
        if test_case
          scope.where(id: test_case.id)
        elsif suite
          scope.where(suite_id: Suite.subtree_ids(project, [suite.id]))
        elsif run
          scope.where(id: run.run_cases.select(:test_case_id))
        else
          TestCase.none
        end
      end

      # Automated cases of the scope this connection can run: unqualified references and references
      # qualified with the connection's reference name (0016). "api:…" cases are not run by "shop".
      def automated_cases
        scope = cases.where.not(automation_reference: [nil, ""]).order(:id)
        return scope if connection.nil? || project.nil?

        names = TestManagement::CiConnection.reference_names(project)
        own = connection.reference_qualifier_name
        ids = scope.pluck(:id, :automation_reference).filter_map do |id, reference|
          parsed = TestManagement::Automation::Reference.parse(reference, names:)
          id if !parsed.qualified? || parsed.for_name?(own)
        end
        scope.where(id: ids)
      end

      # Playwright-style --grep pattern for the automated cases: the part after "#" of each
      # automation reference ("tests/login.spec.ts#rejects bad password", "shop:…" without the
      # repository qualifier), or the reference itself when it has no "#". Regex-escaped and joined
      # with "|". Empty when the pattern would exceed GREP_MAX_LENGTH: the job then runs everything
      # and the upload is still filed into the pre-created iteration.
      def grep
        names = project ? TestManagement::CiConnection.reference_names(project) : nil
        parts = automated_cases.pluck(:automation_reference).map do |reference|
          parsed = TestManagement::Automation::Reference.parse(reference, names:)
          Regexp.escape((parsed.fragment || parsed.path).strip)
        end
        pattern = parts.uniq.join("|")
        pattern.length > GREP_MAX_LENGTH ? "" : pattern
      end

      def scope_label
        if test_case then "##{test_case.id} #{test_case.title}"
        elsif suite then suite.name
        elsif run then run.name
        end
      end
    end
  end
end
