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

module CustomFieldsHelper
  def custom_fields_tabs
    [
      {
        name: 'WorkPackageCustomField',
        partial: 'custom_fields/tab',
        path: custom_fields_path(tab: :WorkPackageCustomField),
        label: :label_work_package_plural
      },
      {
        name: 'TimeEntryCustomField',
        partial: 'custom_fields/tab',
        path: custom_fields_path(tab: :TimeEntryCustomField),
        label: :label_spent_time
      },
      {
        name: 'ProjectCustomField',
        partial: 'custom_fields/tab',
        path: custom_fields_path(tab: :ProjectCustomField),
        label: :label_project_plural
      },
      {
        name: 'VersionCustomField',
        partial: 'custom_fields/tab',
        path: custom_fields_path(tab: :VersionCustomField),
        label: :label_version_plural
      },
      {
        name: 'UserCustomField',
        partial: 'custom_fields/tab',
        path: custom_fields_path(tab: :UserCustomField),
        label: :label_user_plural
      },
      {
        name: 'GroupCustomField',
        partial: 'custom_fields/tab',
        path: custom_fields_path(tab: :GroupCustomField),
        label: :label_group_plural
      }
    ]
  end

  # Return custom field html tag corresponding to its format
  def custom_field_tag(name, custom_value)
    custom_field = custom_value.custom_field
    field_name = "#{name}[custom_field_values][#{custom_field.id}]"
    field_id = "#{name}_custom_field_values_#{custom_field.id}"

    field_format = OpenProject::CustomFieldFormat.find_by_name(custom_field.field_format)

    tag = case field_format.try(:edit_as)
          when 'date'
            angular_component_tag 'op-basic-single-date-picker',
                                  inputs: {
                                    required: custom_field.is_required,
                                    value: custom_value.value,
                                    id: field_id,
                                    name: field_name
                                  }
          when 'text'
            styled_text_area_tag(field_name, custom_value.value, id: field_id, rows: 3, container_class: '-middle',
                                                                 required: custom_field.is_required)
          when 'bool'
            hidden_tag = hidden_field_tag(field_name, '0')
            checkbox_tag = styled_check_box_tag(field_name, '1', custom_value.typed_value, id: field_id,
                                                                                           required: custom_field.is_required)
            hidden_tag + checkbox_tag
          when 'list'
            blank_option = if custom_field.is_required? && custom_field.default_value.blank?
                             "<option value=\"\">--- #{I18n.t(:actionview_instancetag_blank_option)} ---</option>"
                           elsif custom_field.is_required? && custom_field.default_value.present?
                             ''
                           else
                             '<option></option>'
                           end

            options = blank_option.html_safe + options_for_select(custom_field.possible_values_options(custom_value.customized),
                                                                  custom_value.value)

            styled_select_tag(field_name, options, id: field_id, container_class: '-middle', required: custom_field.is_required)
          else
            styled_text_field_tag(field_name, custom_value.value, id: field_id, container_class: '-middle',
                                                                  required: custom_field.is_required)
          end

    tag = content_tag :span, tag, lang: custom_field.name_locale, class: 'form--field-container'

    if custom_value.errors.empty?
      tag
    else
      ActionView::Base.wrap_with_error_span(tag, custom_value, 'value')
    end
  end

  # Return custom field label tag
  def custom_field_label_tag(name, custom_value)
    content_tag 'label', h(custom_value.custom_field.name) +
                         (custom_value.custom_field.is_required? ? content_tag('span', ' *', class: 'required') : ''),
                for: "#{name}_custom_field_values_#{custom_value.custom_field.id}",
                class: "form--label #{custom_value.errors.empty? ? nil : 'error'}",
                lang: custom_value.custom_field.name_locale
  end

  def hidden_custom_field_label_tag(name, custom_value)
    content_tag 'label', h(custom_value.custom_field.name) +
                         (custom_value.custom_field.is_required? ? content_tag('span', ' *', class: 'required') : ''),
                for: "#{name}_custom_field_values_#{custom_value.custom_field.id}",
                class: "hidden-for-sighted",
                lang: custom_value.custom_field.name_locale
  end

  def blank_custom_field_label_tag(name, custom_field)
    content_tag 'label', h(custom_field.name) +
                         (custom_field.is_required? ? content_tag('span', ' *', class: 'required') : ''),
                for: "#{name}_custom_field_values_#{custom_field.id}",
                class: 'form--label'
  end

  # Return custom field tag with its label tag
  def custom_field_tag_with_label(name, custom_value)
    custom_field_label_tag(name, custom_value) + custom_field_tag(name, custom_value)
  end

  def custom_field_tag_for_bulk_edit(name, custom_field, project = nil)
    field_name = "#{name}[custom_field_values][#{custom_field.id}]"
    field_id = "#{name}_custom_field_values_#{custom_field.id}"
    field_format = OpenProject::CustomFieldFormat.find_by_name(custom_field.field_format)

    case field_format.try(:edit_as)
    when 'date'
      angular_component_tag 'op-modal-single-date-picker',
                            inputs: {
                              id: field_id,
                              name: field_name
                            }
    when 'text'
      styled_text_area_tag(field_name, '', id: field_id, rows: 3, with_text_formatting: true)
    when 'bool'
      styled_select_tag(field_name, options_for_select([[I18n.t(:label_no_change_option), ''],
                                                        ([I18n.t(:label_none), 'none'] unless custom_field.required?),
                                                        [I18n.t(:general_text_yes), '1'],
                                                        [I18n.t(:general_text_no), '0']].compact), id: field_id)
    when 'list'
      base_options = [[I18n.t(:label_no_change_option), '']]
      unless custom_field.required?
        unset_label = custom_field.field_format == 'user' ? :label_nobody : :label_none
        base_options << [I18n.t(unset_label), 'none']
      end
      styled_select_tag(field_name,
                        options_for_select(base_options + custom_field.possible_values_options(project)),
                        id: field_id,
                        multiple: custom_field.multi_value?)
    else
      styled_text_field_tag(field_name, '', id: field_id)
    end
  end

  # Return a string used to display a custom value
  def show_value(custom_value)
    return '' unless custom_value

    custom_value.formatted_value
  end

  # Return a string used to display a custom value
  def format_value(value, custom_field)
    custom_value = CustomValue.new(custom_field:,
                                   value:)

    custom_value.formatted_value
  end

  # Return an array of custom field formats which can be used in select_tag
  def custom_field_formats_for_select(custom_field)
    OpenProject::CustomFieldFormat
      .all_for_field(custom_field)
      .sort_by(&:order)
      .reject { |format| format.label.nil? }
      .map do |custom_field_format|
        [label_for_custom_field_format(custom_field_format.name), custom_field_format.name]
      end
  end

  def label_for_custom_field_format(format_string)
    format = OpenProject::CustomFieldFormat.find_by_name(format_string)

    if format
      format.label.is_a?(Proc) ? format.label.call : I18n.t(format.label)
    end
  end
end
