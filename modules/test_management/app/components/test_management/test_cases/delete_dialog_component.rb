# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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

      def confirmation_checkbox_text = I18n.t("#{i18n_scope}.confirm")

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
