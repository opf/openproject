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

class Filters::Inputs::BaseDateForm < Filters::Inputs::BaseFilterForm
  def add_operand(group)
    filter_name = @filter.name

    group.multi(name: filter_name, label: filter_name, visually_hide_label: true,
                class: ["advanced-filters--filter-value"],
                data: {
                  "filter--filters-form-target": "filterValueContainer",
                  "filter-name": filter_name,
                  "value-fields": self.class::VALUE_FIELDS.to_json
                }) do |builder|
      add_fields(builder, filter_name)
    end
  end

  private

  def active_field
    self.class::VALUE_FIELDS[@filter.operator || @filter.default_operator.symbol]
  end

  def field_value(field, index = 0)
    @filter.values.fetch(index, "") if active_field == field
  end

  def days_div(builder, filter_name, value)
    field_arguments = {
      name: :intDays,
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
        input_attributes: { "data-filter--filters-form-target" => "singleDay", "data-filter-name" => filter_name }
      }.compact,
      data: { "filter-name": filter_name }
    )
  end
end
