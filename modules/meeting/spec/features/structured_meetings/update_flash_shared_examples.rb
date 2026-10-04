# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec.shared_examples "no flash appears when interacting with backlog in multiple windows" do
  it do
    show_page.visit!
    first_window = current_window
    second_window = open_new_window

    within_window(first_window) do
      show_page.add_agenda_item_to_backlog do
        fill_in "Title", with: "Backlog agenda item"
      end

      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
    end

    within_window(second_window) do
      show_page.visit!
      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)

      item = MeetingAgendaItem.find_by(title: "Backlog agenda item")
      show_page.edit_agenda_item(item) do
        fill_in "Title", with: "Edited title"
      end

      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
    end

    within_window(first_window) do
      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
      show_page.reload!

      show_page.add_agenda_item_to_backlog do
        fill_in "Title", with: "Second item"
      end

      item = MeetingAgendaItem.find_by(title: "Edited title")
      retry_block do
        show_page.select_action(item, I18n.t(:label_agenda_item_move_to_bottom))
      end

      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
    end

    within_window(second_window) do
      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)

      item = MeetingAgendaItem.find_by(title: "Edited title")
      show_page.remove_agenda_item(item)

      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
    end

    within_window(first_window) do
      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)

      show_page.clear_backlog
      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
    end

    within_window(second_window) do
      show_page.trigger_change_poll
      expect(page).to have_no_text I18n.t(:notice_meeting_updated)
    end

    second_window.close
  end
end
