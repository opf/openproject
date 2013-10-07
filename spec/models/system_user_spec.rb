#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe SystemUser do
  let(:system_user) { User.system }

  describe '#grant_privileges' do
    before do
      system_user.admin.should be_false
      system_user.status.should == User::STATUSES[:locked]
      system_user.grant_privileges
    end

    it 'grant admin rights' do
      system_user.admin.should be_true
    end

    it 'unlocks the user' do
      system_user.status.should == User::STATUSES[:builtin]
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
      system_user.admin.should be_false
    end

    it 'locks the user' do
      system_user.status.should == User::STATUSES[:locked]
    end
  end

  describe '#run_given' do
    let(:project) { FactoryGirl.create(:project_with_types, :is_public => false) }
    let(:user) { FactoryGirl.build(:user) }
    let(:role) { FactoryGirl.create(:role, :permissions => [:view_work_packages]) }
    let(:member) { FactoryGirl.build(:member, :project => project,
                                              :roles => [role],
                                              :principal => user) }
    let(:status) { FactoryGirl.create(:status) }
    let(:issue) { FactoryGirl.build(:work_package, :type => project.types.first,
                                                   :author => user,
                                                   :project => project,
                                                   :status => status) }

    before do
      issue.save!
      @u = system_user
    end

    it 'runs block with SystemUser' do
      @u.admin?.should be_false
      before_user = User.current

      @u.run_given do
        issue.done_ratio = 50
        issue.save
      end
      issue.done_ratio.should == 50
      issue.journals.last.user.should == @u

      @u.admin?.should be_false
      User.current.should == before_user
    end
  end
end
