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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Workflows
  module Wizard
    class ChoiceComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(variant:, back_url: nil)
        super(variant)

        @back_url = back_url
      end

      private

      attr_reader :back_url

      def variant = model

      def group_data
        { controller: "mode-switch-radio", action: "change->mode-switch-radio#select" }
      end

      def existing_option
        {
          value: "existing",
          checked: reuses_existing?,
          label: t("workflows.wizard.choice.existing.label"),
          caption: t("workflows.wizard.choice.existing.caption"),
          nested_content: workflow_panel,
          data: {
            "mode-switch-radio-target": "radio",
            "dialog-url": change_dialog_path,
            test_selector: "workflow-choice-existing"
          }
        }
      end

      def new_workflow_option
        {
          value: "new",
          checked: !reuses_existing?,
          label: t("workflows.wizard.choice.new.label"),
          caption: t("workflows.wizard.choice.new.caption"),
          data: {
            "mode-switch-radio-target": "radio",
            "dialog-url": start_dialog_path,
            test_selector: "workflow-choice-new"
          }
        }
      end

      def workflow_panel
        return unless reuses_existing?
        return if candidates.empty?

        Workflows::WorkflowPanelComponent.new(variant:,
                                              candidates:,
                                              name: variant.workflow.name,
                                              selected: variant.workflow_id,
                                              back_url:)
      end

      def reuses_existing? = !variant.workflow.used_by_one_variant?

      def candidates
        @candidates ||= begin
          scope = Workflow.available_in(variant.project).in_display_order
          scope = scope.where.not(id: variant.workflow_id) unless reuses_existing?
          scope.to_a
        end
      end

      def change_dialog_path = url_helpers.change_dialog_type_workflow_path(**dialog_args)

      def start_dialog_path = url_helpers.start_dialog_type_workflow_path(**dialog_args)

      def dialog_args = variant.path_args.merge(back_url:).compact
    end
  end
end
