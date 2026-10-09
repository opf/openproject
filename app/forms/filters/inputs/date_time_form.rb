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

class Filters::Inputs::DateTimeForm < Filters::Inputs::BaseDateForm
  VALUE_FIELDS = {
    ">t-" => "intDays",
    "<t-" => "intDays",
    "t-" => "intDays",
    "<t+" => "intDays",
    ">t+" => "intDays",
    "t+" => "intDays",
    "=d" => "singleDay",
    ">d" => "singleDatetime",
    "<d" => "singleDatetime",
    "<>d" => "datetimeRange"
  }.freeze

  private

  def add_fields(builder, filter_name)
    days_div(builder, filter_name, field_value("intDays"))
    on_date_div(builder, filter_name, local_date(field_value("singleDay")))
    datetime_div(builder, filter_name, "singleDatetime", field_value("singleDatetime"))
    datetime_range_div(builder, filter_name)
  end

  # "On" stores the start of the day as a UTC timestamp, while the date picker shows the user's local date.
  def local_date(value)
    return value unless value&.include?("T")

    Time.iso8601(value).in_time_zone(User.current.time_zone).to_date.iso8601
  rescue ArgumentError
    value
  end

  def datetime_range_div(builder, filter_name)
    active = active_field == "datetimeRange"

    # primer-multi-input hides the parent of every inactive field, so the range needs a wrapper of its own.
    # Only that wrapper is hidden: Primer collapses a group whose inputs are all hidden with display: none,
    # which primer-multi-input cannot undo when activating it.
    builder.group(hidden: !active) do |wrapper|
      wrapper.group(layout: :horizontal,
                    data: { name: "datetimeRange", targets: "primer-multi-input.fields" }) do |range|
        datetime_div(range, filter_name, "datetimeFrom", field_value("datetimeRange", 0) || "")
        datetime_div(range, filter_name, "datetimeTo", field_value("datetimeRange", 1) || "")
      end
    end
  end

  def datetime_div(builder, filter_name, field, value)
    builder.single_datetime_picker(
      name: field.to_sym,
      label: field.to_sym,
      visually_hide_label: true,
      hidden: value.nil?,
      leading_visual: { icon: :calendar },
      value: value || "",
      datepicker_options: {
        id: "#{filter_name}_#{field}",
        inDialog: @dialog_id,
        input_attributes: { "data-filter--filters-form-target" => field, "data-filter-name" => filter_name }
      }.compact,
      data: { "filter-name": filter_name }
    )
  end
end
