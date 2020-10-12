#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Components
  module UIAutocompleteHelpers
    def search_autocomplete(element, query:, results_selector: nil)
      # Open the element
      element.click
      # Insert the text to find
      element.set(query)
      sleep(0.5)

      ##
      # Find the open dropdown
      list =
        if results_selector
          page.find(results_selector)
        else
          page.find('.ui-autocomplete')
        end

      scroll_to_element(list)
      list
    end

    def select_autocomplete(element, query:, results_selector: nil, select_text: nil)
      target_dropdown = search_autocomplete(element, results_selector: results_selector, query: query)

      ##
      # If a specific select_text is given, use that to locate the match,
      # otherwise use the query
      text = select_text.presence || query

      # click the element to select it
      target_dropdown.find('.ui-menu-item', text: text).click
    end
  end
end

shared_context 'ui-autocomplete helpers' do
  include ::Components::UIAutocompleteHelpers
end
