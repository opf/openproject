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

  let!(:non_project_user) do
    FactoryBot.create :user,
                      firstname: 'Nonproject',
                      lastname: 'User'
  end

  let!(:role) do
    FactoryBot.create :role,
                      name: 'Member',
                      permissions: permissions
  end

  describe 'through the assignee field' do
    let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }
    let(:assignee_field) { wp_page.edit_field :assignee }
    let(:modal) { ::Components::Users::InviteUserModal.new }

    before do
      wp_page.visit!
    end

    it 'can add an existing user to the project' do
      assignee_field.activate!

      find('.ng-dropdown-footer button', text: 'Invite', wait: 10).click

      modal.expect_open

      # STEP 1: Project and type
      modal.expect_title 'Invite user'
      modal.autocomplete project.name
      modal.select_type 'User'

      modal.next

      # STEP 2: User name
      modal.autocomplete non_project_user.name
      modal.next

      # STEP 3: Role name
      modal.autocomplete role.name
      modal.next

      # STEP 4: Invite message
      modal.invitation_message 'Welcome user!'
      modal.click_modal_button 'Review Invitation'

      modal.within_modal do
        expect(page).to have_text project.name
        expect(page).to have_text non_project_user.name
        expect(page).to have_text role.name
        expect(page).to have_text 'Welcome user!'
      end
    end

    context 'when the user has no permission to manage members' do
      let(:permissions) { %i[view_work_packages edit_work_packages] }
    end
  end
end
