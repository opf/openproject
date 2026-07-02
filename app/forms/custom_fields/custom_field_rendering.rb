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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomFields::CustomFieldRendering
  include ActiveSupport::Concern

  SINGLE_VALUE_INPUT_CLASS_NAMES = OpenProject::MultiKeyHash.expand(
    %w[string link] => "CustomFields::Inputs::String",
    "text" => "CustomFields::Inputs::Text",
    "int" => "CustomFields::Inputs::Int",
    "float" => "CustomFields::Inputs::Float",
    %w[hierarchy weighted_item_list list] => "CustomFields::Inputs::SingleSelectList",
    "date" => "CustomFields::Inputs::Date",
    "bool" => "CustomFields::Inputs::Bool",
    "user" => "CustomFields::Inputs::SingleUserSelectList",
    "version" => "CustomFields::Inputs::SingleVersionSelectList",
    "calculated_value" => "CustomFields::Inputs::CalculatedValue"
  ).freeze

  MULTI_VALUE_INPUT_CLASS_NAMES = OpenProject::MultiKeyHash.expand(
    %w[hierarchy weighted_item_list list] => "CustomFields::Inputs::MultiSelectList",
    "user" => "CustomFields::Inputs::MultiUserSelectList",
    "version" => "CustomFields::Inputs::MultiVersionSelectList"
  ).freeze

  def render_custom_fields(form:)
    custom_fields.each do |custom_field|
      render_custom_field(form:, custom_field:)
    end
  end

  def render_custom_field(form:, custom_field:)
    form.fields_for(:custom_field_values) do |builder|
      custom_field_input(builder, custom_field)
    end
    if custom_field.has_comment?
      form.fields_for(:custom_comments) do |builder|
        custom_comment_input(builder, custom_field)
      end
    end
  end

  # override if you want to pass more attributes
  def additional_custom_field_input_arguments
    {}
  end

  def custom_fields
    raise SubclassResponsibilityError, "#custom_fields needs to be overwritten and provide all custom fields we want to show"
  end

  private

  def custom_field_input(builder, custom_field)
    if custom_field.multi_value?
      multi_value_custom_field_input(builder, custom_field)
    else
      single_value_custom_field_input(builder, custom_field)
    end
  end

  def custom_comment_input(builder, custom_field)
    CustomFields::CommentField.new(
      builder,
      custom_field:,
      object: model,
      complete_label: custom_fields.length > 1
    )
  end

  def form_arguments(custom_field)
    {
      custom_field:,
      object: model
    }.merge(additional_custom_field_input_arguments)
  end

  # TBD: transform inputs called below to primer form dsl instead of form classes?
  # TODOS:
  # - initial values for user inputs are not displayed
  # - allow/disallow-non-open version setting is not yet respected in the version selector
  # - rich text editor is not yet supported
  # - hierarchy should not use a flat list

  def single_value_custom_field_input(builder, custom_field)
    input_class_name = SINGLE_VALUE_INPUT_CLASS_NAMES[custom_field.field_format]

    if input_class_name
      input_class_name.constantize.new(builder, **form_arguments(custom_field))
    else
      raise "Unhandled custom field format #{custom_field.field_format}"
    end
  end

  def multi_value_custom_field_input(builder, custom_field)
    input_class_name = MULTI_VALUE_INPUT_CLASS_NAMES[custom_field.field_format]

    if input_class_name
      input_class_name.constantize.new(builder, **form_arguments(custom_field))
    else
      raise "Unhandled custom field format #{custom_field.field_format}"
    end
  end
end
