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
  current_user do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  let!(:role) do
    FactoryBot.create :role,
                      name: 'Member',
                      permissions: permissions
  end

  let(:modal) do
    ::Components::Users::InviteUserModal.new project: project,
                                             principal: principal,
                                             role: role
  end

  shared_examples 'invites the principal to the project' do
    it 'will invite that principal to the project' do
      modal.run_all_steps

      assignee_field.expect_inactive!
      assignee_field.expect_display_value added_principal.name

      new_member = project.reload.member_principals.find_by(user_id: added_principal.id)
      expect(new_member).to be_present
      expect(new_member.roles).to eq [role]
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
        let!(:principal) { FactoryBot.create :user,
                           firstname: 'Nonproject firstname',
                           lastname: 'nonproject lastname'
        }
        it 'can add an existing user to the project' do
          modal.run_all_steps

          assignee_field.expect_inactive!
          assignee_field.expect_display_value principal.name

          # But the user got created
          new_member = project.reload.members.find_by(user_id: principal.id)
          expect(new_member).to be_present
          expect(new_member.roles).to eq [role]
        end
      end

      context 'with a user to be invited' do
        let(:principal) { FactoryBot.build :invited_user }

        context 'when the current user has permissions to create a user' do
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members manage_user] }

          it_behaves_like 'invites the principal to the project' do
            let(:added_principal) { User.find_by!(mail: principal.mail) }
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
          let(:permissions) { %i[view_work_packages edit_work_packages manage_members manage_user] }

          let(:project_no_permissions) { FactoryBot.create :project }
          let(:role_no_permissions) { FactoryBot.create :role,
                                      permissions: %i[view_work_packages edit_work_packages]
          }
          let!(:membership_no_permission) {
            FactoryBot.create :member,
            user: current_user,
            project: project_no_permissions,
            roles: [role_no_permissions]
          }

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
              let(:permissions) { %i[view_work_packages edit_work_packages manage_members manage_placeholder_user] }

              it_behaves_like 'invites the principal to the project' do
                let(:added_principal) { PlaceholderUser.find_by!(name: 'MY NEW PLACEHOLDER') }
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
            let(:permissions) { %i[view_work_packages edit_work_packages manage_members manage_placeholder_user] }

            it_behaves_like 'invites the principal to the project' do
              let(:added_principal) { principal }
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
        let(:principal) { FactoryBot.create :group, name: 'MY NEW GROUP' }

        it_behaves_like 'invites the principal to the project' do
          let(:added_principal) { principal }
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
