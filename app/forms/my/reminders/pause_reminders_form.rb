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

class My::Reminders::PauseRemindersForm < ApplicationForm
  PauseRemindersFormModel = Data.define(:enabled, :first_day, :last_day)

  form do |f|
    f.fieldset_group(title: helpers.t("my_account.email_reminders.pause_reminders.title"), mt: 3) do |fg|
      fg.check_box(
        name: :enabled,
        id: "pause-reminders-enabled",
        label: helpers.t("my_account.email_reminders.pause_reminders.enabled"),
        data: {
          target_name: "pause-enabled",
          show_when_checked_target: "cause"
        }
      ) do |cb|
        cb.nested_form(
          classes: [{ "d-none" => !model.enabled }],
          data: {
            target_name: "pause-enabled",
            show_when_checked_target: "effect",
            show_when: "checked"
          }
        ) do |builder|
          DateRangeForm.new(builder)
        end
      end

      fg.submit(name: :submit, label: helpers.t("button_save"), scheme: :default)
    end
  end

  class DateRangeForm < ApplicationForm
    form do |f|
      f.range_date_picker(
        name: :date_range,
        visually_hide_label: true,
        input_width: :small,
        label: helpers.t("my_account.email_reminders.pause_reminders.date_range"),
        value: [model.first_day, model.last_day].compact_blank.join(" - ")
      )
    end
  end
end
