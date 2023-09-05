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

module AgendaComponentStreams
  extend ActiveSupport::Concern

  included do
    def update_header_component_via_turbo_stream(meeting: @meeting, state: :show)
      update_via_turbo_stream(
        component: Meetings::HeaderComponent.new(
          meeting:,
          state:
        )
      )
    end

    def update_sidebar_component_via_turbo_stream(meeting: @meeting)
      update_via_turbo_stream(
        component: Meetings::SidebarComponent.new(
          meeting:
        )
      )
    end

    def update_sidebar_details_component_via_turbo_stream(meeting: @meeting)
      update_via_turbo_stream(
        component: Meetings::Sidebar::DetailsComponent.new(
          meeting:
        )
      )
    end

    def update_sidebar_state_component_via_turbo_stream(meeting: @meeting)
      update_via_turbo_stream(
        component: Meetings::Sidebar::StateComponent.new(
          meeting:
        )
      )
    end

    def update_sidebar_details_form_component_via_turbo_stream(meeting: @meeting)
      update_via_turbo_stream(
        component: Meetings::Sidebar::DetailsFormComponent.new(
          meeting:
        )
      )
    end

    def update_sidebar_participants_component_via_turbo_stream(meeting: @meeting)
      update_via_turbo_stream(
        component: Meetings::Sidebar::ParticipantsComponent.new(
          meeting:
        )
      )
    end

    def update_sidebar_participants_form_component_via_turbo_stream(meeting: @meeting)
      update_via_turbo_stream(
        component: Meetings::Sidebar::ParticipantsFormComponent.new(
          meeting:
        )
      )
    end

    def update_new_component_via_turbo_stream(hidden: false, meeting_agenda_item: nil, meeting: @meeting, type: :simple)
      update_via_turbo_stream(
        component: MeetingAgendaItems::NewComponent.new(
          hidden:,
          meeting:,
          meeting_agenda_item:,
          type:
        )
      )
    end

    def update_new_button_via_turbo_stream(disabled: false, meeting_agenda_item: nil, meeting: @meeting)
      update_via_turbo_stream(
        component: MeetingAgendaItems::NewButtonComponent.new(
          disabled:,
          meeting:,
          meeting_agenda_item:
        )
      )
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

    def update_item_via_turbo_stream(state: :show, meeting_agenda_item: @meeting_agenda_item)
      if @meeting_agenda_item.duration_in_minutes_previously_changed?
        # if duration was changed, all following items are affectected with their time-slot
        # thus update the whole list to reflect the changes on the UI immediately
        update_list_via_turbo_stream
      else
        update_via_turbo_stream(
          component: MeetingAgendaItems::ItemComponent.new(
            state:,
            meeting_agenda_item:
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
