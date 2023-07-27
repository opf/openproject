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

module WorkPackageTab
  class MeetingAgendaItems::ListComponent < Base::Component
    def initialize(work_package:, meeting_agenda_items:)
      super

      @meeting_agenda_items = meeting_agenda_items
      @work_package = work_package
    end

    def call
      render(Primer::Beta::BorderBox.new(padding: :condensed)) do |component|
        @meeting_agenda_items.each do |meeting_agenda_item|
          component.with_row do
            row_content_partial(meeting_agenda_item)
          end
        end
      end
    end

    private

    def row_content_partial(meeting_agenda_item)
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column do
          content_partial(meeting_agenda_item)
        end
        flex.with_column do
          actions_partial(meeting_agenda_item)
        end
      end
    end

    def content_partial(meeting_agenda_item)
      flex_layout do |flex|
        flex.with_row(mb: 2) do
          meeting_partial(meeting_agenda_item)
        end
        flex.with_row(pl: 2) do
          description_partial(meeting_agenda_item)
        end
      end
    end

    def meeting_partial(meeting_agenda_item)
      flex_layout do |flex|
        flex.with_column(pr: 1) do
          render(Primer::Beta::Label.new(size: :large)) do
            "Meeting: #{meeting_agenda_item.meeting.title}"
          end
        end
        flex.with_column do
          render(Primer::Beta::Label.new(size: :large)) do
            format_date(meeting_agenda_item.meeting.start_time)
          end
        end
      end
    end

    def description_partial(meeting_agenda_item)
      flex_layout do |flex|
        # flex.with_row do
        #   title_partial(meeting_agenda_item)
        # end
        # flex.with_row do
        #   meta_info_partial(meeting_agenda_item)
        # end
        if meeting_agenda_item.input.present?
          flex.with_row do
            input_partial(meeting_agenda_item)
          end
        end
        if meeting_agenda_item.output.present?
          flex.with_row(mt: 2) do
            output_partial(meeting_agenda_item)
          end
        end
      end
    end

    def title_partial(_meeting_agenda_item)
      flex_layout do |flex|
        flex.with_column(pr: 1) do
          render(Primer::Beta::Text.new(font_size: :normal, color: :muted, font_weight: :bold)) do
            "Agenda item"
          end
        end
        # flex.with_column do
        #   render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold)) do
        #     "#{meeting_agenda_item.title}"
        #   end
        # end
      end
    end

    def meta_info_partial(meeting_agenda_item)
      flex_layout do |flex|
        flex.with_column(pr: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :muted)) do
            "created by #{meeting_agenda_item.user.name}"
          end
        end
        flex.with_column do
          render(Primer::Beta::RelativeTime.new(
                   font_size: :small,
                   color: :muted,
                   tense: :past,
                   lang: :en,
                   datetime: meeting_agenda_item.created_at
                 ))
        end
      end
    end

    def input_partial(meeting_agenda_item)
      flex_layout do |flex|
        flex.with_row do
          render(Primer::Beta::Text.new(font_size: :small)) do
            "Clarifaction need:"
          end
        end
        flex.with_row do
          render(Primer::Box.new(font_size: :small, color: :muted)) do
            simple_format(meeting_agenda_item.input, {}, wrapper_tag: "span")
          end
        end
      end
    end

    def output_partial(meeting_agenda_item)
      flex_layout do |flex|
        flex.with_row do
          render(Primer::Beta::Text.new(font_size: :small)) do
            "Clarification:"
          end
        end
        flex.with_row do
          render(Primer::Box.new(font_size: :small, color: :muted)) do
            simple_format(meeting_agenda_item.output, {}, wrapper_tag: "span")
          end
        end
      end
    end

    def actions_partial(meeting_agenda_item)
      form_with(
        url: show_in_wp_tab_meeting_path(meeting_agenda_item.meeting, work_package_id: @work_package&.id),
        method: :get,
        data: { 'turbo-stream': true }
      ) do |_form|
        render(Primer::Beta::IconButton.new(
                 mr: 2,
                 size: :medium,
                 disabled: false,
                 icon: "arrow-right",
                 show_tooltip: true,
                 type: :submit,
                 'aria-label': "Show meeting"
               ))
      end
    end
  end
end
