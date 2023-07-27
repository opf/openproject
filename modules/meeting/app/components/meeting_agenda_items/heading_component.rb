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
  class HeadingComponent < Base::Component
    include OpTurbo::Streamable

    def initialize(meeting:)
      super

      @meeting = meeting
    end

    def call
      component_wrapper do
        render(Primer::Beta::Subhead.new(hide_border: true, mt: 3, mb: 2)) do |component|
          component.with_heading do
            "Agenda"
          end
          component.with_description do
            description_partial
          end
          component.with_actions do
            actions_partial
          end
        end
      end
    end

    private

    def description_partial
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 1) do
          state_partial
        end
        if @meeting.agenda_items.any?
          flex.with_column(flex_layout: true, align_items: :center) do |inner_flex|
            inner_flex.with_column(pr: 1) do
              render(Primer::Beta::Text.new) { "Last updated" }
            end
            inner_flex.with_column do
              render(Primer::Beta::RelativeTime.new(datetime: latest_update)) # prefix not working
            end
          end
        end
      end
    end

    def state_partial
      case @meeting.agenda_items_locked?
      when false
        render(Primer::Beta::State.new(title: "Open", scheme: :open, size: :small)) { "Open" }
      when true
        render(Primer::Beta::State.new(title: "Closed", scheme: :closed, size: :small)) { "Closed" }
      end
    end

    def latest_update
      @meeting.agenda_items.maximum(:updated_at)
    end

    def actions_partial
      case @meeting.agenda_items_locked?
      when false
        close_action_partial
      when true
        open_action_partial
      end
    end

    def close_action_partial
      form_with(
        url: close_meeting_agenda_items_path(@meeting),
        method: :put,
        data: { 'turbo-stream': true }
      ) do
        render(Primer::Beta::Button.new(scheme: :default, type: :submit)) do |component|
          component.with_leading_visual_icon(icon: "issue-closed")
          "Close agenda"
        end
      end
    end

    def open_action_partial
      form_with(
        url: open_meeting_agenda_items_path(@meeting),
        method: :put,
        data: { 'turbo-stream': true }
      ) do
        render(Primer::Beta::Button.new(scheme: :default, type: :submit)) do |component|
          component.with_leading_visual_icon(icon: "issue-reopened")
          "Reopen agenda"
        end
      end
    end
  end
end
