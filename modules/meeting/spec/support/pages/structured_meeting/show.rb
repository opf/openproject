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

    def add_agenda_item(&block)
      page.within('#content') do
        click_button I18n.t(:button_add)
      end
      click_link 'Agenda item'

      page.within('#meeting-agenda-items-form-component', &block)
    end

    def expect_agenda_item(title:)
      expect(page).to have_selector('[data-qa-selector="op-meeting-agenda-title"]', text: title)
    end

    def expect_no_agenda_item(title:)
      expect(page).not_to have_selector('[data-qa-selector="op-meeting-agenda-title"]', text: title)
    end

    def edit_agenda_item(item, &block)
      page.within("#meeting-agenda-items-item-component-#{item.id}") do
        page.find('[data-qa-seleector="op-meeting-agenda-actions"]').click
      end

      page.within('.Overlay') do
        click_on 'Edit'
      end

      page.within("#meeting-agenda-items-item-component-#{item.id} #meeting-agenda-items-form-component", &block)
    end
  end
end
