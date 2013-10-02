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
require_relative '../support/shared/become_member'

describe Group do
  include BecomeMember

  let(:group) { FactoryGirl.build(:group) }
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.create(:project_with_types) }
  let(:status) { FactoryGirl.create(:status) }
  let(:package) { FactoryGirl.build(:work_package, :type => project.types.first,
                                                   :author => user,
                                                   :project => project,
                                                   :status => status) }

  describe :destroy do
    describe 'work packages assigned to the group' do
      before do
        become_member_with_permissions project, group, [:view_work_packages]
        package.assigned_to = group

        package.save!
      end

      it 'should reassign the work package to nobody' do
        group.destroy

        package.reload

        package.assigned_to.should == DeletedUser.first
      end

      it 'should update all journals to have the deleted user as assigned' do
        group.destroy

        package.reload

        package.journals.all?{ |j| j.data.assigned_to_id == DeletedUser.first.id }.should be_true
      end
    end
  end
end
