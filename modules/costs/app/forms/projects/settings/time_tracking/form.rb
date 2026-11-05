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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Settings::TimeTracking
  class Form < ApplicationForm
    form do |f|
      if WorkPackage.status_based_mode?
        f.group do |group|
          logged_time_check_box(group, disabled: true)
          read_only_check_box(group, disabled: true)
        end
      else
        f.group(data: { controller: "disable-when-checked", "disable-when-checked-reversed-value": true }) do |group|
          logged_time_check_box(group, data: { "disable-when-checked-target": "cause" })
          read_only_check_box(group,
                              disabled: !model.logged_time_reduces_remaining_work?,
                              data: { "disable-when-checked-target": "effect" })
        end
      end

      f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary, disabled: WorkPackage.status_based_mode?)
    end

    private

    def logged_time_check_box(group, **)
      group.check_box(
        name: :logged_time_reduces_remaining_work,
        label: I18n.t("cost_types.settings.time_tracking.logged_time_reduces_remaining_work"),
        caption: I18n.t("cost_types.settings.time_tracking.logged_time_reduces_remaining_work_caption"),
        checked: model.logged_time_reduces_remaining_work?,
        **
      )
    end

    def read_only_check_box(group, **)
      group.check_box(
        name: :remaining_work_read_only,
        label: I18n.t("cost_types.settings.time_tracking.remaining_work_read_only"),
        caption: I18n.t("cost_types.settings.time_tracking.remaining_work_read_only_caption"),
        checked: model.remaining_work_read_only?,
        **
      )
    end
  end
end
