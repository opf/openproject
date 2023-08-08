#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe Member do
  let(:user) { create(:user) }
  let(:project_role) { create(:role) }
  let(:global_role) { create(:global_role) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  subject(:member) { build(:member, user:, roles: [global_role]) }

  describe 'relations' do
    it { expect(member).to have_many(:member_roles).dependent(:destroy) }
    it { expect(member).to have_many(:roles).through(:member_roles) }
    it { expect(member).to belong_to(:principal).required }
    it { expect(member).to belong_to(:project).optional }
    it { expect(member).to belong_to(:work_package).optional }

    it do
      expect(member).to have_many(:oauth_client_tokens).with_foreign_key(:user_id).with_primary_key(:user_id).dependent(nil)
    end
  end

  describe 'validations' do
    it { expect(member).to validate_uniqueness_of(:user_id).scoped_to(:project_id, :work_package_id) }

    context 'with a project set' do
      before { member.project = project }

      it { expect(member).to validate_absence_of(:work_package_id) }
    end

    context 'with a work packgage set' do
      before { member.work_package = work_package }

      it { expect(member).to validate_absence_of(:project_id) }
    end
  end

  describe '#deletable?' do
    it 'is deletable, when no roles are inherited' do
      member.member_roles.first.inherited_from = nil
      expect(member).to be_deletable
    end

    it 'is not deletable, when roles are inherited' do
      member.member_roles.first.inherited_from = 1
      expect(member).not_to be_deletable
    end
  end

  describe '#deletable_role?' do
    it 'can delete directly assigned roles, but not if role is inherited through a group membership' do
      # user has the global_role by directly being assigned
      member.save

      # user gets a group that will be assigned the project_role
      group = create(:group, members: [user])
      create(:member, project:, principal: group, roles: [project_role])

      # run the service to normalize the users permissions
      expect do
        Groups::CreateInheritedRolesService
          .new(group, current_user: User.system, contract_class: EmptyContract)
          .call(user_ids: [user.id])
        user.reload
      end.to change(user.memberships, :count).by(1)

      # first membership of the user is the global roles they got assigned directly
      expect(user.memberships.first).to be_deletable_role(global_role)

      # second membership of the user is the project role they got by being a group member
      expect(user.memberships.last).not_to be_deletable_role(project_role)
    end
  end
end
