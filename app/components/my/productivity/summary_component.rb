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

module My
  module Productivity
    class SummaryComponent < ApplicationComponent
      CARD_ICONS = {
        open: :"issue-opened",
        due_this_week: :calendar,
        overdue: :alert,
        completed_this_week: :"check-circle",
        completion_rate: :graph,
        on_time_rate: :clock
      }.freeze

      ALERT_CARDS = %i[overdue].freeze

      options :report

      def cards
        CARD_ICONS.map do |key, icon|
          value = card_value(key)

          {
            key:,
            icon:,
            value:,
            label: t("my_productivity.summary.#{key}"),
            color: ALERT_CARDS.include?(key) && value.to_i.positive? ? :danger : :default
          }
        end
      end

      private

      def card_value(key)
        case key
        when :open then report.open_work_packages.count
        when :due_this_week then report.due_this_week.count
        when :overdue then report.overdue_work_packages.count
        when :completed_this_week then report.completed_this_week_count
        when :completion_rate then "#{report.completion_rate}%"
        when :on_time_rate then "#{report.on_time_rate}%"
        end
      end
    end
  end
end
