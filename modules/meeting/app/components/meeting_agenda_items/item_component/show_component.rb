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
    def initialize(meeting_agenda_item:)
      super

      @meeting_agenda_item = meeting_agenda_item
    end

    def call
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column(flex: 1, flex_layout: true) do |flex|
          if drag_and_drop_enabled?
            flex.with_column(mr: 2) do
              drag_handler_partial
            end
          end
          flex.with_column(flex: 1, mt: 2) do
            description_partial
          end
        end
        flex.with_column do
          right_column_partial
        end
      end
    end

    private

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
      @meeting_agenda_item.meeting.agenda_items_open?
    end

    def drag_handler_partial
      render(Primer::Beta::IconButton.new(
               scheme: :invisible,
               classes: "handle",
               size: :medium,
               disabled: false,
               icon: :grabber,
               show_tooltip: true,
               'aria-label': "Drag agenda item"
             ))
    end

    def show_time_slot?
      true
    end

    def edit_enabled?
      true
    end

    def issue_partial
      flex_layout do |flex|
        flex.with_row do
          issue_link_partial
        end
        flex.with_row(flex_layout: true, mt: 2, bg: :subtle, border: true, border_radius: 2, p: 3) do |flex|
          flex.with_row do
            issue_content_partial
          end
          flex.with_row(mt: 2, pl: 4) do
            issue_resolution_partial
          end
        end
      end
    end

    def issue_link_partial
      link_to(work_package_path(@meeting_agenda_item.work_package_issue.work_package), target: "_blank", rel: "noopener") do
        render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold)) do
          "##{@meeting_agenda_item.work_package_issue.work_package.id} #{@meeting_agenda_item.work_package_issue.work_package.subject}"
        end
      end
    end

    def issue_content_partial
      render(WorkPackageTab::Issues::ItemComponent.new(issue: @meeting_agenda_item.work_package_issue,
                                                       called_from_meeting: @meeting_agenda_item.meeting))
    end

    def issue_resolution_partial
      render(MeetingAgendaItems::ItemComponent::IssueResolutionComponent.new(issue: @meeting_agenda_item.work_package_issue,
                                                                             meeting_agenda_item: @meeting_agenda_item))
    end

    def description_partial
      flex_layout do |flex|
        flex.with_row(mb: 2) do
          title_partial
        end
        # flex.with_row do
        #   meta_info_partial
        # end
        flex.with_row do
          details_partial
        end
      end
    end

    def title_partial
      if @meeting_agenda_item.work_package_issue.present?
        issue_partial
      else
        render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold)) do
          @meeting_agenda_item.title
        end
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
                   datetime: @meeting_agenda_item.created_at
                 ))
        end
      end
    end

    def details_partial
      render(MeetingAgendaItems::ItemComponent::NotesComponent.new(meeting_agenda_item: @meeting_agenda_item))
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
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal", 'aria-label': "Agenda item actions")
        edit_action_item(menu)
        # add_notes_action_item(menu)
        delete_action_item(menu)
      end
    end

    def edit_action_item(menu)
      return if @meeting_agenda_item.meeting.agenda_items_closed?

      menu.with_item(label: "Edit agenda item",
                     href: edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
                     content_arguments: {
                       data: { 'turbo-stream': true }
                     })
    end

    def delete_action_item(menu)
      return unless @meeting_agenda_item.meeting.agenda_items_open?

      menu.with_item(label: "Delete agenda item",
                     color: :danger,
                     href: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
                     form_arguments: {
                       method: :delete, data: { confirm: "Are you sure?", 'turbo-stream': true }
                     })
    end

    # def actions_partial
    #   flex_layout(justify_content: :flex_end) do |flex|
    #     flex.with_column do
    #       edit_action_partial
    #     end
    #     flex.with_column do
    #       delete_action_partial
    #     end
    #   end
    # end

    # def edit_action_partial
    #   return if @meeting_agenda_item.meeting.agenda_items_closed?

    #   form_with(
    #     url: edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
    #     method: :get,
    #     data: { 'turbo-stream': true }
    #   ) do |_form|
    #     flex_layout do |flex|
    #       flex.with_row do
    #         render(Primer::Beta::IconButton.new(
    #                  size: :medium,
    #                  disabled: false,
    #                  icon: :pencil,
    #                  show_tooltip: true,
    #                  type: :submit,
    #                  'aria-label': "Edit agenda item"
    #                ))
    #       end
    #     end
    #   end
    # end

    # def delete_action_partial
    #   return unless @meeting_agenda_item.meeting.agenda_items_open?

    #   form_with(
    #     url: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
    #     method: :delete,
    #     data: { 'turbo-stream': true, confirm: "Are you sure?" }
    #   ) do |_form|
    #     flex_layout do |flex|
    #       flex.with_row do
    #         render(Primer::Beta::IconButton.new(
    #                  ml: 2,
    #                  scheme: :danger,
    #                  size: :medium,
    #                  disabled: false,
    #                  icon: :trash,
    #                  show_tooltip: true,
    #                  type: :submit,
    #                  'aria-label': "Delete agenda item"
    #                ))
    #       end
    #     end
    #   end
    # end
  end
end
