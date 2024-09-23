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

module MeetingAgendaItems
  class FormComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, meeting_section:, meeting_agenda_item:, method:, submit_path:, cancel_path:, type: :simple,
                   display_notes_input: nil)
      super

      @meeting = meeting
      @meeting_section = meeting_section
      @meeting_agenda_item = meeting_agenda_item
      @method = method
      @submit_path = submit_path
      @cancel_path = cancel_path
      @type = type
      @display_notes_input = display_notes_input
    end

    def wrapper_uniq_by
      @meeting_agenda_item.id
    end

    def render?
      User.current.allowed_in_project?(:manage_agendas, @meeting.project)
    end

    private

    def wrapper_data_attributes
      {
        controller: "meeting-agenda-item-form",
        "application-target": "dynamic",
        "meeting-agenda-item-form-cancel-url-value": @cancel_path
      }
    end

    def display_notes_input_value
      if @display_notes_input
        :block
      elsif @meeting_agenda_item.notes.blank?
        :none
      else
        :block
      end
    end

    def display_notes_add_button_value
      if @display_notes_input
        :none
      elsif @meeting_agenda_item.notes.blank?
        :block
      else
        :none
      end
    end
  end
end
