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

module MeetingAgendaItems
  class ItemComponent::ShowComponent < Base::Component
    def initialize(meeting_agenda_item:, active_work_package: nil, **kwargs)
      @meeting_agenda_item = meeting_agenda_item
      @active_work_package = active_work_package
    end

    def call
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column do
          left_column_partial
        end
        flex.with_column do
          right_column_partial
        end
      end
    end

    private

    def left_column_partial
      flex_layout do |flex|
        if drag_and_drop_enabled?
          flex.with_column do
            drag_handler_partial
          end
        end
        flex.with_column do
          content_partial
        end
      end
    end

    def right_column_partial
      flex_layout(align_items: :center) do |flex|
        if show_time_slot?
          flex.with_column(pr: 2) do
            time_slot_partial
          end
        end
        if edit_enabled?
          flex.with_column do
            actions_partial
          end
        end
      end
    end

    def drag_and_drop_enabled?
      @active_work_package.nil?
    end

    def drag_handler_partial
      render(Primer::Beta::IconButton.new(
        mr: 4,
        classes: "handle",
        size: :medium,
        disabled: false,
        icon: :grabber,
        show_tooltip: true,
        "aria-label": "Move agenda item"
      ))
    end

    def content_partial
      flex_layout do |flex|
        if @meeting_agenda_item.work_package
          flex.with_row(mb: 2) do
            work_package_partial
          end
        end
        flex.with_row(pl: 2) do
          description_partial
        end
      end
    end

    def show_time_slot?
      @active_work_package.nil?
    end

    def edit_enabled?
      if @active_work_package.nil?
        true
      elsif @active_work_package&.id == @meeting_agenda_item.work_package&.id
        true
      else
        false
      end
    end

    def work_package_partial
      link_to(work_package_path(@meeting_agenda_item.work_package), target: "_blank") do
        render(Primer::Beta::Label.new(size: :large)) do 
          "##{@meeting_agenda_item.work_package.id} #{@meeting_agenda_item.work_package.subject}"
        end
      end
    end
    
    def description_partial
      flex_layout do |flex|
        flex.with_row do
          title_partial
        end
        flex.with_row do
          meta_info_partial
        end
        if @meeting_agenda_item.input.present?
          flex.with_row do
            input_partial
          end
        end
        if @meeting_agenda_item.output.present?
          flex.with_row do
            output_partial
          end
        end
      end
    end

    def title_partial
      render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold)) do 
        "#{@meeting_agenda_item.position}. #{@meeting_agenda_item.title}" 
      end 
    end

    def meta_info_partial
      flex_layout do |flex|
        flex.with_column(pr: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :muted)) do 
            "created by #{@meeting_agenda_item.user.name}" 
          end
        end
        flex.with_column do
          render(Primer::Beta::RelativeTime.new(
            font_size: :small,
            color: :muted,
            tense: :past,
            lang: :en,
            datetime: @meeting_agenda_item.created_at,
          ))
        end
      end
    end

    def input_partial
      flex_layout do |flex|
        flex.with_row do
          render(Primer::Beta::Text.new(font_size: :small)) do 
            "Input:" 
          end 
        end
        flex.with_row do
          render(Primer::Box.new(font_size: :small, color: :muted)) do 
            simple_format(@meeting_agenda_item.input, {}, wrapper_tag: "span")
          end 
        end
      end
    end

    def output_partial
      flex_layout do |flex|
        flex.with_row do
          render(Primer::Beta::Text.new(font_size: :small)) do 
            "Output:" 
          end 
        end
        flex.with_row do
          render(Primer::Box.new(font_size: :small, color: :muted)) do 
            simple_format(@meeting_agenda_item.output, {}, wrapper_tag: "span")
          end 
        end
      end
    end

    def time_slot_partial
      render(Primer::Beta::Text.new(font_size: :normal, color: :subtle)) do 
        [
          @meeting_agenda_item.start_time.strftime("%H:%M"),
          "-",
          @meeting_agenda_item.end_time.strftime("%H:%M"),
          "(#{@meeting_agenda_item.duration_in_minutes || 0} min)"
        ].join(" ")
      end 
    end

    def actions_partial
      flex_layout(justify_content: :flex_end) do |flex|
        flex.with_column do
          edit_action_partial
        end
        flex.with_column do
          delete_action_partial
        end
      end
    end

    def edit_action_partial
      form_with( 
        url: edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item), 
        method: :get, 
        data: { "turbo-stream": true } 
      ) do |form|
        flex_layout do |flex|
          flex.with_row do
            hidden_field_tag :work_package_id, @active_work_package&.id
          end
          flex.with_row do
            render(Primer::Beta::IconButton.new(
              mr: 2,
              size: :medium,
              disabled: false,
              icon: :pencil,
              show_tooltip: true,
              type: :submit,
              "aria-label": "Edit agenda item"
            ))
          end
        end
      end
    end

    def delete_action_partial
      form_with( 
        url: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item), 
        method: :delete,
        data: { "turbo-stream": true, confirm: "Are you sure?" } 
      ) do |form|
        flex_layout do |flex|
          flex.with_row do
            hidden_field_tag :work_package_id, @active_work_package&.id
          end
          flex.with_row do
            render(Primer::Beta::IconButton.new(
              scheme: :danger,
              size: :medium,
              disabled: false,
              icon: :trash,
              show_tooltip: true,
              type: :submit,
              "aria-label": "Delete agenda item"
            ))
          end
        end
      end
    end
  end
end
