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

require 'spec_helper'
require_relative '../support/shared/become_member'

describe Group, type: :model do
  include BecomeMember

  let(:group) { FactoryBot.create(:group) }
  let(:user) { FactoryBot.create(:user) }
  let(:watcher) { FactoryBot.create :user }
  let(:project) { FactoryBot.create(:project_with_types) }
  let(:status) { FactoryBot.create(:status) }
  let(:package) {
    FactoryBot.build(:work_package, type: project.types.first,
                     author: user,
                     project: project,
                     status: status)
  }

  it 'should create' do
    g = Group.new(lastname: 'New group')
    expect(g.save).to eq true
  end


  describe 'from legacy specs' do
    let!(:roles) { FactoryBot.create_list :role, 2 }
    let!(:role_ids) { roles.map(&:id).sort }
    let!(:member) { FactoryBot.create :member, project: project, principal: group, role_ids: role_ids }
    let!(:group) { FactoryBot.create(:group, members: user) }


    it 'should roles removed when removing group membership' do
      expect(user).to be_member_of project
      member.destroy
      user.reload
      project.reload
      expect(user).not_to be_member_of project
    end

    it 'should roles removed when removing user from group' do
      expect(user).to be_member_of project
      group.destroy
      user.reload
      project.reload
      expect(user).not_to be_member_of project
    end

    it 'should roles updated' do
      group = FactoryBot.create :group, members: user
      member = FactoryBot.build :member
      roles = FactoryBot.create_list :role, 2
      role_ids = roles.map(&:id)
      member.attributes = {principal: group, role_ids: role_ids}
      member.save!

      member.role_ids = [role_ids.first]
      expect(user.reload.roles_for_project(member.project).map(&:id).sort).to eq([role_ids.first])

      member.role_ids = role_ids
      expect(user.reload.roles_for_project(member.project).map(&:id).sort).to eq(role_ids)

      member.role_ids = [role_ids.last]
      expect(user.reload.roles_for_project(member.project).map(&:id).sort).to eq([role_ids.last])

      member.role_ids = [role_ids.first]
      expect(user.reload.roles_for_project(member.project).map(&:id).sort).to eq([role_ids.first])
    end
  end

  describe '#destroy' do
    describe 'work packages assigned to the group' do
      let(:group) { FactoryBot.create(:group, members: [user, watcher]) }
      before do
        become_member_with_permissions project, group, [:view_work_packages]
        package.assigned_to = group

        package.save!
      end

      it 'should reassign the work package to nobody' do
        group.destroy

        package.reload

        expect(package.assigned_to).to eq(DeletedUser.first)
      end

      it 'should update all journals to have the deleted user as assigned' do
        group.destroy

        package.reload

        expect(package.journals.all? { |j| j.data.assigned_to_id == DeletedUser.first.id }).to be_truthy
      end

      describe 'watchers' do
        before do
          package.watcher_users << watcher
        end

        context 'with user only in project through group' do
          it 'should remove the watcher' do
            group.destroy
            package.reload
            project.reload

            expect(package.watchers).to be_empty
          end
        end
      end
    end
  end

  describe '#create' do
    describe 'group with empty group name' do
      let(:group) { FactoryBot.build(:group, lastname: '') }

      it { expect(group.valid?).to be_falsey }

      describe 'error message' do
        before do
          group.valid?
        end

        it { expect(group.errors.full_messages[0]).to include I18n.t('attributes.groupname') }
      end
    end
  end

  describe 'preference' do
    %w{preference
       preference=
       build_preference
       create_preference
       create_preference!}.each do |method|

      it "should not respond to #{method}" do
        expect(group).to_not respond_to method
      end
    end
  end
end
