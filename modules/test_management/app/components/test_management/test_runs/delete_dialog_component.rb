# frozen_string_literal: true

module TestManagement
  module TestRuns
    class DeleteDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "tm-test-run-delete-dialog"

      attr_reader :test_run, :project

      def initialize(test_run:, project:)
        super
        @test_run = test_run
        @project = project
      end

      private

      def id = DIALOG_ID

      def i18n_scope = "test_management.runs.delete_dialog"

      def title = I18n.t("#{i18n_scope}.title")

      def heading = I18n.t("#{i18n_scope}.heading")

      def description
        I18n.t("#{i18n_scope}.description", name: run_label)
      end

      def confirmation_checkbox_text = I18n.t("#{i18n_scope}.confirm")

      def confirm_button_text = I18n.t("#{i18n_scope}.confirm_button")

      def form_arguments
        {
          action: helpers.project_test_management_test_run_path(project, test_run),
          method: :delete
        }
      end

      def run_label
        "#{test_run.formatted_id} #{test_run.name}"
      end
    end
  end
end
