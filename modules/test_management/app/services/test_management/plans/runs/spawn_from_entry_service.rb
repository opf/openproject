# frozen_string_literal: true

module TestManagement
  module Plans
    module Runs
      # Spawns or syncs one TestRun per configuration combination for a plan entry.
      class SpawnFromEntryService
        def initialize(user:, entry:)
          @user = user
          @entry = entry
        end

        def call
          results = []
          desired_keys = []

          entry.configuration_combinations.each do |combo|
            config_ids = combo.map(&:id).sort
            desired_keys << config_ids
            label = combo.map(&:name).join(", ").presence
            existing = find_run(config_ids)

            results << if existing
                         sync_existing(existing)
                       else
                         create_run(config_ids, label)
                       end
          end

          remove_obsolete_runs(desired_keys)

          failed = results.find { |r| !r.success? }
          failed || ServiceResult.success(result: entry)
        end

        private

        attr_reader :user, :entry

        def plan = entry.test_plan

        def find_run(config_ids)
          entry.test_runs.reload.find do |run|
            Array(run.configuration_ids).map(&:to_i).sort == config_ids
          end
        end

        def create_run(config_ids, label)
          name = label.present? ? "#{entry.name} (#{label})" : entry.name
          attrs = {
            project: plan.project,
            name:,
            description: entry.description,
            selection_mode: entry.selection_mode,
            filter_options: entry.filter_options || {},
            assigned_to_id: entry.assigned_to_id,
            milestone_id: plan.milestone_id,
            test_plan_id: plan.id,
            test_plan_entry_id: entry.id,
            configuration_ids: config_ids,
            configuration_label: label
          }
          attrs[:test_case_ids] = entry.selected_case_ids if entry.selection_mode == "specific"

          TestRuns::CreateService.new(user:).call(attrs)
        end

        def sync_existing(run)
          return ServiceResult.success(result: run) unless run.active?

          attrs = {
            selection_mode: entry.selection_mode,
            filter_options: entry.filter_options || {},
            assigned_to_id: entry.assigned_to_id,
            milestone_id: run.milestone_id.presence || plan.milestone_id
          }
          attrs[:test_case_ids] = entry.selected_case_ids if entry.selection_mode == "specific"
          TestRuns::UpdateService.new(user:, model: run).call(attrs)
        end

        # Cancel brand-new empty runs whose combo was removed; leave runs with results alone.
        def remove_obsolete_runs(desired_keys)
          entry.test_runs.find_each do |run|
            key = Array(run.configuration_ids).map(&:to_i).sort
            next if desired_keys.include?(key)
            next unless run.state == "new" && run.run_cases.none? { |rc| rc.status != "untested" }

            run.destroy!
          end
        end
      end
    end
  end
end
