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
  class FilePickerDialog
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def container
      '[data-test-selector="op-files-picker-modal"]'
    end

    def expect_open
      expect(page).to have_selector(container)
    end

    def confirm_button_state(selection_count:)
      page.within(container) do
        case selection_count
        when 0
          expect(page).to have_button(disabled: true,
                                      exact_text: I18n.t("js.storages.file_links.selection.zero"))
        else
          expect(page).to have_button(disabled: false,
                                      exact_text: I18n.t("js.storages.file_links.selection", count: selection_count))
        end
      end
    end

    def wait_for_folder_loaded
      page.within(container) do
        expect(page).to have_no_css('[data-test-selector="op-file-list--loading-indicator"]')
      end
    end

    def confirm
      page.within(container) do
        page.find('[data-test-selector="op-files-picker-modal--confirm"]').click
      end
    end

    def select_file(text)
      page.within(container) do
        page.find('[data-test-selector="op-files-picker-modal--list-item"]', text:).click
      end
    end

    def has_list_item?(text:, checked:, disabled:)
      page.within(container) do
        expect(page.find('[data-test-selector="op-files-picker-modal--list-item"]', text:))
          .to have_field(type: "checkbox", checked:, disabled:)
      end
    end

    def enter_folder(text)
      page.within(container) do
        page.within('[data-test-selector="op-files-picker-modal--list-item"]', text:) do
          page.find('[data-test-selector="op-files-picker-modal--list-item-caret"]').click
        end
      end
    end

    def select_all
      page.within(container) do
        page.find('[data-test-selector="op-files-picker-modal--select-all"]').click
      end
    end

    def use_breadcrumb(position: "root" | "grandparent" | "parent")
      page.within(container) do
        crumbs = page.all('[data-test-selector="op-breadcrumb"]')
        case position
        when "root"
          expect(crumbs.size).to be > 1
          crumbs[0].click
        when "parent"
          expect(crumbs.size).to be > 2
          crumbs[-2].click
        when "grandparent"
          expect(crumbs.size).to be > 3
          crumbs[-3].click
        end
      end
    end
  end
end
