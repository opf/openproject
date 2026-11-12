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

module Projects
  module Settings
    class SubitemsTemplateForm < ApplicationForm
      attr_reader :project, :assignments

      def initialize(project:)
        super()

        @project = project
        @assignments = @project.subproject_template_assignments
      end

      form do |f|
        if project.portfolio?
          program_template = assignments.detect(&:program?)

          f.select_list(
            name: :program_template,
            scope_name_to_model: false,
            label: I18n.t("projects.settings.subitems.program_template_label"),
            caption: I18n.t("projects.settings.subitems.program_template_caption"),
            input_width: :large,
            include_blank: I18n.t("projects.settings.subitems.no_template")
          ) do |list|
            available_templates
              .workspace_type(:program)
              .find_each do |template|
              list.option(
                value: template.id,
                label: template.name,
                selected: template.id == program_template&.template_id
              )
            end
          end
        end

        project_template = assignments.detect(&:project?)
        f.select_list(
          name: :project_template,
          scope_name_to_model: false,
          label: I18n.t("projects.settings.subitems.project_template_label"),
          caption: I18n.t("projects.settings.subitems.project_template_caption"),
          input_width: :large,
          include_blank: I18n.t("projects.settings.subitems.no_template")
        ) do |list|
          available_templates
            .workspace_type(:project)
            .find_each do |template|
            list.option(
              value: template.id,
              label: template.name,
              selected: template.id == project_template&.template_id
            )
          end
        end

        f.submit(
          name: :submit,
          label: I18n.t(:button_save),
          scheme: :primary
        )
      end

      private

      def available_templates
        Project
          .visible(User.current)
          .active
          .templated
          .order(name: :asc)
      end
    end
  end
end
