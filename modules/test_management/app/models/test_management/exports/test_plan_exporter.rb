# frozen_string_literal: true

module TestManagement
  module Exports
    class TestPlanExporter < BaseExporter
      STATUS_COLUMNS = TestManagement::TestRunCase::STATUSES

      def plan
        object
      end

      def title
        I18n.t("test_management.exports.plan_title", id: plan.formatted_id, name: plan.name)
      end

      def counts
        plan.status_counts
      end

      def preamble
        total = counts.values.sum
        pairs = [
          [I18n.t("test_management.exports.plan"), "#{plan.formatted_id} #{plan.name}"],
          [TestManagement::TestPlan.human_attribute_name(:state), I18n.t("test_management.plans.states.#{plan.state}")],
          [I18n.t("test_management.exports.milestone"), plan.milestone&.name.to_s],
          [I18n.t("test_management.exports.runs_count"), plan.runs_count],
          [I18n.t("test_management.exports.total"), total]
        ]
        STATUS_COLUMNS.each do |status|
          pairs << [I18n.t("test_management.runs.statuses.#{status}"), "#{counts[status]} (#{percent(counts[status], total)}%)"]
        end
        pairs << [I18n.t("test_management.exports.pass_rate"), "#{TestManagement::TestRun.pass_rate(counts)}%"]
        pairs
      end

      def headers
        [
          I18n.t("test_management.exports.columns.run_id"),
          I18n.t("test_management.exports.columns.run"),
          I18n.t("test_management.exports.columns.configuration"),
          I18n.t("test_management.exports.state"),
          *STATUS_COLUMNS.map { |s| I18n.t("test_management.runs.statuses.#{s}") },
          I18n.t("test_management.exports.pass_rate")
        ]
      end

      def rows
        plan.test_runs.newest_first.map do |run|
          run_counts = run.status_counts
          [
            run.formatted_id,
            run.name,
            run.configuration_label.to_s,
            I18n.t("test_management.runs.states.#{run.state}"),
            *STATUS_COLUMNS.map { |s| run_counts[s] },
            "#{TestManagement::TestRun.pass_rate(run_counts)}%"
          ]
        end
      end
    end
  end
end
