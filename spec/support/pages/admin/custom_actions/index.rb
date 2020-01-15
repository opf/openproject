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

require 'support/pages/page'

module Pages
  module Admin
    module CustomActions
      class Index < ::Pages::Page
        def new
          within '.toolbar-items' do
            click_link 'Custom action'
          end

          Pages::Admin::CustomActions::New.new
        end

        def edit(name)
          within_buttons_of name do
            find('.icon-edit').click
          end

          custom_action = CustomAction.find_by!(name: name)
          Pages::Admin::CustomActions::Edit.new(custom_action)
        end

        def delete(name)
          within_buttons_of name do
            find('.icon-delete').click

            accept_alert_dialog!
          end
        end

        def expect_listed(*names)
          within 'table' do
            Array(names).each do |name|
              expect(page)
                .to have_content name
            end
          end
        end

        def move_top(name)
          within_row_of(name) do
            click_link 'Move to top'
          end
        end

        def move_bottom(name)
          within_row_of(name) do
            click_link 'Move to bottom'
          end
        end

        def move_up(name)
          within_row_of(name) do
            click_link 'Move up'
          end
        end

        def move_down(name)
          within_row_of(name) do
            click_link 'Move down'
          end
        end

        def path
          custom_actions_path
        end

        private

        def within_row_of(name)
          within 'table' do
            within find('tr', text: name) do
              yield
            end
          end
        end

        def within_buttons_of(name)
          within_row_of(name) do
            within find('.buttons') do
              yield
            end
          end
        end
      end
    end
  end
end
