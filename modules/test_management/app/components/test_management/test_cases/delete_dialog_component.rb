# frozen_string_literal: true

module TestManagement
  module TestCases
    class DeleteDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "tm-test-case-delete-dialog"
      LIST_LIMIT = 10

      attr_reader :test_case, :project

      def initialize(test_case:, project:)
        super
        @test_case = test_case
        @project = project
      end

      private

      def id = DIALOG_ID

      def i18n_scope = "test_management.cases.delete_dialog"

      def title = I18n.t("#{i18n_scope}.title")

      def heading = I18n.t("#{i18n_scope}.heading")

      def description
        I18n.t("#{i18n_scope}.description", name: test_case_label(test_case))
      end

      def confirmation_checkbox_text = I18n.t("#{i18n_scope}.confirm_deletion")

      def confirm_button_text = I18n.t("#{i18n_scope}.confirm_button")

      def form_arguments
        {
          action: helpers.project_test_management_test_case_path(project, test_case),
          method: :delete
        }
      end

      def test_case_label(record)
        "#{record.formatted_id} #{record.title}"
      end
    end
  end
end
