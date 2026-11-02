# frozen_string_literal: true

module TestManagement
  module Plans
    # Creates a new plan by copying entries/selection/configs from an existing plan.
    class RerunService
      def initialize(user:, model:, params: {})
        @user = user
        @source = model
        @params = params.to_h.with_indifferent_access
      end

      def call
        return failure(:error_unauthorized) unless user.allowed_in_project?(:manage_test_plans, source.project)
        return failure(:tm_plans_disabled) unless ProjectSetting.plans_enabled?(source.project)

        new_plan = nil
        TestPlan.transaction do
          create = CreateService.new(user:).call(
            project: source.project,
            name: params[:name].presence || source.name,
            description: source.description,
            milestone_id: params.key?(:milestone_id) ? params[:milestone_id].presence : source.milestone_id,
            assigned_to_id: params[:copy_assignees] ? source.assigned_to_id : nil,
            work_package_ids: source.linked_work_package_ids,
            start_date: source.start_date,
            end_date: source.end_date
          )
          raise ActiveRecord::Rollback unless create.success?

          new_plan = create.result
          source.entries.each do |entry|
            entry_params = {
              test_plan: new_plan,
              name: entry.name,
              description: entry.description,
              position: entry.position,
              selection_mode: entry.selection_mode,
              filter_options: entry.filter_options,
              case_ids: filtered_case_ids(entry),
              configuration_ids: entry.configuration_ids,
              assigned_to_id: params[:copy_assignees] ? entry.assigned_to_id : nil
            }
            result = Entries::CreateService.new(user:).call(entry_params)
            raise ActiveRecord::Rollback unless result.success?
          end
        end

        return failure(:tm_rerun_failed) if new_plan.nil? || !new_plan.persisted?

        ServiceResult.success(result: new_plan.reload)
      end

      private

      attr_reader :user, :source, :params

      def filtered_case_ids(entry)
        ids = entry.selected_case_ids
        status_ids = Array(params[:status_ids]).map(&:to_s).presence
        return ids if status_ids.nil? || entry.selection_mode != "specific"

        run_ids = source.test_runs.where(test_plan_entry_id: entry.id).where.not(state: "cancelled").pluck(:id)
        return [] if run_ids.empty?

        TestRunCase.where(test_run_id: run_ids, test_case_id: ids)
                   .where(TestRunCase.effective_status_sql.in(status_ids))
                   .distinct
                   .pluck(:test_case_id)
      end

      def failure(error)
        source.errors.add(:base, error)
        ServiceResult.failure(result: source, errors: source.errors)
      end
    end
  end
end
