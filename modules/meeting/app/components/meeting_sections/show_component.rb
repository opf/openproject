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

module MeetingSections
  class ShowComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    with_collection_parameter :meeting_section

    def initialize(meeting_section:, first_and_last: [], form_hidden: true, form_type: :simple, insert_target_modified: true,
                   force_wrapper: false, state: :show)
      super

      @meeting = meeting_section.meeting
      @meeting_section = meeting_section
      @meeting_agenda_items = meeting_section.agenda_items
      @first_and_last = first_and_last
      @form_hidden = form_hidden
      @form_type = form_type
      @insert_target_modified = insert_target_modified
      @force_wrapper = force_wrapper
      @state = state
    end

    private

    def wrapper_uniq_by
      @meeting_section.id
    end

    def insert_target_modified?
      @insert_target_modified
    end

    def insert_target_modifier_id
      "meeting-agenda-items-new-item-#{@meeting_section.id}"
    end

    def editable?
      @meeting_section.editable? && User.current.allowed_in_project?(:manage_agendas, @meeting_section.project)
    end

    def render_section_wrapper?
      @force_wrapper || !@meeting_section.untitled? || @meeting.sections.count > 1
    end

    def render_new_button_in_section?
      @meeting_agenda_items.empty? && @form_hidden && editable?
    end

    def draggable_item_config
      {
        "draggable-id": @meeting_section.id,
        "draggable-type": "section",
        "drop-url": drop_meeting_section_path(@meeting, @meeting_section)
      }
    end

    def drag_and_drop_target_config
      {
        "is-drag-and-drop-target": true,
        "target-container-accessor": ".Box > ul", # the accessor of the container that contains the drag and drop items
        "target-id": @meeting_section.id, # the id of the target
        "target-allowed-drag-type": "agenda-item" # the type of dragged items which are allowed to be dropped in this target
      }
    end
  end
end
