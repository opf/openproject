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

  # rubocop:disable Metrics/AbcSize
  def custom_field_input(options = {})
    field = custom_field.attribute_name

    input_options = options.merge(no_label: true,
                                  name: custom_field_field_name,
                                  id: custom_field_field_id)

    field_format = OpenProject::CustomFieldFormat.find_by(name: custom_field.field_format)

    case field_format.try(:edit_as)
    when "date"
      date_picker(field, input_options)
    when "text"
      text_area(field, input_options.merge(with_text_formatting: true, macros: false, editor_type: "constrained"))
    when "bool"
      check_box(field, input_options.merge(checked: custom_value.strategy.checked?))
    when "list"
      custom_field_input_list(field, input_options)
    when "hierarchy"
      custom_field_input_hierarchy(field, input_options)
    else
      text_field(field, input_options)
    end
  end

  def custom_field_input_hierarchy(field, input_options)
    root = custom_field.hierarchy_root
    all_items = CustomFields::Hierarchy::HierarchicalItemService.new
      .get_descendants(item: root, include_self: false)
      .either(->(result) { result }, ->(_) { [] })

    by_parent  = all_items.group_by(&:parent_id)
    top_level  = by_parent[root&.id] || []

    grouped = top_level.map do |top_item|
      [hierarchy_item_label(top_item), hierarchy_collect_options(by_parent, top_item, depth: 0)]
    end

    selected = Array(custom_value).map(&:value)
    input_options[:multiple] = custom_field.multi_value?

    select(field,
           template.grouped_options_for_select(grouped, selected),
           custom_field_select_options_for_object,
           input_options)
  end

  def hierarchy_collect_options(by_parent, item, depth:)
    indent = "  " * depth
    children = by_parent[item.id] || []

    [[hierarchy_item_label(item, indent:), item.id.to_s]] +
      children.flat_map { |child| hierarchy_collect_options(by_parent, child, depth: depth + 1) }
  end

  def hierarchy_item_label(item, indent: "")
    base = item.short.present? ? "#{item.label} (#{item.short})" : item.label
    "#{indent}#{base}"
  end

  def custom_field_input_list(field, input_options)
    customized = Array(custom_value).first&.customized
    selectable_options = custom_field_input_list_options(customized, custom_value)
    input_options[:multiple] = custom_field.multi_value?

    select(field, selectable_options, custom_field_select_options_for_object, input_options)
  end

  def custom_field_input_list_options(customized, selected)
    options = custom_field.possible_values_options(customized)
    selected_options = Array(selected).map(&:value)

    if custom_field.version?
      grouped_options = Hash.new { |hsh, key| hsh[key] = [] }
      options.each do |label, value, group_key|
        grouped_options[group_key] << [label, value]
      end
      template.grouped_options_for_select(grouped_options, selected_options)
    else
      template.options_for_select(options, selected_options)
    end
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
    classes += " error" unless Array(custom_value).flat_map(&:errors).empty?

    content_tag "label",
                for: custom_field_field_id,
                class: classes,
                title: custom_field.name do
      capture do
        concat custom_field.name

        # Render a help text icon
        if options[:help_text]
          concat content_tag("attribute-help-text", "", data: options[:help_text])
        end
      end
    end
  end
end
