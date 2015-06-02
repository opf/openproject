#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'action_view/helpers/form_helper'

class CustomFieldFormBuilder < TabularFormBuilder

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

  def custom_field_input(options = {})
    field = :value

    input_options = options.merge(no_label: true,
                                  name: custom_field_field_name,
                                  id: custom_field_field_id,
                                  lang: object.custom_field.name_locale)

    field_format = Redmine::CustomFieldFormat.find_by_name(object.custom_field.field_format)

    case field_format.try(:edit_as)
    when 'date'
      text_field(field, input_options) +
        template.calendar_for(custom_field_field_id)
    when 'text'
      text_area(field, input_options.merge(rows: 3))
    when 'bool'
      check_box(field, input_options)
    when 'list'
      custom_field_input_list(field, input_options)
    else
      text_field(field, input_options)
    end
  end

  def custom_field_input_list(field, input_options)
    select_options = { no_label: true }
    is_required = object.custom_field.is_required?
    default_value = object.custom_field.default_value
    possible_options = object.custom_field.possible_values_options(object.customized)

    if is_required && default_value.blank?
      select_options[:prompt] = "--- #{l(:actionview_instancetag_blank_option)} ---"
    elsif !is_required
      select_options[:include_blank] = true
    end

    selectable_options = template.options_for_select(possible_options, object.value)

    select(field, selectable_options, select_options, input_options).html_safe
  end

  def custom_field_field_name
    "#{object_name}[#{ object.custom_field.id }]"
  end

  def custom_field_field_id
    "#{object_name}#{ object.custom_field.id }".gsub(/[\[\]]+/, '_')
  end

  # Return custom field label tag
  def custom_field_label_tag
    custom_value = object

    classes = 'form--label'
    classes << ' error' unless custom_value.errors.empty?

    content_tag 'label',
                custom_value.custom_field.name,
                for: custom_field_field_id,
                class: classes,
                title: custom_value.custom_field.name,
                lang: custom_value.custom_field.name_locale
  end
end
