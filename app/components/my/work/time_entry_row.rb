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
  module Work
    class TimeEntryRow < OpPrimer::BorderBoxRowComponent
      include Redmine::I18n

      def button_links
        [
          action_menu
        ]
      end

      def action_menu
        render(My::Work::TimeEntryActionMenuComponent.new(time_entry:))
      end

      def spent_on
        format_time(time_entry.spent_on)
      end

      def time
        if time_entry.ongoing?
          ongoing_time
        else
          time_range
        end
      end

      def hours
        if time_entry.ongoing?
          concat(render(My::Work::StopTimerComponent.new(time_entry: time_entry)))
        end

        DurationConverter.output(time_entry.hours_for_calculation, format: :hours_and_minutes)
      end

      def type
        concat(render(Primer::Beta::Octicon.new(icon: :clock, mr: 1)))

        TimeEntry.model_name.human
      end

      def subject
        return "--" unless time_entry.entity.is_a?(WorkPackage)

        render(Primer::OpenProject::FlexLayout.new) do |flex|
          flex.with_row do
            render(WorkPackages::InfoLineComponent.new(work_package: time_entry.entity))
          end
          flex.with_row do
            render(Primer::Beta::Text.new(font_weight: :semibold)) { time_entry.entity.subject }
          end
        end
      end

      def project
        render(Primer::Beta::Link.new(href: project_path(time_entry.project), underline: true)) do
          time_entry.project.name
        end
      end

      def scheme
        if time_entry.ongoing?
          :info
        else
          super
        end
      end

      private

      def ongoing_time
        time = format_time(time_entry.created_at, include_date: !time_entry.created_at.today?)
        I18n.t("label_timer_since", time:)
      end

      def time_range # rubocop:disable Metrics/AbcSize
        return if time_entry.start_time.blank?

        times = [format_time(time_entry.start_timestamp, include_date: false)]

        times <<
          if time_entry.start_timestamp.to_date == time_entry.end_timestamp.to_date
            format_time(time_entry.end_timestamp, include_date: false)
          else
            format_time(time_entry.end_timestamp, include_date: true)
          end

        times.join(" - ")
      end

      def time_entry
        model
      end
    end
  end
end
