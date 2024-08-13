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

module Pages::StructuredMeeting
  class History < ::Pages::Page
    def initialize(meeting)
      super()
      @meeting = meeting
    end

    def open_history_modal
      retry_block do
        click_link_or_button "op-meetings-header-action-trigger"
        click_link_or_button "History"
        # dynamically wait for the modal to be loaded
        # otherwise running into timing issues with `item = history_page.first_item`
        expect(page).to have_css(".op-activity-list--item")
      end
    end

    def close_history_modal
      if page.has_selector?(".Overlay-closeButton", wait: 0)
        page.find(".Overlay-closeButton").click
      end
    end

    def expect_event(title, action:, actor:, timestamp: nil, &)
      title = page.find(".op-activity-list--item-title", text: title, exact_text: true)
      subtitle = title.sibling(".op-activity-list--item-subtitle")

      expect(subtitle).to have_text(actor)
      expect(subtitle).to have_text(action)
      expect(subtitle).to have_text(timestamp) if timestamp

      if block_given?
        details = title.find(".op-activity-list--item-details")
        page.within(details, &)
      end
    end

    def first_item
      page.first(".op-activity-list--item")
    end

    def find_item(detail)
      detail = page.find("li.op-activity-list--item-detail", text: detail)
      detail.ancestor(".op-activity-list--item-details").ancestor(".op-activity-list--item")
    end
  end
end
