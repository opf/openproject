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

require "action_view/helpers/form_helper"

class CustomFieldFormBuilder < TabularFormBuilder
  include ActionView::Context

  attr_reader :custom_value,
              :custom_field

  def initialize(object_name, object, template, options)
    super

    @custom_value = options.fetch(:custom_value)
    @custom_field = options.fetch(:custom_field)
  end

  # Return custom field html tag corresponding to its format
  def cf_form_field(options = {})
    input = custom_field_input(options)

    if options[:no_label]
      input
    else
      label = custom_field_label_tag(options)
      container_options = options.merge(no_label: true)

      label + container_wrap_field(input, "field", container_options)
    end
  end

  private

  def custom_field_input(options = {})
    field = custom_field.attribute_name

    input_options = options.merge(no_label: true,
                                  name: custom_field_field_name,
                                  id: custom_field_field_id)

    field_format = OpenProject::CustomFieldFormat.find_by_name(custom_field.field_format)

    case field_format.try(:edit_as)
    when "date"
      date_picker(field, input_options)
    when "text"
      text_area(field, input_options.merge(with_text_formatting: true, macros: false, editor_type: "constrained"))
    when "bool"
      check_box(field, input_options.merge(checked: custom_value.strategy.checked?))
    when "list"
      custom_field_input_list(field, input_options)
    else
      text_field(field, input_options)
    end
  end

  def custom_field_input_list(field, input_options)
    customized = Array(custom_value).first&.customized
    possible_options = custom_field.possible_values_options(customized)
    select_options = custom_field_select_options_for_object
    selected_options = Array(custom_value).map(&:value)
    selectable_options = template.options_for_select(possible_options, selected_options)
    input_options[:multiple] = custom_field.multi_value?

    select(field, selectable_options, select_options, input_options).html_safe
  end

  def custom_field_select_options_for_object
    is_required = custom_field.is_required?
    default_value = custom_field.default_value

    select_options = { no_label: true }

    if is_required && default_value.blank?
      select_options[:prompt] = "--- #{I18n.t(:actionview_instancetag_blank_option)} ---"
    elsif !is_required && !custom_field.multi_value?
      select_options[:include_blank] = true
    end

    select_options
  end

  def custom_field_field_name
    if custom_field.multi_value?
      "#{object_name}[#{custom_field.id}][]"
    else
      "#{object_name}[#{custom_field.id}]"
    end
  end

  def custom_field_field_id
    "#{object_name}#{custom_field.id}".gsub(/[\[\]]+/, "_")
  end

  # Return custom field label tag
  def custom_field_label_tag(options)
    classes = "form--label"
    classes << " error" unless Array(custom_value).flat_map(&:errors).empty?

    content_tag "label",
                for: custom_field_field_id,
                class: classes,
                title: custom_field.name do
      output = "".html_safe
      output += custom_field.name

      # Render a help text icon
      if options[:help_text]
        output += content_tag("attribute-help-text", "", data: options[:help_text])
      end

      output
    end
  end
end
