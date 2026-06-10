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

module RecurringMeetings
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :recurring_meeting, :cancelled?, to: :model
    delegate :project, to: :recurring_meeting

    def meeting
      model.is_a?(Meeting) ? model : nil
    end

    def instantiated?
      meeting.present? && !cancelled?
    end

    # The canonical scheduled time for this occurrence slot.
    def occurrence_time
      model.recurrence_start_time
    end

    def start_time
      if instantiated?
        link_to start_time_title, project_meeting_path(project, meeting)
      else
        start_time_title
      end
    end

    def user_time_zone(time)
      helpers.in_user_zone(time)
    end

    def formatted_time(time)
      helpers.format_time(user_time_zone(time), include_date: true)
    end

    def old_time
      render(Primer::Beta::Text.new(tag: :s)) { formatted_time(occurrence_time) }
    end

    def start_time_title
      if start_time_changed?
        old_time + simple_format("\n#{formatted_time(meeting.start_time)}")
      else
        formatted_time(occurrence_time)
      end
    end

    def relative_time
      time = start_time_changed? ? meeting.start_time : occurrence_time

      render(OpPrimer::RelativeTimeComponent.new(datetime: user_time_zone(time), prefix: I18n.t(:label_on)))
    end

    def state
      if cancelled?
        "cancelled"
      elsif instantiated?
        meeting.state
      else
        "planned"
      end
    end

    def status
      scheme = status_scheme(state)

      render(Primer::Beta::Label.new(scheme:)) do
        render(Primer::Beta::Text.new) { t("label_meeting_state_#{state}") }
      end
    end

    def status_scheme(state)
      case state
      when "open"
        :success
      when "cancelled"
        :severe
      else
        :secondary
      end
    end

    def create
      return unless creatable?

      render(
        Primer::Beta::Button.new(
          scheme: :default,
          size: :medium,
          tag: :a,
          data: { "turbo-method": "post" },
          href: init_project_recurring_meeting_path(project, recurring_meeting.id, start_time: occurrence_time.iso8601)
        )
      ) do |_c|
        I18n.t(:label_recurring_meeting_create)
      end
    end

    def button_links
      [
        action_menu
      ]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": t(:label_more),
                              scheme: :invisible,
                              data: {
                                "test-selector": "more-button"
                              })

        open_action(menu)
        delete_scheduled_action(menu)
        ical_action(menu)
        delete_action(menu)
        restore_action(menu)
      end
    end

    def open_action(menu)
      return unless creatable?

      menu.with_item(
        label: I18n.t(:label_recurring_meeting_create),
        tag: :a,
        href: init_project_recurring_meeting_path(
          project,
          recurring_meeting.id,
          start_time: occurrence_time.iso8601
        ),
        content_arguments: {
          data: { turbo_method: :post }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :"issue-opened")
      end
    end

    def creatable?
      copy_allowed? && !(instantiated? || cancelled?)
    end

    def ical_action(menu)
      return unless instantiated?

      menu.with_item(label: I18n.t(:label_icalendar_download),
                     href: download_ics_project_recurring_meeting_path(project,
                                                                       recurring_meeting,
                                                                       occurrence_id: meeting.id),
                     content_arguments: {
                       data: { turbo: false }
                     }) do |item|
        item.with_leading_visual_icon(icon: :download)
      end
    end

    def delete_action(menu)
      return unless delete_allowed? && !cancelled? && instantiated?

      menu.with_item(
        label: meeting.past? ? I18n.t(:label_recurring_meeting_delete) : I18n.t(:label_recurring_meeting_cancel),
        scheme: :danger,
        href: delete_dialog_project_meeting_path(project, meeting),
        tag: :a,
        content_arguments: {
          data: { controller: "async-dialog" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def delete_scheduled_action(menu)
      return unless delete_allowed? && !cancelled? && !instantiated?

      menu.with_item(
        label: I18n.t(:label_recurring_meeting_cancel),
        scheme: :danger,
        href: delete_scheduled_dialog_project_recurring_meeting_path(project,
                                                                     recurring_meeting,
                                                                     start_time: occurrence_time.iso8601),
        tag: :a,
        content_arguments: {
          data: { controller: "async-dialog" }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def restore_action(menu)
      return unless cancelled?

      menu.with_item(
        label: I18n.t(:label_recurring_meeting_restore),
        href: init_project_recurring_meeting_path(project, recurring_meeting, start_time: occurrence_time.iso8601),
        form_arguments: {
          method: :post
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :history)
      end
    end

    def delete_allowed?
      User.current.allowed_in_project?(:delete_meetings, project)
    end

    def copy_allowed?
      User.current.allowed_in_project?(:create_meetings, project)
    end

    # A non-cancelled meeting whose actual start_time differs from its canonical
    # recurrence_start_time slot has been moved to a different time.
    def start_time_changed?
      instantiated? && meeting.start_time != occurrence_time
    end

  end
end
