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
  class ItemComponent::EditComponent < Base::Component
    def initialize(meeting_agenda_item:, active_work_package: nil, **kwargs)
      @meeting_agenda_item = meeting_agenda_item
      @active_work_package = active_work_package
    end

    def call
      flex_layout do |flex|
        flex.with_row(mb: 3) do
          render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold, color: :muted)) do 
            "Edit agenda item" 
          end 
        end
        flex.with_row do
          render(MeetingAgendaItems::FormComponent.new(
            meeting: @meeting_agenda_item.meeting, 
            meeting_agenda_item: @meeting_agenda_item, 
            active_work_package: @active_work_package,
            method: :put,
            submit_path: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item),
            cancel_path: cancel_edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item)
          ))
        end
      end
    end
  end
end
