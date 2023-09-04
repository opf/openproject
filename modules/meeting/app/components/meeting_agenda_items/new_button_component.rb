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
  class NewButtonComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(meeting:, meeting_agenda_item: nil, disabled: false)
      super

      @meeting = meeting
      @meeting_agenda_item = meeting_agenda_item || MeetingAgendaItem.new(meeting:, author: User.current)
      @disabled = @meeting.closed? || disabled
    end

    def call
      component_wrapper(class: "mt-3") do
        menu_content_partial
      end
    end

    def render?
      User.current.allowed_to?(:create_meeting_agendas, @meeting.project)
    end

    private

    def menu_content_partial
      render(Primer::Alpha::ActionMenu.new) do |component|
        component.with_show_button(scheme: :primary, disabled: @disabled) do |button|
          button.with_leading_visual_icon(icon: :plus)
          t("button_add")
        end
        component.with_item(
          label: t("activerecord.models.meeting_agenda_item", count: 1),
          tag: :a,
          content_arguments: {
            href: new_meeting_agenda_item_path(@meeting, type: "simple"),
            data: { 'turbo-stream': true }
          }
        )
        component.with_item(
          label: t("activerecord.models.work_package", count: 1),
          tag: :a,
          content_arguments: {
            href: new_meeting_agenda_item_path(@meeting, type: "work_package"),
            data: { 'turbo-stream': true }
          }
        )
      end
    end
  end
end
