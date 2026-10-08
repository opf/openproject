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

class Filters::Inputs::DateForm < Filters::Inputs::BaseFilterForm
  DAYS_OPERATORS = %w[>t- <t- t- <t+ >t+ t+].freeze

  def add_operand(group)
    filter_name = @filter.name
    values = operand_values

    # The multi name intentionally uses @filter.name (not operand_name) because
    # parseDateFilterValue in filters-form.controller.ts locates the datepicker
    # inputs via findTargetById(filterName, …), which matches the id derived from
    # the multi name. Switching to operand_name would require migrating that
    # lookup to findTargetByName and adding data-filter-name to the picker inputs.
    group.multi(name: filter_name, label: filter_name, visually_hide_label: true,
                class: ["advanced-filters--filter-value"],
                data: {
                  "filter--filters-form-target": "filterValueContainer",
                  "filter-name": filter_name
                }) do |builder|
      days_div(builder, filter_name, values[:days])
      on_date_div(builder, filter_name, values[:on_date])
      between_dates_div(builder, filter_name, values[:from], values[:to])
    end
  end

  private

  def operand_values
    filter_values = @filter.values

    case date_format
    when "days"
      { days: filter_values.fetch(0, "") }
    when "on-date"
      { on_date: picker_date(filter_values.fetch(0, "")) }
    when "between-dates"
      { from: picker_date(filter_values.fetch(0, "")), to: picker_date(filter_values.fetch(1, "")) }
    else
      {}
    end
  end

  # Datetime filters store the day boundaries as UTC timestamps, while the pickers show the user's local date.
  def picker_date(value)
    return value unless @filter.type.in?(%i[datetime_past datetime]) && value.include?("T")

    Time.iso8601(value).in_time_zone(User.current.time_zone).to_date.iso8601
  rescue ArgumentError
    value
  end

  def date_format
    op = @filter.operator || @filter.default_operator.symbol
    @date_format ||= if DAYS_OPERATORS.include?(op)
                       "days"
                     elsif op == "=d"
                       "on-date"
                     elsif op == "<>d"
                       "between-dates"
                     end
  end

  def days_div(builder, filter_name, value)
    field_arguments = {
      name: :days,
      label: I18n.t("datetime.units.day.other"),
      visually_hide_label: true,
      trailing_visual: { text: { text: I18n.t("datetime.units.day.other") } },
      scope_name_to_model: false,
      value:,
      hidden: value.nil?,
      data: {
        "filter--filters-form-target": "days",
        "filter-name": filter_name
      }
    }

    builder.text_field(**field_arguments, type: :number, step: "any", class: "days")
  end

  def on_date_div(builder, filter_name, value)
    builder.single_date_picker(
      name: :singleDay,
      label: :singleDay,
      hidden: value.nil?,
      leading_visual: { icon: :calendar },
      value: value || "",
      datepicker_options: {
        inDialog: @dialog_id,
        input_attributes: { "data-filter--filters-form-target" => "singleDay" }
      }.compact,
      data: { "filter-name": filter_name }
    )
  end

  def between_dates_div(builder, filter_name, from_value, to_value)
    value = [from_value, to_value].compact.join(" - ").presence
    builder.range_date_picker(
      name: :dateRange,
      label: :dateRange,
      hidden: value.nil?,
      leading_visual: { icon: :calendar },
      value: value || "-",
      datepicker_options: {
        inDialog: @dialog_id,
        input_attributes: { "data-filter--filters-form-target" => "dateRange" }
      }.compact,
      data: { "filter-name": filter_name }
    )
  end
end
