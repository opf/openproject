# frozen_string_literal: true

module TestManagement
  module Exports
    # Exports one test run (object: TestManagement::TestRun): run info, state,
    # statistics and pass rate, then its cases grouped by folder.
    class TestRunExporter < BaseExporter
      # failed_step / error (0020): "3. <step action>" and the first ERROR_CELL_LIMIT characters of
      # the result's error. The PDF lists them in a "Failures" section instead of table columns.
      COLUMNS = %i[id title folder labels assignee status comment result_by result_at failed_step error].freeze
      PDF_COLUMNS = COLUMNS - %i[folder failed_step error]
      ERROR_CELL_LIMIT = 1000
      STATUS_COLUMN = PDF_COLUMNS.index(:status)

      def run
        object
      end

      def title
        I18n.t("test_management.exports.run_title", id: run.formatted_id, name: run.name)
      end

      def counts
        @counts ||= begin
          counts = TestManagement::TestRunCase::STATUSES.index_with { 0 }
          run_cases.each { |rc| counts[rc.effective_status] += 1 }
          counts
        end
      end

      def preamble
        total = run_cases.size
        pairs = [
          [I18n.t("test_management.exports.run"), "#{run.formatted_id} #{run.name}"],
          [I18n.t("test_management.exports.state"), I18n.t("test_management.runs.states.#{run.state}")],
          [I18n.t("test_management.exports.assignee"), user_name(run.assigned_to)],
          [I18n.t("test_management.exports.created_by"), "#{user_name(run.author)} #{time_value(run.created_at)}".strip],
          [I18n.t("test_management.runs.sections.starts"), run.start_date ? format_date(run.start_date) : ""],
          [I18n.t("test_management.runs.sections.ends"), run.end_date ? format_date(run.end_date) : ""],
          [I18n.t("test_management.runs.sections.references"), references]
        ]
        if run.finished?
          pairs << [I18n.t("test_management.exports.finished"),
                    "#{user_name(run.finished_by)} #{time_value(run.finished_at)}".strip]
        end
        pairs << [I18n.t("test_management.exports.total"), total]
        TestManagement::TestRunCase::STATUSES.each do |status|
          pairs << [I18n.t("test_management.runs.statuses.#{status}"), "#{counts[status]} (#{percent(counts[status], total)}%)"]
        end
        pairs << [I18n.t("test_management.exports.pass_rate"), "#{TestManagement::TestRun.pass_rate(counts)}%"]
        pairs
      end

      def headers
        COLUMNS.map { |column| I18n.t("test_management.exports.columns.#{column}") }
      end

      def rows
        @rows ||= grouped.flat_map { |folder, cases| cases.map { |rc| row_for(rc, folder) } }
      end

      # [[folder path, [run cases]]] ordered by path (unfiled last), cases by id.
      def grouped
        @grouped ||= run_cases
                       .group_by { |rc| rc.test_case.suite_id }
                       .sort_by { |suite_id, _| [suite_id ? 0 : 1, paths[suite_id].to_s.downcase] }
                       .map { |suite_id, cases| [suite_id ? paths[suite_id].to_s : unfiled_label, cases.sort_by(&:test_case_id)] }
      end

      def run_cases
        @run_cases ||= run.run_cases
                          .joins(:test_case)
                          .merge(TestManagement::TestCase.not_deleted)
                          .includes(:assigned_to, test_case: :labels)
                          .to_a
      end

      def render_pdf(pdf)
        pdf_key_values(pdf, preamble)

        pdf_heading(pdf, I18n.t("test_management.exports.cases"))
        if grouped.empty?
          pdf.text I18n.t("test_management.exports.no_cases"), size: 10
          return
        end

        header = PDF_COLUMNS.map { |column| I18n.t("test_management.exports.columns.#{column}") }
        widths = [0.06, 0.24, 0.12, 0.12, 0.09, 0.2, 0.08, 0.09].map { |r| pdf.bounds.width * r }
        grouped.each do |folder, cases|
          pdf.move_down 6
          pdf.text "#{folder} (#{cases.size})", size: 10, style: :bold
          pdf.move_down 2
          data = cases.map { |rc| row_for(rc, folder).values_at(0, 1, 3, 4, 5, 6, 7, 8) }
          pdf_table(pdf, header, data, widths:) do |table|
            cases.each_with_index do |rc, index|
              table.cells[index + 1, STATUS_COLUMN].text_color = status_color(rc.effective_status)
              table.cells[index + 1, STATUS_COLUMN].font_style = :bold
            end
          end
        end
        render_pdf_failures(pdf)
      end

      def render_pdf_failures(pdf)
        failures = rows.select { |row| row[9].present? || row[10].present? }
        return if failures.empty?

        pdf_heading(pdf, I18n.t("test_management.exports.failures"))
        header = %i[id title failed_step error].map { |column| I18n.t("test_management.exports.columns.#{column}") }
        widths = [0.08, 0.25, 0.22, 0.45].map { |r| pdf.bounds.width * r }
        pdf_table(pdf, header, failures.map { |row| row.values_at(0, 1, 9, 10) }, widths:)
      end

      protected

      def column_widths
        [8, 40, 30, 20, 20, 12, 50, 20, 18, 40, 60]
      end

      private

      def row_for(run_case, folder)
        result = last_result(run_case)
        [
          run_case.test_case.formatted_id,
          run_case.test_case.title,
          folder,
          run_case.test_case.labels.map(&:name).sort_by(&:downcase).join(LIST_SEPARATOR),
          user_name(run_case.assigned_to),
          I18n.t("test_management.runs.statuses.#{run_case.effective_status}"),
          result&.comment.to_s,
          user_name(result&.user),
          result ? time_value(result.created_at) : "",
          failed_step_value(result),
          error_value(result)
        ]
      end

      def failed_step_value(result)
        step = result&.failed_step
        return "" unless step

        "#{step.number}. #{step.label.to_s.squish.truncate(200)}"
      end

      def error_value(result)
        return "" unless result

        step = result.failed_step
        (result.error_message.presence || step&.error_message.presence || step&.actual_result).to_s.first(ERROR_CELL_LIMIT)
      end

      # Latest result per run case (same as the run page), without loading the whole history.
      def last_result(run_case)
        last_results[run_case.id]
      end

      def last_results
        @last_results ||= TestManagement::TestResult.latest_by_run_case(run_cases.map(&:id))
      end

      # Same palette as the run page; untested uses a readable grey for text.
      def status_color(status)
        return "57606A" if status == "untested"

        TestManagement::TestRunsHelper::STATUS_COLORS.fetch(status, "#57606A").delete("#").upcase
      end

      def references
        ids = run.linked_work_package_ids
        return "" if ids.empty?

        ::WorkPackage.visible(current_user).where(id: ids).order(:id).pluck(:id, :subject)
                     .map { |id, subject| "##{id} #{subject}" }
                     .join(LIST_SEPARATOR)
      end

      def paths
        @paths ||= folder_paths(run.project)
      end

      def percent(count, total)
        return 0 if total.zero?

        ((count.to_f / total) * 100).round
      end
    end
  end
end
