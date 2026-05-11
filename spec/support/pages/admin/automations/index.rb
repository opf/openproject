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
    module Automations
      class Index < ::Pages::Page
        def new
          page.find_test_selector("op-admin-automations--button-new").click

          wait_for_reload

          Pages::Admin::Automations::New.new
        end

        def edit(name)
          within_buttons_of name do
            find(".icon-edit").click
          end

          automation = Automation.find_by!(name:)
          Pages::Admin::Automations::Edit.new(automation)
        end

        def delete(name)
          accept_alert do
            within_buttons_of name do
              find(".icon-delete").click
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
          within_row_of(name) do
            find("a[title='Move to top']").trigger("click")
          end
          wait_for_network_idle
        end

        def move_bottom(name)
          within_row_of(name) do
            find("a[title='Move to bottom']").trigger("click")
          end
          wait_for_network_idle
        end

        def move_up(name)
          within_row_of(name) do
            find("a[title='Move up']").trigger("click")
          end
          wait_for_network_idle
        end

        def move_down(name)
          within_row_of(name) do
            find("a[title='Move down']").trigger("click")
          end
          wait_for_network_idle
        end

        def path
          automations_path
        end

        private

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
