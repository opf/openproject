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
  module AgendaComponentStreams
    extend ActiveSupport::Concern

    included do
      def update_header_component_via_turbo_stream(project: @project, meeting: @meeting, state: :show)
        update_via_turbo_stream(
          component: Meetings::HeaderComponent.new(
            meeting:,
            project:,
            state:
          )
        )
      end

      def update_sidebar_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::SidePanelComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_details_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::SidePanel::DetailsComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_state_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::SidePanel::StateComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_details_form_component_via_turbo_stream(meeting: @meeting, status: :bad_request)
        update_via_turbo_stream(
          component: Meetings::SidePanel::DetailsFormComponent.new(
            meeting:
          ),
          status:
        )
      end

      def update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::SidePanel::ParticipantsComponent.new(
            meeting:
          )
        )
      end

      def update_sidebar_participants_form_component_via_turbo_stream(meeting: @meeting)
        update_via_turbo_stream(
          component: Meetings::SidePanel::ParticipantsFormComponent.new(
            meeting:
          ),
          status: :bad_request # TODO: why bad_request?
        )
      end

      def update_show_items_via_turbo_stream(meeting: @meeting)
        meeting.sections.each do |meeting_section|
          update_show_items_of_section_via_turbo_stream(meeting_section:)
        end
      end

      def update_show_items_of_section_via_turbo_stream(meeting_section: @meeting_section)
        agenda_items = meeting_section.agenda_items.with_includes_to_render
        first_and_last = [agenda_items.first, agenda_items.last]

        agenda_items.each do |meeting_agenda_item|
          update_via_turbo_stream(
            component: MeetingAgendaItems::ItemComponent::ShowComponent.new(meeting_agenda_item:, first_and_last:)
          )
        end
      end

      def update_new_component_via_turbo_stream(hidden: false, meeting_section: @meeting_section, meeting_agenda_item: nil,
                                                meeting: @meeting, type: :simple)
        if meeting_section.nil? && meeting_agenda_item.nil?
          meeting_section = meeting.sections.last
        end

        if meeting_agenda_item.present?
          meeting_section = meeting_agenda_item.meeting_section
        end

        update_via_turbo_stream(
          component: MeetingAgendaItems::NewComponent.new(
            hidden:,
            meeting:,
            meeting_section:,
            meeting_agenda_item:,
            type:
          )
        )
      end

      def update_new_button_via_turbo_stream(disabled: false, meeting: @meeting, meeting_section: nil)
        update_via_turbo_stream(
          component: MeetingAgendaItems::NewButtonComponent.new(
            disabled:,
            meeting:,
            meeting_section:
          )
        )
      end

      def render_agenda_item_form_via_turbo_stream(meeting: @meeting, meeting_section: @meeting_section, type: :simple)
        if meeting.sections.empty?
          render_agenda_item_form_for_empty_meeting_via_turbo_stream(meeting:, type:)
        else
          render_agenda_item_form_in_section_via_turbo_stream(meeting:, meeting_section:, type:)
        end

        update_new_button_via_turbo_stream(disabled: true)
      end

      def render_agenda_item_form_for_empty_meeting_via_turbo_stream(meeting: @meeting, type: :simple)
        update_new_component_via_turbo_stream(
          hidden: false,
          meeting_section: nil,
          type:
        )
      end

      def render_agenda_item_form_in_section_via_turbo_stream(meeting: @meeting, meeting_section: @meeting_section, type: :simple)
        if meeting_section.nil?
          meeting_section = meeting.sections.last
        end

        if meeting_section.agenda_items.empty?
          update_section_via_turbo_stream(meeting_section:, form_hidden: false, form_type: type)
        else
          update_new_component_via_turbo_stream(
            hidden: false,
            meeting_section:,
            type:
          )
        end
      end

      def update_list_via_turbo_stream(meeting: @meeting, form_hidden: true, form_type: :simple)
        # replace needs to be called in order to mount the drag and drop handlers again
        # update would not do that and drag and drop would stop working after the first update
        replace_via_turbo_stream(
          component: MeetingAgendaItems::ListComponent.new(
            meeting:,
            form_hidden:,
            form_type:
          )
        )
        # as the list is updated without displaying the form, the new button needs to be enabled again
        # the new button might be in a disabled state
        update_new_button_via_turbo_stream(disabled: false) if form_hidden == true
      end

      def update_item_via_turbo_stream(state: :show, meeting_agenda_item: @meeting_agenda_item, display_notes_input: nil)
        replace_via_turbo_stream(
          component: MeetingAgendaItems::ItemComponent.new(
            state:,
            meeting_agenda_item:,
            display_notes_input:
          )
        )
        update_show_items_via_turbo_stream
      end

      def add_item_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item, clear_slate: false) # rubocop:disable Metrics/AbcSize
        if clear_slate
          update_list_via_turbo_stream(form_hidden: false, form_type: @agenda_item_type)
        elsif meeting_agenda_item.meeting.agenda_items.count == 1
          update_list_via_turbo_stream(form_hidden: true)

          update_new_component_via_turbo_stream(
            hidden: true,
            meeting_section: meeting_agenda_item.meeting_section,
            type: @agenda_item_type
          )

        else
          update_section_header_via_turbo_stream(meeting_section: meeting_agenda_item.meeting_section)

          add_before_via_turbo_stream(
            component: MeetingAgendaItems::ItemComponent.new(
              state: :show,
              meeting_agenda_item:
            ),
            target_component: MeetingSections::ShowComponent.new(
              meeting_section: @meeting_agenda_item.meeting_section
            )
          )

          update_new_component_via_turbo_stream(
            hidden: true,
            meeting_section: meeting_agenda_item.meeting_section,
            type: @agenda_item_type
          )

          update_new_button_via_turbo_stream(disabled: false)

          update_show_items_via_turbo_stream
        end
      end

      def remove_item_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item, clear_slate: false)
        if clear_slate
          update_list_via_turbo_stream
        else
          update_show_items_of_section_via_turbo_stream(meeting_section: meeting_agenda_item.meeting_section)
          if meeting_agenda_item.meeting_section.agenda_items.empty?
            # Show the empty section state by updating the whole section if items are empty
            update_section_via_turbo_stream(meeting_section: meeting_agenda_item.meeting_section)
          else
            remove_via_turbo_stream(
              component: MeetingAgendaItems::ItemComponent.new(
                state: :show,
                meeting_agenda_item:,
                display_notes_input: nil
              )
            )
          end
        end
      end

      def move_item_within_section_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
        move_item_via_turbo_stream(meeting_agenda_item:)

        # Update the header for updated timestamp
        update_header_component_via_turbo_stream

        # update the displayed time slots of all other items in the section
        update_show_items_of_section_via_turbo_stream(meeting_section: meeting_agenda_item.meeting_section)
      end

      def move_item_to_other_section_via_turbo_stream(old_section:, current_section:, meeting_agenda_item: @meeting_agenda_item)
        move_item_via_turbo_stream(meeting_agenda_item:)

        # Update the header for updated timestamp
        update_header_component_via_turbo_stream

        # update the old section
        update_section_header_via_turbo_stream(meeting_section: old_section)

        if old_section.agenda_items.empty?
          update_section_via_turbo_stream(meeting_section: old_section)
        else
          update_show_items_of_section_via_turbo_stream(meeting_section: old_section)
        end

        # update the new section
        update_section_header_via_turbo_stream(meeting_section: current_section)

        if current_section.agenda_items.count == 1
          update_section_via_turbo_stream(meeting_section: current_section)
        else
          update_show_items_of_section_via_turbo_stream(meeting_section: current_section)
        end
      end

      def move_item_via_turbo_stream(meeting_agenda_item: @meeting_agenda_item)
        # Note: The `remove_component` and the `component` are pointing to the same
        # component, but we still need to instantiate them separately, otherwise re-adding
        # of the item will render and empty component.
        remove_component = MeetingAgendaItems::ItemComponent.new(state: :show, meeting_agenda_item:)
        remove_via_turbo_stream(component: remove_component)

        component = MeetingAgendaItems::ItemComponent.new(state: :show, meeting_agenda_item:)

        target_component = if meeting_agenda_item.lower_item
                             MeetingAgendaItems::ItemComponent.new(
                               state: :show,
                               meeting_agenda_item: meeting_agenda_item.lower_item
                             )
                           else
                             MeetingSections::ShowComponent.new(
                               meeting_section: meeting_agenda_item.meeting_section
                             )
                           end

        add_before_via_turbo_stream(component:, target_component:)
      end

      def render_base_error_in_flash_message_via_turbo_stream(errors)
        if errors[:base].present?
          render_error_flash_message_via_turbo_stream(message: errors[:base].to_sentence)
        end
      end

      def update_section_headers_via_turbo_stream(meeting: @meeting)
        meeting.sections.each do |meeting_section|
          update_section_header_via_turbo_stream(meeting_section:)
        end
      end

      def update_section_header_via_turbo_stream(meeting_section: @meeting_section, state: :show)
        update_via_turbo_stream(
          component: MeetingSections::HeaderComponent.new(
            meeting_section:,
            state:
          )
        )
      end

      def update_section_via_turbo_stream(meeting_section: @meeting_section, form_hidden: true, form_type: :simple,
                                          force_wrapper: false, state: :show)
        update_via_turbo_stream(
          component: MeetingSections::ShowComponent.new(
            meeting_section:,
            form_type:,
            form_hidden:,
            force_wrapper:,
            state:
          )
        )
      end

      def add_section_via_turbo_stream(meeting_section: @meeting_section)
        if meeting_section.meeting.sections.count <= 2
          # hide blank slate again through rerendering the list component -> count == 0
          # or show section wrapper of first untitled section -> count == 1
          update_list_via_turbo_stream
          # CODE MAINTENANCE: potentially loosing edit state in last section
        else
          append_via_turbo_stream(
            component: MeetingSections::ShowComponent.new(
              meeting_section:
            ),
            target_component: MeetingAgendaItems::ListComponent.new(
              meeting: meeting_section.meeting
            )
          )
        end
      end

      def remove_section_via_turbo_stream(meeting_section: @meeting_section)
        if meeting_section.meeting.sections.count <= 1
          # show blank slate again through rerendering the list component -> count == 0
          # or hide section wrapper of first (potentially) untitled section -> count == 1
          update_list_via_turbo_stream
          # CODE MAINTENANCE: potentially loosing edit state in last section
        else
          remove_via_turbo_stream(
            component: MeetingSections::ShowComponent.new(
              meeting_section:
            )
          )
        end
      end

      def move_section_via_turbo_stream(meeting_section: @meeting_section)
        # Note: The `remove_component` and the `component` are pointing to the same
        # component, but we still need to instantiate them separately, otherwise re-adding
        # of the item will render and empty component.
        remove_component = MeetingSections::ShowComponent.new(meeting_section:)
        remove_via_turbo_stream(component: remove_component)

        component = MeetingSections::ShowComponent.new(meeting_section:)

        if meeting_section.lower_item
          add_before_via_turbo_stream(
            component:,
            target_component: MeetingSections::ShowComponent.new(
              meeting_section: meeting_section.lower_item,
              insert_target_modified: false
              # insert target is modified for agenda items in this section, but not for sections
            )
          )
        else
          append_via_turbo_stream(
            component: MeetingSections::ShowComponent.new(
              meeting_section:
            ),
            target_component: MeetingAgendaItems::ListComponent.new(
              meeting: meeting_section.meeting
            )
          )
        end
      end

      def update_all_via_turbo_stream
        update_header_component_via_turbo_stream
        update_sidebar_component_via_turbo_stream
        update_new_button_via_turbo_stream
        update_list_via_turbo_stream
      end
    end
  end
end
