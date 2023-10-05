# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

require 'support/components/common/modal'
require 'support/components/autocompleter/ng_select_autocomplete_helpers'

module Components
  module WorkPackages
    class ShareModal < Components::Common::Modal
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_reader :work_package

      def initialize(work_package)
        super()

        @work_package = work_package
      end

      def invite_user(user, role_name)
        # Adding a user to the list of shared users
        select_autocomplete page.find('[data-test-selector="op-share-wp-invite-autocomplete"]'),
                            query: user.firstname,
                            select_text: user.name,
                            results_selector: 'body'

        within modal_element.find('[data-test-selector="op-share-wp-invite-role"]') do
          # Open the ActionMenu
          click_button 'View'

          find('.ActionListContent', text: role_name).click
        end

        within modal_element do
          click_button 'Invite'
        end
      end

      alias_method :invite_group, :invite_user

      def remove_user(user)
        within user_row(user) do
          click_button 'Remove'
        end
      end

      def change_role(user, role_name)
        within user_row(user) do
          find('[data-test-selector="op-share-wp-update-role"]').click

          find('.ActionListContent', text: role_name).click
        end
      end

      def close
        modal_element.send_keys(:escape)
      end

      def expect_shared_with(user, role_name = nil, position: nil, editable: true)
        within shares_list do
          expect(page)
            .to have_text(user.name)
        end

        if position
          within shares_list do
            expect(page)
              .to have_selector("li:nth-child(#{position})", text: user.name),
                  "Expected #{user.name} to be ##{position} on the shares list."
          end
        end

        if role_name
          within user_row(user) do
            expect(page)
              .to have_button(role_name)
          end
        end

        unless editable
          within user_row(user) do
            expect(page)
              .not_to have_button
          end
        end
      end

      def expect_not_shared_with(user)
        within shares_list do
          expect(page)
            .not_to have_text(user.name)
        end
      end

      def expect_shared_count_of(count)
        expect(active_list)
          .to have_selector('[data-test-selector="op-share-wp-active-count"]', text: "#{count} users")
      end

      def expect_no_invite_option
        within modal_element do
          expect(page)
            .to have_text(I18n.t('work_package.sharing.permissions.denied'))
        end
      end

      def user_row(user)
        modal_element
          .find("[data-test-selector=\"op-share-wp-active-user-#{user.id}\"]")
      end

      def active_list
        modal_element
          .find('[data-test-selector="op-share-wp-active-list"]')
      end

      def shares_list
        active_list.find_by_id('op-share-wp-active-shares')
      end
    end
  end
end
