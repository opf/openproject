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
require_relative "../common/modal"
require_relative "../autocompleter/ng_select_autocomplete_helpers"

module Components
  module Users
    class InviteUserModal < ::Components::Common::Modal
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      attr_accessor :project, :principal, :role, :invite_message

      def initialize(project:, principal:, role:, invite_message: "Welcome!")
        self.project = project
        self.principal = principal
        self.role = role
        self.invite_message = invite_message

        super()
      end

      def run_all_steps(skip_project_autocomplete: false)
        expect_open

        # STEP 1: Project and type
        project_step(skip_autocomplete: skip_project_autocomplete)

        # STEP 2: User name
        principal_step

        # STEP 3: Confirmation screen
        confirmation_step

        # Step 4: Perform invite
        click_modal_button "Send invitation"

        expect_text "#{principal_name} was invited!"

        text =
          case principal
          when User
            "The user can now log in to access #{project.name}"
          when PlaceholderUser
            "The placeholder can now be used in #{project.name}"
          when Group
            "The group is now a part of #{project.name}"
          else
            raise ArgumentError, "Wrong type"
          end

        expect_text text

        # Close
        click_modal_button "Continue"
        expect_closed
      end

      def project_step(next_step: true, skip_autocomplete: false)
        expect_title "Invite user"
        autocomplete ".ng-select-container", project.name unless skip_autocomplete
        select_type type

        click_next if next_step
      end

      def open_select_in_step(selector, query = "")
        select_field = modal_element.find(selector)

        search_autocomplete select_field,
                            query:,
                            results_selector: "body"
      end

      def principal_step(next_step: true)
        if invite_user?
          retry_block do
            autocomplete "op-ium-principal-search", principal_name, select_text: "Invite: #{principal_name}"
          end
        else
          autocomplete "op-ium-principal-search", principal_name
        end
        autocomplete "op-ium-role-search", role.name
        invitation_message invite_message unless placeholder?
        click_next if next_step
      end

      def role_step(next_step: true)
        autocomplete "op-ium-role-search", role.name

        click_next if next_step
      end

      def invitation_step(next_step: true)
        invitation_message invite_message
        click_modal_button "Review invitation" if next_step
      end

      def confirmation_step
        within_modal do
          expect(page).to have_text project.name
          expect(page).to have_text principal_name
          expect(page).to have_text role.name
          expect(page).to have_text invite_message unless placeholder?
        end
      end

      def autocomplete(selector, query, select_text: query)
        select_field = modal_element.find(selector, wait: 5)

        select_autocomplete select_field,
                            query:,
                            select_text:,
                            results_selector: "body"
      end

      def select_type(type)
        within_modal do
          page.find(".op-option-list--item", text: type).click
        end
      end

      def click_next
        click_modal_button "Next"
        wait_for_reload
      end

      def invitation_message(text)
        within_modal do
          find("textarea").set text
        end
      end

      def invite_user?
        principal.invited?
      end

      def placeholder?
        principal.is_a?(PlaceholderUser)
      end

      def principal_name
        if invite_user?
          principal.mail
        else
          principal.name
        end
      end

      def type
        principal.model_name.human
      end

      def expect_error_displayed(message)
        within_modal do
          expect(page)
            .to have_css(".spot-form-field--error", text: message)
        end
      end

      def expect_help_displayed(message)
        within_modal do
          expect(page)
            .to have_text(message)
        end
      end
    end
  end
end
