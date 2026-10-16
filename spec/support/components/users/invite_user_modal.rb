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

        expect_invited_successfully
      end

      def expect_invited_successfully
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

        expect_closed
        expect_flash message: text
      end

      def project_step(next_step: true, skip_autocomplete: false)
        expect_title "Invite user"
        autocomplete "opce-project-autocompleter", project.name unless skip_autocomplete
        select_type type

        click_continue if next_step
      end

      def open_select_in_step(selector, query = "")
        select_field = modal_element.find(selector, wait: 5)

        search_autocomplete select_field,
                            query:,
                            results_selector: "#user-invitation-dialog .ng-dropdown-panel"
      end

      def principal_step(next_step: true)
        principal_autocomplete
        role_autocomplete
        invitation_message invite_message unless placeholder?
        click_continue(label: "Invite") if next_step
      end

      def role_autocomplete(name = role.name)
        autocomplete "opce-autocompleter", name
      end

      def principal_autocomplete(name = principal_name)
        if invite_user?
          retry_block do
            autocomplete "opce-members-autocompleter", name, select_text: "Send invite to #{name}"
          end
        else
          autocomplete "opce-members-autocompleter", name
        end
      end

      def principal_search(query)
        search_autocomplete(modal_element.find("opce-members-autocompleter"),
                            query:,
                            results_selector: "#user-invitation-dialog .ng-dropdown-panel")
      end

      def project_search(query)
        search_autocomplete(modal_element.find("opce-project-autocompleter"),
                            query:,
                            results_selector: "#user-invitation-dialog .ng-dropdown-panel")
      end

      def role_step(next_step: true)
        autocomplete "opce-autocompleter", role.name

        click_continue if next_step
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
                            results_selector: "#user-invitation-dialog .ng-dropdown-panel"

        select_field
      end

      def select_type(type)
        within_modal do
          choose type
        end
      end

      def click_continue(label: "Continue")
        click_modal_button label
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
          expect(page).to have_text(message)
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
