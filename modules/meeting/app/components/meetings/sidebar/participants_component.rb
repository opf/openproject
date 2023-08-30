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
  class Sidebar::ParticipantsComponent < ApplicationComponent
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
            participant_list_partial
          end
        end
      end
    end

    private

    def heading_partial
      flex_layout(align_items: :center, justify_content: :space_between) do |flex|
        flex.with_column(flex: 1) do
          render(Primer::Beta::Heading.new(tag: :h4)) { "Partcipants" }
        end
        flex.with_column do
          dialog_wrapper_partial
        end
      end
    end

    def dialog_wrapper_partial
      render(Primer::Alpha::Dialog.new(
               id: "edit-participants-dialog", title: "Partcipants (Not working right now)",
               size: :medium_portrait
             )) do |dialog|
        dialog.with_show_button(icon: :pencil, 'aria-label': "Edit partcipants", scheme: :invisible)
        render(Meetings::Sidebar::ParticipantsFormComponent.new(meeting: @meeting))
      end
    end

    def participant_list_partial
      flex_layout do |flex|
        @meeting.participants.sort.each do |participant|
          flex.with_row(mt: 1) do
            participant_partial(participant)
          end
        end
      end
    end

    def participant_partial(participant)
      flex_layout(align_items: :center) do |flex|
        flex.with_column do
          render(Users::AvatarComponent.new(user: participant.user,
                                            text_system_attributes: {
                                              font_size: :normal, muted: false
                                            }))
        end
        flex.with_column(ml: 1) do
          render(Primer::Beta::Text.new(font_size: :small, color: :subtle)) do
            participant.invited? ? "Invited" : "Attended"
          end
        end
      end
    end
  end
end
