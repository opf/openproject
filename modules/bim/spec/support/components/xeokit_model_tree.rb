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

module Components
  class XeokitModelTree
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def sidebar_shows_viewer_menu(visible)
      selector = ".xeokit-tab"
      tabs = ["Models", "Objects", "Classes", "Storeys"]

      tabs.each do |tab|
        expect(page).to have_conditional_selector(visible, selector, text: tab)
      end
    end

    def expect_model_management_available(visible: true)
      selector = ".xeokit-btn.xeokit-addModel"
      expect(page).to have_conditional_selector(visible, selector)
    end

    def click_add_model
      selector = ".xeokit-btn.xeokit-addModel"
      page.find(selector).click
    end

    def select_model_menu_item(model_name, item_label)
      page.find(".xeokit-form-check span", text: model_name).right_click
      page.find(".xeokit-context-menu-item", text: item_label).click
    end

    def select_sidebar_tab(tab)
      selector = ".xeokit-tab"
      page.find(selector, text: tab).click
    end

    def expand_tree
      page.all(".xeokit-tree-panel a.plus").map(&:click)
    end

    def expect_checked(label)
      page
        .find(".xeokit-tree-panel li span", text: label, wait: 10)
        .sibling("input[type=checkbox]:checked")
    end

    def expect_unchecked(label)
      page
        .find(".xeokit-tree-panel li span", text: label, wait: 10)
        .sibling("input[type=checkbox]:not(:checked)")
    end

    def all_checkboxes
      page
        .all(".xeokit-tree-panel li span")
        .map { |item| [item, item.sibling("input[type=checkbox]")] }
    end

    def expect_tree_panel_selected(selected, tab = "Models")
      within (".xeokit-#{tab.downcase}.xeokit-tree-panel") do
        if selected
          expect(page.find("input", match: :first)).to be_checked
        else
          expect(page.find("input", match: :first)).not_to be_checked
        end
      end
    end
  end
end
