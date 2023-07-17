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
      flex_layout(justify_content: :space_between, align_items: :flex_start) do |flex|
        flex.with_column(flex: 1, mr: 5) do
          form_partial
        end
        flex.with_column do
          exit_partial
        end
      end
    end

    private

    def form_partial
      flex_layout do |flex|
        flex.with_row(mb: 3) do
          render(Primer::Beta::Text.new(font_size: :normal, font_weight: :bold, color: :muted)) do 
            "Edit agenda item" 
          end 
        end
        flex.with_row do
          primer_form_with(
            model: @meeting_agenda_item, 
            method: :put, 
            url: meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item)
          ) do |f|
            box_collection do |collection|
              collection.with_box do
                hidden_field_tag :work_package_id, @active_work_package&.id
              end
              collection.with_box do
                render(MeetingAgendaItemForm.new(f, preselected_work_package: @active_work_package))
              end
            end
          end
        end
      end
    end

    def exit_partial
      form_with( 
        url: cancel_edit_meeting_agenda_item_path(@meeting_agenda_item.meeting, @meeting_agenda_item), 
        method: :get, 
        data: { "turbo-stream": true, confirm: 'Are you sure?' } 
      ) do |form|
        box_collection do |collection|
          collection.with_box do
            hidden_field_tag :work_package_id, @active_work_package&.id
          end
          collection.with_box do
            render(Primer::Beta::IconButton.new(
              size: :medium,
              disabled: false,
              icon: :x,
              show_tooltip: true,
              type: :submit,
              "aria-label": "Cancel editing"
            ))
          end
        end
      end
    end
  end
end
