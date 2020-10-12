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

require 'features/support/components/ui_autocomplete'

module Components
  module Projects
    class TopMenu
      include Capybara::DSL
      include RSpec::Matchers
      include ::Components::UIAutocompleteHelpers

      def toggle
        page.find('#projects-menu').click
      end

      def expect_current_project(name)
        expect(page).to have_selector('#projects-menu', text: name)
      end

      def expect_open
        expect(page).to have_selector(autocompleter_selector)
      end

      def expect_closed
        expect(page).to have_no_selector(autocompleter_selector)
      end

      def search(query)
        search_autocomplete(autocompleter, query: query)
      end

      def clear_search
        autocompleter.set ''
        autocompleter.send_keys :backspace
      end

      def search_and_select(query)
        select_autocomplete autocompleter,
                            results_selector: autocompleter_results_selector,
                            query: query
      end

      def search_results
        page.find autocompleter_results_selector
      end

      def autocompleter
        page.find autocompleter_selector
      end

      def autocompleter_results_selector
        '.project-menu-autocomplete--results'
      end

      def autocompleter_selector
        '#project_autocompletion_input'
      end
    end
  end
end
