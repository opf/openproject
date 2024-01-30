#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
module Projects::CustomFields
  class Form < ApplicationForm
    form do |custom_fields_form|
      sorted_custom_fields.each do |custom_field|
        custom_fields_form.fields_for(:custom_field_values) do |builder|
          custom_field_input(builder, custom_field)
        end
      end
    end

    def initialize(project:, custom_field_section: nil)
      super()
      @project = project
      @custom_field_section = custom_field_section
    end

    private

    def sorted_custom_fields
      # TODO: move to service/model
      return @custom_fields if @custom_fields.present?

      @custom_fields ||= @project.available_custom_fields

      if @custom_field_section.present?
        @custom_fields = @custom_fields
          .where(custom_field_section_id: @custom_field_section.id)
      end

      @custom_fields = @custom_fields.sort_by do |pcf|
        [pcf.project_custom_field_section.position, pcf.position_in_custom_field_section]
      end
    end

    def custom_field_input(builder, custom_field)
      if custom_field.multi_value?
        custom_values = @project.custom_values_for_custom_field(id: custom_field.id)
        multi_value_custom_field_input(builder, custom_field, custom_values)
      else
        custom_value = @project.custom_value_for(custom_field.id)
        single_value_custom_field_input(builder, custom_field, custom_value)
      end
    end

    # TBD: transform inputs called below to primer form dsl instead of form classes?
    # TODOS:
    # - list inputs cannot be resetted currently (worked before refactoring though)
    # - initial values for user inputs are not displayed

    def single_value_custom_field_input(builder, custom_field, custom_value)
      form_args = { custom_field:, custom_value:, project: @project }

      case custom_field.field_format
      when "string"
        Projects::CustomFields::Inputs::String.new(builder, **form_args)
      when "text"
        Projects::CustomFields::Inputs::Text.new(builder, **form_args)
      when "int"
        Projects::CustomFields::Inputs::Int.new(builder, **form_args)
      when "float"
        Projects::CustomFields::Inputs::Float.new(builder, **form_args)
      when "list"
        Projects::CustomFields::Inputs::SingleSelectList.new(builder, **form_args)
      when "date"
        Projects::CustomFields::Inputs::Date.new(builder, **form_args)
      when "bool"
        Projects::CustomFields::Inputs::Bool.new(builder, **form_args)
      when "user"
        Projects::CustomFields::Inputs::SingleUserSelectList.new(builder, **form_args)
      when "version"
        Projects::CustomFields::Inputs::SingleVersionSelectList.new(builder, **form_args)
      end
    end

    def multi_value_custom_field_input(builder, custom_field, custom_values)
      form_args = { custom_field:, custom_values:, project: @project }

      case custom_field.field_format
      when "list"
        Projects::CustomFields::Inputs::MultiSelectList.new(builder, **form_args)
      when "user"
        Projects::CustomFields::Inputs::MultiUserSelectList.new(builder, **form_args)
      when "version"
        Projects::CustomFields::Inputs::MultiVersionSelectList.new(builder, **form_args)
      end
    end
  end
end
