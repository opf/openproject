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

require_relative '../meetings/show'

module Pages::StructuredMeeting
  class Show < ::Pages::Meetings::Show
    def expect_empty
      expect(page).to have_no_selector('[id^="meeting-agenda-items-item-component"]')
    end

    def add_agenda_item(type: MeetingAgendaItem, cancel_followup_item: true, &block)
      page.within('#content') do
        click_button I18n.t(:button_add)
      end

      click_link type.model_name.human

      page.within('#meeting-agenda-items-form-component', &block)

      if cancel_followup_item
        page.find('#meeting-agenda-items-new-component a', text: I18n.t(:button_cancel)).click
      end
    end

    def assert_agenda_order!(*titles)
      retry_block do
        found = page.all(:test_id, 'op-meeting-agenda-title').map(&:text)
        raise "Expected order of agenda items #{titles.inspect}, but found #{found.inspect}" if titles != found
      end
    end

    def remove_agenda_item(item)
      accept_confirm(I18n.t('text_are_you_sure')) do
        select_action item, I18n.t(:button_delete)
      end

      expect_no_agenda_item(title: item.title)
    end

    def expect_agenda_item(title:)
      expect(page).to have_test_selector('op-meeting-agenda-title', text: title)
    end

    def expect_agenda_link(item)
      expect(page).to have_selector("#meeting-agenda-items-item-component-#{item.id}", text: item.work_package.subject)
    end

    def expect_undisclosed_agenda_link(item)
      expect(page).to have_selector("#meeting-agenda-items-item-component-#{item.id}",
                                    text: I18n.t(:label_agenda_item_undisclosed_wp, id: item.work_package_id))
    end

    def expect_no_agenda_item(title:)
      expect(page).not_to have_test_selector('op-meeting-agenda-title', text: title)
    end

    def select_action(item, action)
      page.within("#meeting-agenda-items-item-component-#{item.id}") do
        page.find_test_selector('op-meeting-agenda-actions').click
      end

      page.within('.Overlay') do
        click_on action
      end
    end

    def edit_agenda_item(item, &block)
      select_action item, 'Edit'
      page.within("#meeting-agenda-items-item-component-#{item.id} #meeting-agenda-items-form-component", &block)
    end
  end
end
