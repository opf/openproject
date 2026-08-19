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

require "spec_helper"

RSpec.describe "Invite user modal", :js do
  let!(:standard) { create(:standard_global_role) }
  let!(:project) { create(:project) }
  let!(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages edit_work_packages manage_members work_package_assigned] }
  let(:global_permissions) { %i[view_all_principals] }
  let(:modal) do
    Components::Users::InviteUserModal.new project:,
                                           principal:,
                                           role:,
                                           invite_message:
  end
  let!(:role) do
    create(:project_role,
           name: "Member",
           permissions:)
  end
  let(:invite_message) { "Welcome to the team. **You'll like it here**." }
  let(:mail_membership_recipients) { [] }
  let(:mail_invite_recipients) { [] }

  current_user do
    create(:user,
           member_with_roles: { project => role },
           global_permissions:)
  end

  shared_examples "invites the principal to the project" do |skip_project_autocomplete = false|
    let(:modal_actions) { modal.run_all_steps(skip_project_autocomplete:) }

    it "invites that principal to the project" do
      perform_enqueued_jobs { modal_actions }

      assignee_field.expect_inactive!
      assignee_field.expect_display_value added_principal.name

      new_member = project.reload.member_principals.find_by(user_id: added_principal.id)
      expect(new_member).to be_present
      expect(new_member.roles).to eq [role]

      # Check that the expected number of emails are sent.
      # This includes no mails being sent if the recipient list is empty.
      expect(ActionMailer::Base.deliveries.size)
        .to eql mail_invite_recipients.size + mail_membership_recipients.size

      mail_invite_recipients.each_with_index do |recipient, index|
        expect(ActionMailer::Base.deliveries[index].to)
          .to contain_exactly(recipient.mail)

        expect(ActionMailer::Base.deliveries[index].body.encoded)
          .to include "Welcome to OpenProject"
      end

      mail_membership_recipients.each_with_index do |recipient, index|
        overall_index = index + mail_invite_recipients.length

        expect(ActionMailer::Base.deliveries[overall_index].to)
          .to contain_exactly(recipient.mail)

        expect(ActionMailer::Base.deliveries[overall_index].body.encoded)
          .to include OpenProject::TextFormatting::Renderer.format_text(invite_message)

        expect(ActionMailer::Base.deliveries[overall_index].body.encoded)
          .to include role.name
      end
    end
  end

  describe "searching for users in the auto completer" do
    let!(:principal) do
      create(:user,
             firstname: "Nonproject firstname",
             lastname: "nonproject lastname")
    end

    let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

    before do
      wp_page.visit!

      page.find_test_selector("quick-add-menu-button").click
      page.find_test_selector("quick-add-menu-item", text: "Invite user", wait: 5).click
    end

    context "without permission" do
      let!(:standard) { create(:empty_global_role) }

      it "does not show you the email address of other users" do
        modal.expect_open
        modal.project_step
        select = modal.principal_search ""

        expect(select).to have_text(current_user.firstname)
        expect(select).to have_text(principal.firstname)
        expect(select).to have_no_text(principal.mail)
      end
    end

    context "when not selecting the role" do
      it "keeps the principal selected" do
        modal.expect_open
        modal.project_step
        modal.principal_autocomplete

        modal.click_continue(label: "Invite")
        modal.expect_error_displayed "Role can't be blank."

        modal.role_autocomplete
        modal.click_continue(label: "Invite")
        modal.expect_invited_successfully
      end

      context "with invite permission, but not selecting the role" do
        let(:global_permissions) { %i[create_user] }

        it "does not yet invite the user" do
          modal.expect_open
          modal.project_step
          modal.principal_autocomplete "foobar@example.com"

          modal.click_continue(label: "Invite")
          modal.expect_error_displayed "Role can't be blank."

          expect(User.find_by_mail("foobar@example.com")).to be_nil

          modal.role_autocomplete
          modal.click_continue(label: "Invite")
          modal.expect_invited_successfully

          user = User.find_by_mail("foobar@example.com")
          expect(user).to be_invited
        end
      end
    end
  end

  describe "inviting a placeholder on a WP create", with_ee: %i[placeholder_users] do
    let!(:principal) { create(:placeholder_user, name: "EXISTING PLACEHOLDER") }
    let(:wp_page) { Pages::FullWorkPackageCreate.new(project:) }
    let(:assignee_field) { wp_page.edit_field :assignee }
    let(:subject_field) { wp_page.edit_field :subject }
    let!(:status) { create(:default_status) }
    let!(:priority) { create(:default_priority) }
    let(:permissions) { %i[view_work_packages add_work_packages edit_work_packages manage_members work_package_assigned] }

    it "selects the placeholder" do
      wp_page.visit!
      subject_field.expect_active!
      subject_field.set_value "foobar"
      assignee_field.expect_active!

      assignee_field.openSelectField
      find(".ng-dropdown-footer button", text: "Invite", wait: 10).click

      modal.run_all_steps
      expect(page).to have_css(".ng-value-label", text: principal.name)

      wp_page.save!
      wp_page.expect_and_dismiss_toaster(message: "Successful creation.")

      assignee_field.expect_inactive!
      assignee_field.expect_state_text principal

      work_package = WorkPackage.last
      expect(work_package.assigned_to).to eq principal
    end
  end

  describe "inviting a principal to a project" do
    describe "through the assignee field" do
      let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
      let(:assignee_field) { wp_page.edit_field :assignee }

      before do
        wp_page.visit!
        retry_block do
          assignee_field.activate!
        end
        find(".ng-dropdown-footer button", text: "Invite", wait: 10).click
      end

      context "with an existing user" do
        let!(:principal) do
          create(:user,
                 firstname: "Nonproject firstname",
                 lastname: "nonproject lastname")
        end

        it_behaves_like "invites the principal to the project" do
          let(:added_principal) { principal }
          let(:mail_membership_recipients) { [principal] }
        end

        context "when keeping the default project selection" do
          it_behaves_like "invites the principal to the project", skip_project_autocomplete: true do
            let(:added_principal) { principal }
            let(:mail_membership_recipients) { [principal] }
          end
        end

        context "with a required list user CF (regression #58429)" do
          let(:current_user) { create(:admin) }
          let(:list_cf) do
            create(:user_custom_field,
                   :list,
                   name: "List",
                   is_required: true,
                   editable: false,
                   default_option: "A")
          end

          before do
            list_cf
          end

          it_behaves_like "invites the principal to the project" do
            let(:added_principal) { principal }
            let(:mail_membership_recipients) { [principal] }
          end

          context "when the required list CF value is missing" do
            let(:list_cf) do
              create(:user_custom_field,
                     :list,
                     name: "List",
                     is_required: true,
                     editable: false)
            end

            it_behaves_like "invites the principal to the project" do
              let(:added_principal) { principal }
              let(:mail_membership_recipients) { [principal] }
            end
          end
        end
      end

      context "with a user to be invited" do
        let(:principal) { build(:invited_user) }

        context "when the current user has permissions to create a user" do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members work_package_assigned] }
          let(:global_permissions) { %i[create_user] }

          it_behaves_like "invites the principal to the project" do
            let(:added_principal) { User.find_by!(mail: principal.mail) }
            let(:mail_invite_recipients) { [added_principal] }
            let(:mail_membership_recipients) { [added_principal] }
          end

          context "with a required list user CF" do
            let(:current_user) { create(:admin) }
            let(:list_cf) do
              create(:user_custom_field,
                     :list,
                     name: "List",
                     is_required: true,
                     editable: false,
                     default_option: "A")
            end

            before do
              list_cf
            end

            it_behaves_like "invites the principal to the project" do
              let(:added_principal) { User.find_by!(mail: principal.mail) }
              let(:mail_invite_recipients) { [added_principal] }
              let(:mail_membership_recipients) { [added_principal] }
            end

            context "when the required list CF value is missing" do
              let(:string_cf) { create(:user_custom_field, :string, name: "Department", is_required: true) }

              before do
                string_cf
              end

              it_behaves_like "invites the principal to the project" do
                let(:added_principal) { User.find_by!(mail: principal.mail) }
                let(:mail_invite_recipients) { [added_principal] }
                let(:mail_membership_recipients) { [added_principal] }
              end
            end
          end
        end

        context "when the current user does not have permissions to invite a user to the instance by email" do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }

          it "does not show the invite user option" do
            modal.project_step
            ngselect = modal.principal_search principal.mail
            expect(ngselect).to have_text "No items found"
            expect(ngselect).to have_no_text "Invite: #{principal.mail}"
          end
        end

        context "when the current user does not have permissions to invite a user in this project" do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
          let(:global_permissions) { %i[create_user] }

          let(:project_no_permissions) { create(:project) }
          let(:role_no_permissions) do
            create(:project_role,
                   permissions: %i[view_work_packages edit_work_packages])
          end

          let!(:membership_no_permission) do
            create(:member,
                   user: current_user,
                   project: project_no_permissions,
                   roles: [role_no_permissions])
          end

          it "hides projects you are not allowed to access" do
            dropdown = modal.project_search project_no_permissions.name
            expect(dropdown).to have_text "No items found"
            expect(dropdown).to have_no_text project_no_permissions.name
          end
        end

        context "with a project that is archived" do
          let!(:archived_project) { create(:project, active: false) }
          # Use admin to ensure all projects are visible
          let(:current_user) { create(:admin) }

          it "does not show that project" do
            ngselect = modal.open_select_in_step ".ng-select-container"
            expect(ngselect).to have_no_text archived_project
          end
        end
      end

      describe "inviting placeholders" do
        let(:principal) { build(:placeholder_user, name: "MY NEW PLACEHOLDER") }

        context "when in an enterprise system", with_ee: %i[placeholder_users] do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members work_package_assigned] }

          context "without permissions to manage placeholders" do
            it "does not allow to invite a new placeholder" do
              modal.project_step

              dropdown = modal.principal_search "SOME NEW PLACEHOLDER"

              expect(dropdown).to have_text("No items found")
              expect(dropdown).to have_no_text("SOME NEW PLACEHOLDER")
            end
          end

          context "with permissions to manage placeholders" do
            let(:global_permissions) { %i[view_all_principals manage_placeholder_user] }

            it_behaves_like "invites the principal to the project" do
              let(:added_principal) { PlaceholderUser.find_by!(name: "MY NEW PLACEHOLDER") }
              # Placeholders get no invite mail
              let(:mail_membership_recipients) { [] }
            end
          end

          context "with an existing placeholder" do
            let(:principal) { create(:placeholder_user, name: "EXISTING PLACEHOLDER") }
            let(:global_permissions) { %i[view_all_principals] }

            it_behaves_like "invites the principal to the project" do
              let(:added_principal) { principal }
              # Placeholders get no invite mail
              let(:mail_membership_recipients) { [] }
            end
          end
        end

        context "non-enterprise system" do
          it "shows the modal with placeholder option disabled" do
            modal.within_modal do
              expect(page).to have_field "Placeholder user", disabled: true
            end
          end
        end
      end

      describe "inviting groups" do
        let(:group_user) { create(:user) }
        let!(:principal) { create(:group, name: "MY NEW GROUP", members: [group_user]) }

        it_behaves_like "invites the principal to the project" do
          let(:added_principal) { principal }
          # Groups get no invite mail themselves but their members do
          let(:mail_membership_recipients) { [group_user] }
        end

        context "with a required group custom field" do
          let(:current_user) { create(:admin) }
          let(:list_cf) do
            create(:group_custom_field,
                   :list,
                   name: "Department",
                   is_required: true,
                   editable: false,
                   default_option: "A")
          end

          before do
            list_cf
          end

          it_behaves_like "invites the principal to the project" do
            let(:added_principal) { principal }
            let(:mail_membership_recipients) { [group_user] }
          end

          context "when the required group CF value is missing" do
            let(:string_cf) { create(:group_custom_field, :string, name: "Team Type", is_required: true) }

            before do
              string_cf
            end

            it_behaves_like "invites the principal to the project" do
              let(:added_principal) { principal }
              let(:mail_membership_recipients) { [group_user] }
            end
          end
        end
      end
    end
  end

  context "when the user has no permission to manage members" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }
    let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
    let(:assignee_field) { wp_page.edit_field :assignee }

    before do
      wp_page.visit!
    end

    it "cannot add an existing user to the project" do
      assignee_field.activate!

      expect(page).to have_no_css(".ng-dropdown-footer", text: "Invite")
    end
  end
end
