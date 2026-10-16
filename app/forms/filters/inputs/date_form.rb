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

class Filters::Inputs::DateForm < Filters::Inputs::BaseDateForm
  VALUE_FIELDS = {
    ">t-" => "intDays",
    "<t-" => "intDays",
    "t-" => "intDays",
    "<t+" => "intDays",
    ">t+" => "intDays",
    "t+" => "intDays",
    "=d" => "singleDay",
    ">d" => "singleDay",
    "<d" => "singleDay",
    "<>d" => "dateRange"
  }.freeze

  private

  def add_fields(builder, filter_name)
    days_div(builder, filter_name, field_value("intDays"))
    on_date_div(builder, filter_name, field_value("singleDay"))
    between_dates_div(builder, filter_name, date_range_value)
  end

  def date_range_value
    "#{field_value('dateRange', 0)} - #{field_value('dateRange', 1)}" if active_field == "dateRange"
  end

  def between_dates_div(builder, filter_name, value)
    builder.range_date_picker(
      name: :dateRange,
      label: :dateRange,
      hidden: value.nil?,
      leading_visual: { icon: :calendar },
      value: value || "-",
      datepicker_options: {
        inDialog: @dialog_id,
        input_attributes: { "data-filter--filters-form-target" => "dateRange", "data-filter-name" => filter_name }
      }.compact,
      data: { "filter-name": filter_name }
    )
  end
end
