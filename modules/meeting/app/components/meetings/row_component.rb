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

module Meetings
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    delegate :current_project, to: :table
    delegate :project, to: :model

    def project_name
      helpers.link_to_project project, {}, {}, false
    end

    def title
      if recurring?
        render(Primer::Beta::Link.new(href: project_recurring_meeting_path(project, model), font_weight: :bold)) { model.title }
      elsif recurring_meeting.present?
        occurrence_title
      else
        render(Primer::Beta::Link.new(href: project_meeting_path(project, model), font_weight: :bold)) { model.title }
      end
    end

    def occurrence_title
      safe_join(
        [(render(Primer::Beta::Link.new(href: project_meeting_path(project, model), font_weight: :bold)) { model.title }),
         (render(Primer::Beta::Link.new(href: project_recurring_meeting_path(project, recurring_meeting))) { recurring_label })],
        "  "
      )
    end

    def start_time
      if recurring?
        helpers.format_time(model.start_time, include_date: false)
      else
        safe_join(
          [
            helpers.format_date(model.start_time),
            helpers.format_time(model.start_time, include_date: false)
          ],
          " "
        )
      end
    end

    def duration
      return if model.duration.blank?

      render OpenProject::Common::DurationComponent.new(model.duration, :hours, abbreviated: false)
    end

    def location
      helpers.auto_link(recurring? ? model.template.location : model.location,
                        link: :all,
                        html: { target: "_blank" })
    end

    def frequency
      return unless recurring?

      model.human_frequency
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

        if recurring?
          nil
        elsif recurring_meeting.present?
          view_meeting_series(menu)
        else
          copy_action(menu)
        end

        ical_action(menu) unless recurring?
        delete_action(menu)
      end
    end

    def view_meeting_series(menu)
      menu.with_item(label: I18n.t(:label_recurring_meeting_view),
                     href: project_recurring_meeting_path(project, recurring_meeting)) do |item|
        item.with_leading_visual_icon(icon: :iterations)
      end
    end

    def copy_action(menu)
      return unless copy_allowed?

      menu.with_item(label: I18n.t(:label_meeting_duplicate),
                     href: copy_project_meeting_path(project, model),
                     content_arguments: {
                       data: {
                         turbo_stream: true
                       }
                     }) do |item|
        item.with_leading_visual_icon(icon: :duplicate)
      end
    end

    def ical_action(menu)
      menu.with_item(label: I18n.t(:label_icalendar_download),
                     href: download_ics_project_meeting_path(project, model),
                     content_arguments: {
                       data: { turbo: false }
                     }) do |item|
        item.with_leading_visual_icon(icon: :download)
      end
    end

    def delete_action(menu)
      return unless delete_allowed?

      back_url = current_project ? nil : meetings_path
      label = if recurring_meeting.present?
                model.past? ? I18n.t(:label_recurring_meeting_delete) : I18n.t(:label_recurring_meeting_cancel)
              else
                I18n.t(:label_meeting_delete)
              end
      menu.with_item(label:,
                     scheme: :danger,
                     href: delete_dialog_project_meeting_path(project, model, back_url:),
                     tag: :a,
                     content_arguments: {
                       data: { controller: "async-dialog" }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def recurring_label
      render(Primer::BaseComponent.new(tag: :span, color: :muted)) do
        concat render(Primer::Beta::Octicon.new(icon: :iterations, mr: 1, ml: 1))
        concat render(Primer::Beta::Text.new(font_weight: :bold, font_size: :small)) { recurring_meeting.human_frequency }
      end
    end

    def delete_allowed?
      User.current.allowed_in_project?(:delete_meetings, project)
    end

    def copy_allowed?
      User.current.allowed_in_project?(:create_meetings, project)
    end

    def recurring?
      model.is_a?(RecurringMeeting)
    end

    def recurring_meeting
      return if recurring?

      model.recurring_meeting
    end
  end
end
