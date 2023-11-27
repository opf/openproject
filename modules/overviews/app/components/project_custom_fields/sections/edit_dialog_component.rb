#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module ProjectCustomFields
  module Sections
    class EditDialogComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      def initialize(project:,
                     project_custom_field_section:,
                     active_project_custom_fields_of_section:,
                     project_custom_field_values:)
        super

        @project = project
        @project_custom_field_section = project_custom_field_section
        @active_project_custom_fields_of_section = active_project_custom_fields_of_section
        @project_custom_field_values = project_custom_field_values
      end

      private

      def project_custom_field_values_for(project_custom_field_id)
        values = @project_custom_field_values.select { |pcfv| pcfv.custom_field_id == project_custom_field_id }

        if values.empty?
          [CustomValue.new(
            custom_field_id: project_custom_field_id,
            customized_id: @project.id,
            customized_type: "Project"
          )]
        else
          values
        end
      end

      def render_custom_field_value_input(form, custom_field, custom_field_values)
        if custom_field.multi_value?
          render_multi_value_custom_field_input(form, custom_field, custom_field_values)
        else
          render_single_value_custom_field_input(form, custom_field, custom_field_values.first)
        end
      end

      def render_single_value_custom_field_input(form, custom_field, custom_field_value)
        case custom_field.field_format
        when "string"
          render(Project::CustomValueForm::String.new(form, custom_field:, custom_field_value:, project: @project))
        when "text"
          render(Project::CustomValueForm::Text.new(form, custom_field:, custom_field_value:, project: @project))
        when "int"
          render(Project::CustomValueForm::Int.new(form, custom_field:, custom_field_value:, project: @project))
        when "float"
          render(Project::CustomValueForm::Float.new(form, custom_field:, custom_field_value:, project: @project))
        when "list"
          render(Project::CustomValueForm::SingleSelectList.new(form, custom_field:, custom_field_value:, project: @project))
        when "date"
          render(Project::CustomValueForm::Date.new(form, custom_field:, custom_field_value:, project: @project))
        when "bool"
          render(Project::CustomValueForm::Bool.new(form, custom_field:, custom_field_value:, project: @project))
        when "user"
          render(Project::CustomValueForm::SingleUserSelectList.new(form, custom_field:, custom_field_value:, project: @project))
        when "version"
          render(Project::CustomValueForm::SingleVersionSelectList.new(form, custom_field:, custom_field_value:,
                                                                             project: @project))
        end
      end

      def render_multi_value_custom_field_input(form, custom_field, custom_field_values)
        case custom_field.field_format
        when "list"
          render(Project::CustomValueForm::MultiSelectList.new(form, custom_field:, custom_field_values:, project: @project))
        when "user"
          render(Project::CustomValueForm::MultiUserSelectList.new(form, custom_field:, custom_field_values:, project: @project))
        when "version"
          render(Project::CustomValueForm::MultiVersionSelectList.new(form, custom_field:, custom_field_values:,
                                                                            project: @project))
        end
      end
    end
  end
end
