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

module MyDay
  class TodayComponent < BaseComponent
    COLOR_SCHEMES = { morning: :attention, afternoon: :accent, evening: :done }.freeze

    def initialize(today:)
      super()
      @today = today
    end

    private

    attr_reader :today

    def summary
      [
        I18n.l(today.date, format: "%A, %-d %B"),
        t("my_day.open_tasks", count: today.open_count),
        t("my_day.meetings", count: today.meetings.size)
      ].join(" · ")
    end

    def row_arguments(day_part, **)
      { border: :bottom, px: 2, py: 1, test_selector: "my-day-#{day_part}", ** }
    end

    def subject_field_arguments
      {
        name: "task[subject]",
        label: t("my_day.quick_add.label"),
        visually_hide_label: true,
        placeholder: t("my_day.quick_add.placeholder"),
        required: true,
        autocomplete: "off",
        full_width: true,
        size: :small
      }
    end
  end
end
