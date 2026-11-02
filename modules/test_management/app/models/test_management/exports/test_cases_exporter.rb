# frozen_string_literal: true

module TestManagement
  module Exports
    # Exports test cases (object: a TestManagement::TestCasesQuery).
    #
    # options:
    #   format:  "pdf" | "csv" | "xls"
    #   scope:   "project" | "folder" | "filter" (see TestCasesQuery)
    #   project: the project
    class TestCasesExporter < BaseExporter
      COLUMNS = %i[id title folder priority status automated labels work_packages
                   preconditions steps created_by created_at updated_by updated_at].freeze

      def query
        object
      end

      def project
        options[:project] || query.project
      end

      def scope
        TestManagement::TestCasesQuery::SCOPES.include?(options[:scope].to_s) ? options[:scope].to_s : query.current_scope
      end

      def title
        I18n.t("test_management.exports.cases_title", project: project.name)
      end

      # Human description of what was exported, e.g. "Folder: Accounts / Sign in (including subfolders)".
      def scope_description
        case scope
        when "folder" then folder_description
        when "filter"
          parts = []
          parts << folder_description if query.folder?
          parts << I18n.t("test_management.exports.filter_search", value: query.params[:q]) if query.params[:q].present?
          parts << "#{I18n.t('test_management.cases.columns.status')}: #{query.params[:status]}" if query.params[:status].present?
          parts << "#{I18n.t('test_management.cases.columns.priority')}: #{query.params[:priority]}" if query.params[:priority].present?
          parts.presence&.join(", ") || I18n.t("test_management.exports.scope_project")
        else
          I18n.t("test_management.exports.scope_project")
        end
      end

      def preamble
        [
          [I18n.t("test_management.exports.scope"), scope_description],
          [I18n.t("test_management.exports.total"), test_cases.size]
        ]
      end

      def headers
        COLUMNS.map { |column| I18n.t("test_management.exports.columns.#{column}") }
      end

      def rows
        @rows ||= test_cases.map { |test_case| row_for(test_case) }
      end

      # Cases ordered by folder path (unfiled last), then id.
      def test_cases
        @test_cases ||= query.results(scope)
                             .includes(:labels, :steps, :author, :updated_by)
                             .to_a
                             .sort_by { |tc| [tc.suite_id ? 0 : 1, paths[tc.suite_id].to_s.downcase, tc.id] }
      end

      def render_pdf(pdf)
        pdf_key_values(pdf, preamble)
        pdf.move_down 8

        if test_cases.empty?
          pdf.text I18n.t("test_management.exports.no_cases"), size: 10
          return
        end

        overview = test_cases.map do |tc|
          [tc.formatted_id, tc.title, folder_for(tc), tc.priority, tc.status, yes_no(tc.automated),
           labels_for(tc), work_packages_for(tc), "#{user_name(tc.updated_by || tc.author)}\n#{time_value(tc.updated_at)}"]
        end
        pdf_table(pdf,
                  %i[id title folder priority status automated labels work_packages updated_at]
                    .map { |c| I18n.t("test_management.exports.columns.#{c}") },
                  overview,
                  widths: pdf_widths(pdf, [0.05, 0.2, 0.14, 0.07, 0.07, 0.07, 0.12, 0.14, 0.14]))

        pdf_heading(pdf, I18n.t("test_management.exports.details"))
        test_cases.each { |tc| render_case_details(pdf, tc) }
      end

      protected

      def column_widths
        [8, 40, 28, 10, 10, 10, 20, 30, 50, 60, 18, 18, 18, 18]
      end

      private

      def row_for(test_case)
        [
          test_case.formatted_id,
          test_case.title,
          folder_for(test_case),
          test_case.priority,
          test_case.status,
          yes_no(test_case.automated),
          labels_for(test_case),
          work_packages_for(test_case),
          test_case.preconditions.to_s,
          steps_for(test_case),
          user_name(test_case.author),
          time_value(test_case.created_at),
          user_name(test_case.updated_by),
          test_case.updated_by ? time_value(test_case.updated_at) : ""
        ]
      end

      def render_case_details(pdf, test_case)
        pdf.move_down 6
        pdf.text "#{test_case.formatted_id} #{test_case.title}", size: 10, style: :bold
        pdf.text folder_for(test_case), size: 8, color: "57606A"
        if test_case.preconditions.present?
          pdf.move_down 2
          pdf.text I18n.t("test_management.exports.columns.preconditions"), size: 8, style: :bold
          pdf.text test_case.preconditions.to_s, size: 8
        end
        steps = ordered_steps(test_case)
        if steps.any?
          pdf.move_down 3
          pdf_table(pdf,
                    ["#", I18n.t("test_management.exports.step_action"),
                     I18n.t("test_management.exports.step_data"), I18n.t("test_management.exports.step_expected")],
                    steps.each_with_index.map do |step, i|
                      [(i + 1).to_s, step.action.to_s, step.data.to_s, step.expected_result.to_s]
                    end,
                    widths: pdf_widths(pdf, [0.04, 0.4, 0.16, 0.4]))
        end
        pdf.stroke_color "D0D7DE"
        pdf.move_down 4
        pdf.stroke_horizontal_rule
      end

      def pdf_widths(pdf, ratios)
        ratios.map { |ratio| pdf.bounds.width * ratio }
      end

      def paths
        @paths ||= folder_paths(project)
      end

      def folder_for(test_case)
        test_case.suite_id ? paths[test_case.suite_id].to_s : unfiled_label
      end

      def folder_description
        if query.suite
          I18n.t("test_management.exports.scope_folder", folder: paths[query.suite.id])
        else
          unfiled_label
        end
      end

      def labels_for(test_case)
        test_case.labels.map(&:name).sort_by(&:downcase).join(LIST_SEPARATOR)
      end

      # Only work packages the exporting user may see.
      def work_packages_for(test_case)
        Array(visible_work_packages[test_case.id]).join(LIST_SEPARATOR)
      end

      def visible_work_packages
        @visible_work_packages ||= begin
          links = TestManagement::TestCaseWorkPackage
                    .where(test_case_id: test_cases.map(&:id))
                    .order(:work_package_id)
                    .pluck(:test_case_id, :work_package_id)
          subjects = ::WorkPackage.visible(current_user)
                                  .where(id: links.map(&:last).uniq)
                                  .pluck(:id, :subject)
                                  .to_h
          links.each_with_object({}) do |(case_id, wp_id), result|
            next unless subjects.key?(wp_id)

            (result[case_id] ||= []) << "##{wp_id} #{subjects[wp_id]}"
          end
        end
      end

      def ordered_steps(test_case)
        test_case.steps.sort_by { |step| [step.position.to_i, step.id.to_i] }
      end

      # "1. Action | Data: … | Expected: …", one step per line.
      def steps_for(test_case)
        ordered_steps(test_case).each_with_index.map do |step, index|
          parts = ["#{index + 1}. #{step.action}"]
          parts << "#{I18n.t('test_management.exports.step_data')}: #{step.data}" if step.data.present?
          parts << "#{I18n.t('test_management.exports.step_expected')}: #{step.expected_result}" if step.expected_result.present?
          parts.join(" | ")
        end.join("\n")
      end
    end
  end
end
