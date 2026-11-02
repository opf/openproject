# frozen_string_literal: true

module TestManagement
  module TestCases
    class BulkDeleteDialogComponent < ApplicationComponent
      include OpTurbo::Streamable

      DIALOG_ID = "tm-test-cases-bulk-delete-dialog"
      LIST_LIMIT = DeleteDialogComponent::LIST_LIMIT

      attr_reader :test_cases, :project

      def initialize(test_cases:, project:)
        super
        @test_cases = Array(test_cases)
        @project = project
      end

      private

      def id = DIALOG_ID

      def i18n_scope = "test_management.cases.bulk_delete_dialog"

      def title = I18n.t("#{i18n_scope}.title", count: test_cases.size)

      def heading = I18n.t("#{i18n_scope}.heading", count: test_cases.size)

      def description = I18n.t("#{i18n_scope}.description", count: test_cases.size)

      def confirmation_checkbox_text = I18n.t("#{i18n_scope}.confirm_deletion")

      def confirm_button_text = I18n.t("#{i18n_scope}.confirm_button")

      def list_cases? = test_cases.size <= LIST_LIMIT

      def form_arguments
        {
          action: helpers.project_test_management_test_cases_bulk_path(project),
          method: :delete
        }
      end

      def test_case_label(record)
        "#{record.formatted_id} #{record.title}"
      end
    end
  end
end
