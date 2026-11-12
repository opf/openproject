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
    class HeaderInfolineComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include Redmine::I18n

      attr_reader :sprint

      def initialize(sprint:)
        super

        @sprint = sprint
      end

      private

      def displayed_dates
        @displayed_dates ||= ::Sprints::DisplayedDates.new(sprint)
      end

      def actual_dates
        if displayed_dates.finish_planned?
          format_date_tag(displayed_dates.actual_start, include_time: true)
        else
          format_date_range(displayed_dates.actual_range, include_time: true)
        end
      end

      def planned_range_arguments
        return {} unless displayed_dates.actual?

        { font_size: :small, color: :muted, ml: 2 }
      end
    end
  end
end
