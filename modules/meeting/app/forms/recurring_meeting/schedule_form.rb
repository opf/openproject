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

class RecurringMeeting::ScheduleForm < ApplicationForm
  include OpenProject::StaticRouting::UrlHelpers

  form do |form|
    form.select_list(
      name: :recurrence,
      input_width: :medium,
      label: RecurringMeeting.human_attribute_name(:recurrence),
      required: true,
      autofocus: true
    ) do |list|
      list.option(label: "Daily", value: "daily")
      list.option(label: "Daily on workdays", value: "workdays")
      list.option(label: "Weekly", value: "weekly")
      list.option(label: "Monthly", value: "monthly")
    end

    form.check_box_group(label: "Days", layout: :horizontal, visually_hide_label: true) do |check_group|
      check_group.check_box(
        name: "monday",
        label: "Monday"
      )
      check_group.check_box(
        name: "tuesday",
        label: "Tuesday"
      )
      check_group.check_box(
        name: "wednesday",
        label: "Wednesaday"
      )
      check_group.check_box(
        name: "thursday",
        label: "Thursday"
      )
      check_group.check_box(
        name: "friday",
        label: "Friday"
      )
      check_group.check_box(
        name: "saturday",
        label: "Saturday"
      )
      check_group.check_box(
        name: "sunday",
        label: "Sunday"
      )
    end

    form.text_field(
      name: :interval,
      input_width: :medium,
      label: RecurringMeeting.human_attribute_name(:interval),
      type: :number,
      step: 1
    )

    form.select_list(
      name: :end,
      input_width: :medium,
      label: RecurringMeeting.human_attribute_name(:ends),
      required: true,
      autofocus: true
    ) do |list|
      list.option(label: "Never", value: "never")
      list.option(label: "After a number of occurrences", value: "after")
      list.option(label: "On a specific date", value: "date")
    end

    form.text_field(
      name: :count,
      input_width: :medium,
      label: RecurringMeeting.human_attribute_name(:count),
      type: :number,
      step: 1
    )

    # form.date_select(
    #   :start_date,
    #   label: RecurringMeeting.human_attribute_name(:start_date)
    # )

    # form.date_select(
    #   :end_date,
    #   label: RecurringMeeting.human_attribute_name(:end_date)
    # )
  end

  def initialize(meeting:)
    super()
    @meeting = meeting
  end
end
