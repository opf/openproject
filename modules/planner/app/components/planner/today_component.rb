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

module Planner
  class TodayComponent < BaseComponent
    def initialize(today:, adding: nil, filter: View::FILTERS.first)
      super(adding:, filter:)
      @today = today
    end

    def add_todo_defaults = { date: today.date, day_part: today.current_day_part }

    def filterable? = true

    private

    attr_reader :today

    def section_box_arguments(section)
      name = t("planner.day_part.#{section.day_part}")

      { padding: :condensed, mb: 4, test_selector: "planner-section-#{section.day_part}",
        data: sortable_list_data(section.day_part, name) }
    end

    def section_header(section)
      SectionHeaderComponent.new(title: t("planner.day_part.#{section.day_part}"),
                                 subtitle: t("planner.time_range.#{section.day_part}"),
                                 counts: counts(section))
    end

    def todo_input(day_part)
      TodoInputComponent.new(group: day_part, view: :today, task_fields: { day_part: })
    end
  end
end
