# frozen_string_literal: true

module TestManagement
  module CiTriggers
    # Validates a "Run in CI" request (TestManagement::CiTriggers::Request):
    # - the user may trigger test automation in the project;
    # - the connection belongs to the project, is active and has what its provider needs;
    # - exactly one scope (run, folder or case) of the same project; new_iteration needs an
    #   active run of the project;
    # - the scope contains at least one automated case (automation reference set);
    # - the ref looks like a git ref;
    # - an optional milestone (new_run only) is an open milestone of the project with
    #   milestones enabled.
    class TriggerContract
      include ActiveModel::Validations

      PERMISSION = :trigger_test_automation

      attr_reader :model, :user

      delegate :project, :connection, :run, :suite, :test_case, :mode, to: :model

      validate :user_allowed
      validate :connection_usable
      validate :mode_and_scope
      validate :automated_cases_present
      validate :ref_format
      validate :milestone_assignable

      def initialize(model, user)
        @model = model
        @user = user
      end

      # Errors are reported on the request itself (request.errors), so callers and forms
      # render them like model errors. A separate ActiveModel::Errors instance would leave
      # request.errors empty.
      delegate :errors, to: :model

      private

      def user_allowed
        return if project && user.allowed_in_project?(PERMISSION, project)

        errors.add(:base, :error_unauthorized)
      end

      def connection_usable
        if connection.nil? || connection.project_id != project&.id
          errors.add(:connection, :blank)
        elsif !connection.active?
          errors.add(:connection, :inactive)
        elsif (missing = connection.trigger_missing).any?
          errors.add(:connection, :not_ready,
                     missing: missing.map { |a| CiConnection.human_attribute_name(a) }.join(", "))
        end
      end

      def mode_and_scope
        errors.add(:mode, :inclusion) unless Request::MODES.include?(mode)
        errors.add(:base, :tm_ci_scope_missing) if [run, suite, test_case].compact.empty?
        errors.add(:base, :tm_ci_scope_ambiguous) if [suite, test_case].compact.size > 1
        errors.add(:suite, :invalid) if suite && suite.project_id != project&.id
        errors.add(:test_case, :invalid) if test_case && (test_case.project_id != project&.id || test_case.deleted_at)
        return if run.nil? && !model.new_iteration?

        if run.nil? || run.project_id != project&.id
          errors.add(:run, :blank)
        elsif model.new_iteration? && !run.active?
          errors.add(:run, :tm_run_finished)
        end
      end

      def automated_cases_present
        return if errors.any?
        return if model.automated_cases.exists?

        errors.add(:base, :tm_ci_no_automated_cases)
      end

      def milestone_assignable
        milestone = model.milestone
        return if milestone.nil?

        if model.new_iteration?
          errors.add(:milestone, :tm_ci_milestone_new_run_only)
        elsif milestone.project_id != project&.id || !::TestManagement::ProjectSetting.milestones_enabled?(project)
          errors.add(:milestone, :invalid)
        elsif milestone.completed?
          errors.add(:milestone, :tm_milestone_completed)
        end
      end

      def ref_format
        ref = model.ref.to_s.strip
        return if ref.blank?

        errors.add(:ref, :invalid) unless ref.length <= 255 && ref.match?(CiConnection::REF_FORMAT)
      end
    end
  end
end
