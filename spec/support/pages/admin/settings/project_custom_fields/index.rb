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

require "support/pages/custom_fields/index"

module Pages
  module Admin
    module Settings
      module ProjectCustomFields
        class Index < ::Pages::CustomFields::Index
          def path
            "/admin/settings/project_custom_fields"
          end

          def visit_page(customizable_name)
            fail "Only Project type is expected" unless customizable_name == "Projects"

            visit!
          end

          def expect_add_project_attribute_submenu(close: true)
            within_add_menu(close:) do
              expect(page).to have_test_selector("add-project-custom-field-attribute")
            end
          end

          def expect_no_add_project_attribute_submenu(close: true)
            within_add_menu(close:) do
              expect(page).to have_no_test_selector("add-project-custom-field-attribute")
            end
          end

          def click_to_create_new_custom_field(type)
            within_add_menu do
              click_button "Project attribute"

              click_on type
            end
          end

          def expect_having_create_item(type, enterprise_icon:)
            within_add_menu do
              click_button "Project attribute"

              expect(page).to have_link(type)

              if enterprise_icon
                expect(page.find(:link, type)).to have_css(".octicon-op-enterprise-addons.upsell-colored")
              else
                expect(page.find(:link, type)).to have_no_css(".octicon-op-enterprise-addons.upsell-colored")
              end
            end
          end

          def expect_not_having_create_item(type)
            within_add_menu do
              click_button "Project attribute"

              expect(page).to have_no_link(type)
            end
          end

          private

          def within_add_menu(close: false, &)
            wait_for_network_idle

            button = find_button("Add")

            button.click

            within(button.ancestor("action-menu").find("action-list"), &)

            button.click if close
          end
        end
      end
    end
  end
end
