# frozen_string_literal: true

module TestManagement
  module Exports
    # Milestone summary (object: TestManagement::Milestone): milestone info, aggregated
    # status counts and pass rate (own runs + sub-milestone runs, cancelled runs excluded),
    # then one row per run with its own counts.
    class MilestoneExporter < BaseExporter
      STATUS_COLUMNS = TestManagement::TestRunCase::STATUSES

      def milestone
        object
      end

      def title
        I18n.t("test_management.exports.milestone_title", id: milestone.formatted_id, name: milestone.name)
      end

      def counts
        milestone.status_counts
      end

      def preamble
        total = counts.values.sum
        pairs = [
          [I18n.t("test_management.exports.milestone"), "#{milestone.formatted_id} #{milestone.name}"],
          [TestManagement::Milestone.human_attribute_name(:status),
           I18n.t("test_management.milestones.statuses.#{milestone.status}")],
          [TestManagement::Milestone.human_attribute_name(:parent), milestone.parent&.name.to_s],
          [TestManagement::Milestone.human_attribute_name(:start_date),
           milestone.start_date ? format_date(milestone.start_date) : ""],
          [TestManagement::Milestone.human_attribute_name(:due_date), milestone.due_date ? format_date(milestone.due_date) : ""],
          [I18n.t("test_management.milestones.overdue"), yes_no(milestone.overdue?)],
          [TestManagement::Milestone.human_attribute_name(:version), milestone.version&.name.to_s],
          [I18n.t("test_management.runs.sections.references"), references]
        ]
        if milestone.completed_at
          pairs << [TestManagement::Milestone.human_attribute_name(:completed_at),
                    time_value(milestone.completed_at)]
        end
        pairs << [I18n.t("test_management.exports.runs_count"), milestone.runs_count]
        pairs << [I18n.t("test_management.exports.total"), total]
        STATUS_COLUMNS.each do |status|
          pairs << [I18n.t("test_management.runs.statuses.#{status}"), "#{counts[status]} (#{percent(counts[status], total)}%)"]
        end
        pairs << [I18n.t("test_management.exports.pass_rate"), "#{TestManagement::TestRun.pass_rate(counts)}%"]
        pairs
      end

      def headers
        [
          I18n.t("test_management.exports.columns.milestone"),
          I18n.t("test_management.exports.columns.run_id"),
          I18n.t("test_management.exports.columns.run"),
          I18n.t("test_management.exports.state"),
          I18n.t("test_management.exports.total")
        ] + STATUS_COLUMNS.map { |status| I18n.t("test_management.runs.statuses.#{status}") } +
          [I18n.t("test_management.exports.pass_rate")]
      end

      def rows
        @rows ||= runs.map do |run|
          run_counts = run_status_counts.fetch(run.id)
          [
            run.milestone.name,
            run.formatted_id,
            run.name,
            I18n.t("test_management.runs.states.#{run.state}"),
            run_counts.values.sum
          ] + STATUS_COLUMNS.map { |status| run_counts[status] } + ["#{TestManagement::TestRun.pass_rate(run_counts)}%"]
        end
      end

      def runs
        @runs ||= TestManagement::TestRun
                    .where(milestone_id: [milestone.id] + milestone.children.pluck(:id))
                    .includes(:milestone)
                    .order(:id)
                    .to_a
      end

      def render_pdf(pdf)
        pdf_key_values(pdf, preamble)
        pdf_heading(pdf, I18n.t("test_management.milestones.runs"))
        if rows.empty?
          pdf.text I18n.t("test_management.milestones.no_runs"), size: 10
          return
        end

        header = headers.values_at(0, 2, 3, 4, 5, 6, 11, 12)
        data = rows.map { |row| row.values_at(0, 2, 3, 4, 5, 6, 11, 12) }
        widths = [0.17, 0.25, 0.12, 0.08, 0.08, 0.08, 0.11, 0.11].map { |r| pdf.bounds.width * r }
        pdf_table(pdf, header, data, widths:)
      end

      protected

      def column_widths
        [24, 10, 36, 14, 8] + STATUS_COLUMNS.map { 10 } + [10]
      end

      private

      def run_status_counts
        @run_status_counts ||= begin
          ids = runs.map(&:id)
          raw = TestManagement::TestRunCase.where(test_run_id: ids)
                                           .group(:test_run_id, TestManagement::TestRunCase.effective_status_sql)
                                           .count
          ids.index_with { |id| STATUS_COLUMNS.index_with { |status| raw[[id, status]].to_i } }
        end
      end

      def references
        ids = milestone.linked_work_package_ids
        return "" if ids.empty?

        ::WorkPackage.visible(current_user).where(id: ids).order(:id).pluck(:id, :subject)
                     .map { |id, subject| "##{id} #{subject}" }
                     .join(LIST_SEPARATOR)
      end

      def percent(count, total)
        return 0 if total.zero?

        ((count.to_f / total) * 100).round
      end
    end
  end
end
