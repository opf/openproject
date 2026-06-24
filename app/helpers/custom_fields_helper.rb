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

module CustomFieldsHelper
  def custom_fields_tabs
    [
      {
        name: "WorkPackageCustomField",
        partial: "custom_fields/tab",
        path: custom_fields_path(tab: :WorkPackageCustomField),
        label: :label_work_package_plural
      },
      {
        name: "TimeEntryCustomField",
        partial: "custom_fields/tab",
        path: custom_fields_path(tab: :TimeEntryCustomField),
        label: :label_spent_time
      },
      {
        name: "VersionCustomField",
        partial: "custom_fields/tab",
        path: custom_fields_path(tab: :VersionCustomField),
        label: :label_version_plural
      },
      {
        name: "GroupCustomField",
        partial: "custom_fields/tab",
        path: custom_fields_path(tab: :GroupCustomField),
        label: :label_group_plural
      }
    ]
  end

  def blank_custom_field_label_tag(name, custom_field)
    content_tag "label", h(custom_field.name) +
                         (custom_field.is_required? ? content_tag("span", " *", class: "required") : ""),
                for: "#{name}_custom_field_values_#{custom_field.id}",
                class: "form--label"
  end

  def custom_field_tag_for_bulk_edit(name, custom_field, project = nil) # rubocop:disable Metrics/AbcSize
    field_name = name.present? ? "#{name}[custom_field_values][#{custom_field.id}]" : "custom_field_values[#{custom_field.id}]"
    field_id = "#{name}_custom_field_values_#{custom_field.id}"
    field_format = OpenProject::CustomFieldFormat.find_by(name: custom_field.field_format)

    case field_format.try(:edit_as)
    when "date"
      angular_component_tag "opce-basic-single-date-picker",
                            inputs: {
                              required: custom_field.required?,
                              id: field_id,
                              name: field_name
                            }
    when "text"
      styled_text_area_tag(field_name, "", id: field_id, rows: 3, with_text_formatting: true)
    when "bool"
      styled_select_tag(field_name,
                        options_for_select([([I18n.t(:label_none), "none"] unless custom_field.required?),
                                            [I18n.t(:general_text_yes), "1"],
                                            [I18n.t(:general_text_no), "0"]].compact),
                        id: field_id,
                        include_blank: I18n.t(:label_no_change_option))
    when "list"
      styled_select_tag(field_name,
                        options_for_list(custom_field, project),
                        id: field_id,
                        multiple: custom_field.multi_value?,
                        include_blank: I18n.t(:label_no_change_option))
    when "hierarchy", "weighted_item_list"
      base_options = []
      result = CustomFields::Hierarchy::HierarchicalItemService.new
        .get_descendants(item: custom_field.hierarchy_root, include_self: false)
        .either(
          ->(items) { items },
          ->(_) { [] }
        )
      options = base_options + result.map do |item|
        label = item.short.present? ? "#{item.label} (#{item.short})" : item.label
        [label, item.id]
      end
      styled_select_tag(field_name,
                        options_for_select(options),
                        id: field_id,
                        multiple: custom_field.multi_value?,
                        include_blank: I18n.t(:label_no_change_option))
    else
      styled_text_field_tag(field_name, "", id: field_id)
    end
  end

  # Return a string used to display a custom value
  def show_value(custom_value)
    return "" unless custom_value

    custom_value.formatted_value
  end

  # Return a string used to display a custom value
  def format_value(value, custom_field)
    CustomValue.new(custom_field:, value:).formatted_value
  end

  def label_for_custom_field_format(format_string)
    format = OpenProject::CustomFieldFormat.find_by(name: format_string)
    return "" if format.nil?

    format.label.is_a?(Proc) ? format.label.call : I18n.t(format.label)
  end

  def options_for_list(custom_field, project)
    base_options = []
    unless custom_field.required?
      unset_label = custom_field.field_format == "user" ? :label_nobody : :label_none
      base_options << [I18n.t(unset_label), "none"]
    end

    possible_values = custom_field.possible_values_options(project)
    options = if custom_field.version?
                grouped_options_for_select(possible_values.group_by(&:last).to_a)
              else
                options_for_select(possible_values)
              end

    options_for_select(base_options) + options
  end
end
