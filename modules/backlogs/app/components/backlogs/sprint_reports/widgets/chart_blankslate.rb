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

module Backlogs
  module SprintReports
    module Widgets
      # Including widgets implement `blankslate_reason`, returning nil when the chart can be drawn,
      # or a key of +ICONS+ naming why it cannot.
      module ChartBlankslate
        ICONS = {
          too_long: :blocked,
          no_work: :graph,
          no_epics: :graph,
          not_started: :graph,
          no_story_points: :graph,
          no_estimated_hours: :graph
        }.freeze

        def chart_available? = resolved_blankslate_reason.nil?

        def blankslate
          reason = resolved_blankslate_reason

          render(Primer::Beta::Blankslate.new(spacious: true)) do |blankslate|
            blankslate.with_visual_icon(icon: ICONS.fetch(reason))
            blankslate.with_heading(tag: :h3).with_content(t(".blankslate.#{reason}.heading"))
            blankslate.with_description_content(t(".blankslate.#{reason}.description"))
          end
        end

        private

        def resolved_blankslate_reason
          return @resolved_blankslate_reason if defined?(@resolved_blankslate_reason)

          @resolved_blankslate_reason = blankslate_reason
        end
      end
    end
  end
end
