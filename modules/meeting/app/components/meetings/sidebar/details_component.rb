#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  class Sidebar::DetailsComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper do
        flex_layout do |flex|
          flex.with_row do
            heading_partial
          end
          flex.with_row(mt: 2) do
            details_partial
          end
        end
      end
    end

    private

    def edit_enabled?
      User.current.allowed_to?(:edit_meetings, @meeting.project)
    end

    def heading_partial
      flex_layout(align_items: :center, justify_content: :space_between) do |flex|
        flex.with_column(flex: 1) do
          render(Primer::Beta::Heading.new(tag: :h4)) { t("label_meeting_details") }
        end
        if edit_enabled?
          flex.with_column do
            dialog_wrapper_partial
          end
        end
      end
    end

    def dialog_wrapper_partial
      render(Primer::Alpha::Dialog.new(
               id: "edit-meeting-details-dialog", title: t("label_meeting_details"),
               size: :medium_portrait
             )) do |dialog|
        dialog.with_show_button(icon: :pencil, 'aria-label': t("label_meeting_details_edit"), scheme: :invisible)
        render(Meetings::Sidebar::DetailsFormComponent.new(meeting: @meeting))
      end
    end

    def details_partial
      flex_layout do |flex|
        flex.with_row do
          date_partial
        end
        flex.with_row(mt: 2) do
          time_partial
        end
        flex.with_row(mt: 2) do
          duration_partial
        end
        if @meeting.location.present?
          flex.with_row(mt: 2) do
            location_partial
          end
        end
      end
    end

    def date_partial
      meeting_attribute_row(:calendar) do
        render(Primer::Beta::Text.new) do
          format_date(@meeting.start_time)
        end
      end
    end

    def time_partial
      meeting_attribute_row(:clock) do
        flex_layout(align_items: :center) do |flex|
          flex.with_column do
            render(Primer::Beta::Text.new) do
              "#{format_time(@meeting.start_time, false)} - #{format_time(@meeting.end_time, false)}"
            end
          end
          flex.with_column(ml: 2) do
            render(Primer::Beta::Text.new(color: :subtle, font_size: :small)) do
              Time.zone.to_s[/\((.*?)\)/m, 1]
            end
          end
        end
      end
    end

    def duration_partial
      duration = Duration.new(seconds: @meeting.duration * 3600)

      meeting_attribute_row(:stopwatch) do
        if duration.hours > 0
          render(Primer::Beta::Text.new) do
            "#{duration.hours} h #{duration.minutes} min"
          end
        else
          render(Primer::Beta::Text.new) do
            "#{duration.minutes} min"
          end
        end
      end
    end

    def location_partial
      if @meeting.location.include?("http")
        meeting_attribute_row(:link) do
          render(Primer::Beta::Link.new(href: @meeting.location, target: "_blank")) do
            truncated_location
          end
        end
      else
        meeting_attribute_row(:location) do
          render(Primer::Beta::Text.new) do
            truncated_location
          end
        end
      end
    end

    def truncated_location
      render(Primer::Beta::Truncate.new) do |component|
        component.with_item(max_width: 250) do
          @meeting.location
        end
      end
    end

    def meeting_attribute_row(icon, &)
      flex_layout(align_items: :center, justify_content: :space_between) do |flex|
        flex.with_column do
          render(Primer::Beta::Octicon.new(icon:))
        end
        flex.with_column(flex: 1, ml: 1, &)
      end
    end
  end
end
