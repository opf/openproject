#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe SystemUser, type: :model do
  let(:system_user) { User.system }

  describe '#grant_privileges' do
    before do
      expect(system_user.admin).to be_falsey
      expect(system_user.status).to eq(User::STATUSES[:locked])
      system_user.grant_privileges
    end

    it 'grant admin rights' do
      expect(system_user.admin).to be_truthy
    end

    it 'unlocks the user' do
      expect(system_user.status).to eq(User::STATUSES[:builtin])
    end
  end

  describe '#remove_privileges' do
    before do
      system_user.admin = true
      system_user.status = User::STATUSES[:active]
      system_user.save
      system_user.remove_privileges
    end

    it 'removes admin rights' do
      expect(system_user.admin).to be_falsey
    end

    it 'locks the user' do
      expect(system_user.status).to eq(User::STATUSES[:locked])
    end
  end

  describe '#run_given' do
    let(:project) { FactoryGirl.create(:project_with_types, is_public: false) }
    let(:user) { FactoryGirl.build(:user) }
    let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
    let(:member) {
      FactoryGirl.build(:member, project: project,
                                 roles: [role],
                                 principal: user)
    }
    let(:status) { FactoryGirl.create(:status) }
    let(:issue) {
      FactoryGirl.build(:work_package, type: project.types.first,
                                       author: user,
                                       project: project,
                                       status: status)
    }

    before do
      issue.save!
      @u = system_user
    end

    it 'runs block with SystemUser' do
      expect(@u.admin?).to be_falsey
      before_user = User.current

      @u.run_given do
        issue.done_ratio = 50
        issue.save
      end
      expect(issue.done_ratio).to eq(50)
      expect(issue.journals.last.user).to eq(@u)

      expect(@u.admin?).to be_falsey
      expect(User.current).to eq(before_user)
    end
  end
end
