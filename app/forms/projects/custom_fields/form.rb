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
module Projects::CustomFields
  class Form < ApplicationForm
    form do |custom_fields_form|
      custom_fields.each do |custom_field|
        custom_fields_form.fields_for(:custom_field_values) do |builder|
          custom_field_input(builder, custom_field)
        end
      end
    end

    def initialize(project:, custom_field_section: nil, custom_field: nil, wrapper_id: nil)
      super()
      @project = project
      @custom_field_section = custom_field_section
      @custom_field = custom_field
      @wrapper_id = wrapper_id

      if @custom_field_section.present? && @custom_field.present?
        raise ArgumentError,
              "Either custom_field_section or custom_field must be specified, but not both"
      end
    end

    private

    def custom_fields
      @custom_fields ||=
        if @custom_field.present?
          [@custom_field]
        elsif @custom_field_section.present?
          @project
            .available_custom_fields
            .where(custom_field_section_id: @custom_field_section.id)
        else
          @project.available_custom_fields
        end
    end

    def custom_field_input(builder, custom_field)
      if custom_field.multi_value?
        multi_value_custom_field_input(builder, custom_field)
      else
        single_value_custom_field_input(builder, custom_field)
      end
    end

    # TBD: transform inputs called below to primer form dsl instead of form classes?
    # TODOS:
    # - initial values for user inputs are not displayed
    # - allow/disallow-non-open version setting is not yet respected in the version selector
    # - rich text editor is not yet supported

    def single_value_custom_field_input(builder, custom_field)
      form_args = { custom_field:, object: @project, wrapper_id: @wrapper_id }

      case custom_field.field_format
      when "string", "link"
        CustomFields::Inputs::String.new(builder, **form_args)
      when "text"
        CustomFields::Inputs::Text.new(builder, **form_args)
      when "int"
        CustomFields::Inputs::Int.new(builder, **form_args)
      when "float"
        CustomFields::Inputs::Float.new(builder, **form_args)
      when "list"
        CustomFields::Inputs::SingleSelectList.new(builder, **form_args)
      when "date"
        CustomFields::Inputs::Date.new(builder, **form_args)
      when "bool"
        CustomFields::Inputs::Bool.new(builder, **form_args)
      when "user"
        CustomFields::Inputs::SingleUserSelectList.new(builder, **form_args)
      when "version"
        CustomFields::Inputs::SingleVersionSelectList.new(builder, **form_args)
      end
    end

    def multi_value_custom_field_input(builder, custom_field)
      form_args = { custom_field:, object: @project, wrapper_id: @wrapper_id }

      case custom_field.field_format
      when "list"
        CustomFields::Inputs::MultiSelectList.new(builder, **form_args)
      when "user"
        CustomFields::Inputs::MultiUserSelectList.new(builder, **form_args)
      when "version"
        CustomFields::Inputs::MultiVersionSelectList.new(builder, **form_args)
      end
    end
  end
end
