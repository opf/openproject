#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'action_view/helpers/form_helper'

class CustomFieldFormBuilder < TabularFormBuilder
  include ActionView::Context

  # Return custom field html tag corresponding to its format
  def custom_field(options = {})
    input = custom_field_input(options)

    if options[:no_label]
      input
    else
      label = custom_field_label_tag
      container_options = options.merge(no_label: true)

      label + container_wrap_field(input, 'field', container_options)
    end
  end

  private

  def possible_options_for_object
    object
      .custom_field
      .possible_values_options(object.customized)
  end

  def custom_field_input(options = {})
    field = :value

    input_options = options.merge(no_label: true,
                                  name: custom_field_field_name,
                                  id: custom_field_field_id)

    field_format = OpenProject::CustomFieldFormat.find_by_name(object.custom_field.field_format)

    case field_format.try(:edit_as)
    when 'date'
      input_options[:class] = (input_options[:class] || '') << ' -augmented-datepicker'
      text_field(field, input_options)
    when 'text'
      text_area(field, input_options.merge(with_text_formatting: true, macros: false, editor_type: 'constrained'))
    when 'bool'
      formatter = field_format.formatter.new(object)
      check_box(field, input_options.merge(checked: formatter.checked?))
    when 'list'
      custom_field_input_list(field, input_options)
    else
      text_field(field, input_options)
    end
  end

  def custom_field_input_list(field, input_options)
    possible_options = possible_options_for_object
    select_options = custom_field_select_options_for_object
    selectable_options = template.options_for_select(possible_options, object.value)

    select(field, selectable_options, select_options, input_options).html_safe
  end

  def custom_field_select_options_for_object
    is_required = object.custom_field.is_required?
    default_value = object.custom_field.default_value

    select_options = { no_label: true }

    if is_required && default_value.blank?
      select_options[:prompt] = "--- #{I18n.t(:actionview_instancetag_blank_option)} ---"
    elsif !is_required
      select_options[:include_blank] = true
    end

    select_options
  end

  def custom_field_field_name
    "#{object_name}[#{object.custom_field.id}]"
  end

  def custom_field_field_id
    "#{object_name}#{object.custom_field.id}".gsub(/[\[\]]+/, '_')
  end

  # Return custom field label tag
  def custom_field_label_tag
    custom_value = object

    classes = 'form--label'
    classes << ' error' unless custom_value.errors.empty?

    content_tag 'label',
                for: custom_field_field_id,
                class: classes,
                title: custom_value.custom_field.name do
      custom_value.custom_field.name
    end
  end
end
