# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module TimeTracking
    class TimeEntryRow < OpPrimer::BorderBoxRowComponent
      include Redmine::I18n

      def button_links
        [
          action_menu
        ]
      end

      def action_menu
        return nil if !(can_modify_time_entry? || can_delete_time_entry?)

        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t("label_more"), scheme: :invisible)

          with_item_group(menu) do
            if time_entry.ongoing?
              stop_timer_action_button(menu)
            else
              edit_action_button(menu)
            end
          end

          with_item_group(menu) { delete_action_button(menu) } if can_delete_time_entry?
        end
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
          concat(render(My::TimeTracking::StopTimerComponent.new(time_entry: time_entry)))
        end

        DurationConverter.output(time_entry.hours_for_calculation, format: :hours_and_minutes)
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

      def activity
        time_entry.activity&.name
      end

      def scheme
        if time_entry.ongoing?
          :info
        else
          super
        end
      end

      delegate :comments, to: :time_entry

      private

      def stop_timer_action_button(menu)
        menu.with_item(
          content_arguments: {
            data: {
              "turbo-stream" => true
            }
          },
          tag: :a,
          label: t("button_stop_timer"),
          href: dialog_time_entry_path(time_entry, onlyMe: true)
        ) do |item|
          item.with_leading_visual_icon(icon: "op-stopwatch-stop")
        end
      end

      def edit_action_button(menu)
        menu.with_item(
          content_arguments: {
            data: {
              "turbo-stream" => true
            }
          },
          tag: :a,
          label: t("label_edit"),
          href: dialog_time_entry_path(time_entry, onlyMe: true)
        ) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def delete_action_button(menu)
        menu.with_item(
          scheme: :danger,
          content_arguments: {
            data: {
              "turbo" => true,
              "turbo-method" => :delete,
              "turbo-confirm" => t("js.text_are_you_sure")
            }
          },
          href: time_entry_path(time_entry, no_dialog: true),
          label: t("label_delete"),
          tag: :a
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

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

      def can_delete_time_entry?
        TimeEntries::DeleteContract.new(time_entry, User.current).valid?
      end

      def can_modify_time_entry?
        TimeEntries::UpdateContract.new(time_entry, User.current).valid?
      end
    end
  end
end
