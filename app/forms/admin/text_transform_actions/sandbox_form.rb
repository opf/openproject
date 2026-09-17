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

module Admin
  module TextTransformActions
    class SandboxForm < ApplicationForm
      MODE_TARGET_NAME = "sandbox_context_mode"
      MODES = %w[none work_package new_work_package].freeze
      WORK_PACKAGE_PANEL_ID = "ai-text-transform-sandbox-work-package"
      PROJECT_PANEL_ID = "ai-text-transform-sandbox-project"

      form do |f|
        f.text_area(
          name: :content,
          label: label(:content_label),
          caption: label(:content_caption),
          rows: 10,
          full_width: true,
          data: target(:content)
        )

        f.select_list(
          name: :context_mode,
          label: label(:context_label),
          caption: label(:context_caption),
          include_blank: false,
          data: target(:contextMode).merge(show_when_value_selected_target: "cause", target_name: MODE_TARGET_NAME)
        ) do |select|
          MODES.each { |mode| select.option(value: mode, label: label(:"context_#{mode}")) }
        end

        f.group(hidden: true, data: effect_for("work_package")) do |group|
          group.html_content { work_package_control }
        end

        f.group(hidden: true, data: effect_for("new_work_package")) do |group|
          group.html_content { project_control }

          group.select_list(
            name: :type_id,
            label: label(:type_label),
            caption: label(:type_caption),
            include_blank: true,
            data: target(:typeId)
          ) do |select|
            @types.each { |type| select.option(value: type.id, label: type.name) }
          end
        end
      end

      def initialize(types:)
        super()
        @types = types
      end

      private

      def work_package_control
        form_control(label(:work_package_label), label(:work_package_caption)) do |input_arguments|
          work_package_panel(input_arguments)
        end
      end

      def project_control
        form_control(label(:project_label), label(:new_work_package_caption)) do |input_arguments|
          project_panel(input_arguments)
        end
      end

      def form_control(label, caption, &)
        render(Primer::Alpha::FormControl.new(label:, caption:)) do |control|
          control.with_input(&)
        end
      end

      def work_package_panel(input_arguments)
        remote_panel(input_arguments,
                     id: WORK_PACKAGE_PANEL_ID,
                     name: :work_package_id,
                     src: url_helpers.sandbox_work_packages_admin_text_transform_actions_path,
                     title: label(:select_work_package))
      end

      def project_panel(input_arguments)
        remote_panel(input_arguments,
                     id: PROJECT_PANEL_ID,
                     name: :project_id,
                     src: url_helpers.sandbox_projects_admin_text_transform_actions_path,
                     title: label(:select_project))
      end

      def remote_panel(input_arguments, id:, name:, src:, title:)
        render(
          Primer::Alpha::SelectPanel.new(
            id:,
            select_variant: :single,
            fetch_strategy: :remote,
            src:,
            title:,
            dynamic_label: true,
            form_arguments: { builder: @builder, name: }
          )
        ) do |panel|
          panel.with_show_button(scheme: :secondary, aria: { describedby: input_arguments.dig(:aria, :describedby) }) do |button|
            button.with_trailing_action_icon(icon: :"triangle-down")
            title
          end
        end
      end

      def label(key)
        I18n.t("admin.text_transform_actions.sandbox.#{key}")
      end

      def target(name)
        { ai_text_transform_sandbox_target: name }
      end

      def effect_for(mode)
        { show_when_value_selected_target: "effect", target_name: MODE_TARGET_NAME, value: mode }
      end
    end
  end
end
