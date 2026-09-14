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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  module Admin
    module CustomActions
      class Index < ::Pages::Page
        def new
          page.find_test_selector("op-admin-custom-actions--button-new", text: "Custom action").click

          wait_for_reload

          Pages::Admin::CustomActions::New.new
        end

        def edit(name)
          within_buttons_of name do
            find(".icon-edit").click
          end

          custom_action = CustomAction.find_by!(name:)
          Pages::Admin::CustomActions::Edit.new(custom_action)
        end

        def delete(name)
          wait_until_turbo_ready

          wait_for_turbo do
            accept_alert do
              within_buttons_of name do
                find(".icon-delete").click
              end
            end
          end
        end

        def expect_listed(*names)
          within "table" do
            Array(names).each do |name|
              expect(page)
                .to have_content name
            end
          end
        end

        def move_top(name)
          reorder(name, "Move to top")
        end

        def move_bottom(name)
          reorder(name, "Move to bottom")
        end

        def move_up(name)
          reorder(name, "Move up")
        end

        def move_down(name)
          reorder(name, "Move down")
        end

        def path
          custom_actions_path
        end

        private

        def reorder(name, title)
          wait_until_turbo_ready

          wait_for_turbo(wait: 20) do
            within_row_of(name) do
              find("a[title='#{title}']").trigger("click")
            end
          end
        end

        def wait_until_turbo_ready
          page.document.synchronize(20) do
            unless page.evaluate_script("window.Turbo?.session?.started === true")
              raise Capybara::ExpectationNotMet, "Turbo is not ready"
            end
          end
        end

        def within_row_of(name, &)
          within "table" do
            within(find("tr", text: name), &)
          end
        end

        def within_buttons_of(name, &)
          within_row_of(name) do
            within(find(".buttons"), &)
          end
        end
      end
    end
  end
end
