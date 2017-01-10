#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require_relative '../support/shared/become_member'

describe Group, type: :model do
  include BecomeMember

  let(:group) { FactoryGirl.build(:group) }
  let(:user) { FactoryGirl.build(:user) }
  let(:watcher) { FactoryGirl.create :user }
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:status) { FactoryGirl.create(:status) }
  let(:package) {
    FactoryGirl.build(:work_package, type: project.types.first,
                                     author: user,
                                     project: project,
                                     status: status)
  }

  describe '#destroy' do
    describe 'work packages assigned to the group' do
      before do
        group.add_member! user
        group.add_member! watcher

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
      let(:group) { FactoryGirl.build(:group, lastname: '') }

      it { expect(group.valid?).to be_falsey }

      describe 'error message' do
        before do group.valid? end

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
