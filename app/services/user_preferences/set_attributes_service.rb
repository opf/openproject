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

module UserPreferences
  class SetAttributesService < ::BaseServices::SetAttributes
    SETTABLE_PREFERENCES = %w[
      time_zone
      date_format
      time_format
      avatar_color
      avatar_text
      avatar_type
      theme
      increase_theme_contrast
      force_light_theme_contrast
      force_dark_theme_contrast
      disable_keyboard_shortcuts
      require_double_click_for_inline_edit
      warn_on_leaving_unsaved
      comments_sorting
      auto_hide_popups
      diff_type
      my_work_view_mode
      my_work_mode
      workdays
      daily_reminders_enabled
      daily_reminders_times
      immediate_reminders_mentioned
      immediate_reminders_personal_reminder
      pause_reminders_enabled
      pause_reminders_first_day
      pause_reminders_last_day
      pause_reminders_date_range
    ].freeze

    def set_attributes(params)
      model.assign_attributes(params.to_h.stringify_keys.slice(*SETTABLE_PREFERENCES))
    end
  end
end
