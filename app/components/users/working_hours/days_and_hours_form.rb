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

class Users::WorkingHours::DaysAndHoursForm < ApplicationForm
  def initialize(is_first_form:)
    super()
    @is_first_form = is_first_form
  end

  form do |form|
    form.html_content do
      render(Primer::Beta::Subhead.new(spacious: !@is_first_form)) do |component|
        component.with_heading(tag: :div, size: :medium) do
          I18n.t("users.working_hours.form.title_days_and_hours")
        end
      end
    end

    if model.errors[:days].present?
      form.html_content do
        render(Primer::Alpha::Banner.new(mb: 3, icon: :stop, scheme: :danger)) { model.errors[:days].join("\n") }
      end
    end

    form.group(layout: :horizontal, mb: 2) do |group|
      ordered_days.each do |day|
        group.hidden name: "#{day}_hours", value: 0
        group.check_box name: "day_enabled_#{day}",
                        data: {
                          "users--working-hours-form-target": "dayCheckbox",
                          day: day,
                          action: "users--working-hours-form#dayToggled"
                        },
                        checked: day_enabled?(day),
                        label: full_day_name(day),
                        label_arguments: { mr: 3 }
      end
    end

    form.radio_button_group(name: "hours_mode", label: I18n.t("users.working_hours.form.hours_mode_label"),
                            mb: 2) do |group|
      group.radio_button(
        label: I18n.t("users.working_hours.form.same_hours_mode"),
        value: "same",
        checked: all_same_hours?,
        data: { action: "users--working-hours-form#hoursModeChanged" }
      )
      group.radio_button(
        label: I18n.t("users.working_hours.form.individual_hours_mode"),
        value: "individual",
        checked: !all_same_hours?,
        data: { action: "users--working-hours-form#hoursModeChanged" }
      )
    end

    copy_day_errors_to_shared_hours

    form.group(data: { "users--working-hours-form-target": "sameHoursSection" }) do |group|
      group.text_field name: :shared_hours,
                       label: UserWorkingHours.human_attribute_name(:shared_hours),
                       input_width: :large,
                       value: shared_hours,
                       data: {
                         "users--working-hours-form-target": "sharedHoursInput",
                         action: "input->users--working-hours-form#hoursChanged blur->users--working-hours-form#hoursFormatted"
                       },
                       trailing_visual: { text: { text: I18n.t("users.working_hours.form.per_day") } }
    end

    form.group(data: { "users--working-hours-form-target": "individualSection" }) do |group|
      ordered_days.each do |day|
        group.text_field name: "#{day}_hours",
                         label: UserWorkingHours.human_attribute_name("#{day}_hours"),
                         value: day_hours(day),
                         input_width: :large,
                         data: {
                           "users--working-hours-form-target": "dayHoursInput",
                           day: day,
                           action: "input->users--working-hours-form#hoursChanged blur->users--working-hours-form#hoursFormatted"
                         },
                         disabled: !day_enabled?(day)
      end
    end

    form.text_field name: :total_work_hours,
                    label: I18n.t("users.working_hours.form.total_work_hours"),
                    input_width: :large,
                    readonly: true,
                    data: { "users--working-hours-form-target": "totalWorkHoursDisplay" },
                    trailing_visual: { text: { text: I18n.t("users.working_hours.form.per_week") } }
  end

  private

  def ordered_days
    # DAYS = [monday(0), tuesday(1), ..., saturday(5), sunday(6)]
    # Setting.start_of_week: 1=Monday, 6=Saturday, 7=Sunday, nil=locale default (treat as Monday)
    start_index = case Setting.start_of_week
                  when 6 then UserWorkingHours::DAYS.index(:saturday)
                  when 7 then UserWorkingHours::DAYS.index(:sunday)
                  else 0 # Monday
                  end
    UserWorkingHours::DAYS.rotate(start_index)
  end

  def day_enabled?(day)
    model.public_send(day).to_i > 0
  end

  def day_hours(day)
    "#{model.public_send("#{day}_hours").round(2)}h"
  end

  def all_same_hours?
    enabled = UserWorkingHours::DAYS.select { |d| day_enabled?(d) }
    return true if enabled.empty?

    enabled.map { |d| day_hours(d) }.uniq.one?
  end

  def shared_hours
    first_enabled = UserWorkingHours::DAYS.find { |d| day_enabled?(d) }
    first_enabled ? day_hours(first_enabled) : "#{Setting.hours_per_day.round(2)}h"
  end

  def copy_day_errors_to_shared_hours
    UserWorkingHours::DAYS
      .flat_map { |day| model.errors[:"#{day}_hours"] }
      .uniq
      .each { |message| model.errors.add(:shared_hours, message) }
  end

  def full_day_name(day)
    I18n.t("date.day_names")[UserWorkingHours::DAY_ABBR_INDEX[day]]
  end
end
