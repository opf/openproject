#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'


feature 'Invite user modal', type: :feature, js: true do
  shared_let(:project) { FactoryBot.create :project }
  shared_let(:work_package) { FactoryBot.create :work_package, project: project }

  let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
  let(:global_permissions) { %i[] }
  let(:modal) do
    ::Components::Users::InviteUserModal.new project: project,
                                             principal: principal,
                                             role: role,
                                             invite_message: invite_message
  end
  let!(:role) do
    FactoryBot.create :role,
                      name: 'Member',
                      permissions: permissions
  end
  let(:invite_message) { "Welcome to the team. **You'll like it here**."}
  let(:mail_membership_recipients) { [] }
  let(:mail_invite_recipients) { [] }

  current_user do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role,
                      global_permissions: global_permissions
  end

  shared_examples 'invites the principal to the project' do
    it 'invites that principal to the project' do
      perform_enqueued_jobs do
        modal.run_all_steps
      end

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
          .to match_array [recipient.mail]

        expect(ActionMailer::Base.deliveries[index].body.encoded)
          .to include "Welcome to OpenProject"
      end

      mail_membership_recipients.each_with_index do |recipient, index|
        overall_index = index + mail_invite_recipients.length

        expect(ActionMailer::Base.deliveries[overall_index].to)
          .to match_array [recipient.mail]

        expect(ActionMailer::Base.deliveries[overall_index].body.encoded)
          .to include OpenProject::TextFormatting::Renderer.format_text(invite_message)

        expect(ActionMailer::Base.deliveries[overall_index].body.encoded)
          .to include role.name
      end
    end
  end

  describe 'inviting a principal to a project' do
    describe 'through the assignee field' do
      let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
      let(:assignee_field) { wp_page.edit_field :assignee }

      before do
        wp_page.visit!

        assignee_field.activate!

        find('.ng-dropdown-footer button', text: 'Invite', wait: 10).click
      end

      context 'with an existing user' do
        let!(:principal) do
          FactoryBot.create :user,
                            firstname: 'Nonproject firstname',
                            lastname: 'nonproject lastname'
        end

        it_behaves_like 'invites the principal to the project' do
          let(:added_principal) { principal }
          let(:mail_membership_recipients) { [principal] }
        end
      end

      context 'with a user to be invited' do
        let(:principal) { FactoryBot.build :invited_user }

        context 'when the current user has permissions to create a user' do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
          let(:global_permissions) { %i[manage_user] }

          it_behaves_like 'invites the principal to the project' do
            let(:added_principal) { User.find_by!(mail: principal.mail) }
            let(:mail_invite_recipients) { [added_principal] }
            let(:mail_membership_recipients) { [added_principal] }
          end
        end

        context 'when the current user does not have permissions to invite a user to the instance by email' do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
          it 'does not show the invite user option' do
            modal.project_step
            ngselect = modal.open_select_in_step principal.mail
            expect(ngselect).to have_text "No users were found"
            expect(ngselect).not_to have_text "Invite: #{principal.mail}"
          end
        end

        context 'when the current user does not have permissions to invite a user in this project' do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
          let(:global_permissions) { %i[manage_user] }

          let(:project_no_permissions) { FactoryBot.create :project }
          let(:role_no_permissions) do
            FactoryBot.create :role,
                              permissions: %i[view_work_packages edit_work_packages]
          end

          let!(:membership_no_permission) do
            FactoryBot.create :member,
                              user: current_user,
                              project: project_no_permissions,
                              roles: [role_no_permissions]
          end

          it 'disables projects for which you do not have rights' do
            ngselect = modal.open_select_in_step
            expect(ngselect).to have_text "#{project_no_permissions.name}\nYou are not allowed to invite members to this project"
          end
        end
      end

      describe 'inviting placeholders' do
        let(:principal) { FactoryBot.build :placeholder_user, name: 'MY NEW PLACEHOLDER' }

        context 'an enterprise system', with_ee: %i[placeholder_users] do
          describe 'create a new placeholder' do
            context 'with permissions to manage placeholders' do
              let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
              let(:global_permissions) { %i[manage_placeholder_user] }

              it_behaves_like 'invites the principal to the project' do
                let(:added_principal) { PlaceholderUser.find_by!(name: 'MY NEW PLACEHOLDER') }
                # Placeholders get no invite mail
                let(:mail_membership_recipients) { [] }
              end
            end

            context 'without permissions to manage placeholders' do
              let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
              it 'does not allow to invite a new placeholder' do
                modal.within_modal do
                  expect(page).to have_selector '.op-option-list--item', count: 2
                end
              end
            end
          end

          context 'with an existing placeholder' do
            let(:principal) { FactoryBot.create :placeholder_user, name: 'EXISTING PLACEHOLDER' }
            let(:permissions) { %i[view_work_packages edit_work_packages manage_members] }
            let(:global_permissions) { %i[manage_placeholder_user] }

            it_behaves_like 'invites the principal to the project' do
              let(:added_principal) { principal }
              # Placeholders get no invite mail
              let(:mail_membership_recipients) { [] }
            end
          end
        end

        context 'non-enterprise system' do
          it 'shows the modal with placeholder option disabled' do
            modal.within_modal do
              expect(page).to have_field 'Placeholder user', disabled: true
            end
          end
        end
      end

      describe 'inviting groups' do
        let(:group_user) { FactoryBot.create(:user) }
        let(:principal) { FactoryBot.create :group, name: 'MY NEW GROUP', members: [group_user] }

        it_behaves_like 'invites the principal to the project' do
          let(:added_principal) { principal }
          # Groups get no invite mail themselves but their members do
          let(:mail_membership_recipients) { [group_user] }
        end
      end
    end
  end

  context 'when the user has no permission to manage members' do
    let(:permissions) { %i[view_work_packages edit_work_packages] }
    let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
    let(:assignee_field) { wp_page.edit_field :assignee }

    before do
      wp_page.visit!
    end

    it 'cannot add an existing user to the project' do
      assignee_field.activate!

      expect(page).to have_no_selector('.ng-dropdown-footer', text: 'Invite')
    end
  end
end
