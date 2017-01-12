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

describe WorkPackage::SpentTime, type: :model do
  let(:project) do
    work_package.project
  end
  let(:other_project) do
    child_work_package_in_other_project.project
  end
  let(:work_package) do
    FactoryGirl.build(:work_package)
  end
  let(:child_work_package) do
    FactoryGirl.build(:work_package,
                      project: project,
                      parent: work_package)
  end
  let(:child_work_package_in_other_project) do
    FactoryGirl.build(:work_package,
                      parent: work_package)
  end
  let(:time_entry) do
    FactoryGirl.build(:time_entry,
                      work_package: work_package,
                      project: project)
  end
  let(:time_entry2) do
    FactoryGirl.build(:time_entry,
                      work_package: work_package,
                      project: project)
  end
  let(:child_time_entry) do
    FactoryGirl.build(:time_entry,
                      work_package: child_work_package,
                      project: project)
  end
  let(:child_time_entry_in_other_project) do
    FactoryGirl.build(:time_entry,
                      work_package: child_work_package_in_other_project,
                      project: other_project)
  end
  let(:role) do
    FactoryGirl.build(:role,
                      permissions: [:view_time_entries, :view_work_packages])
  end
  let(:role_without_view_time_entries) do
    FactoryGirl.build(:role,
                      permissions: [:view_work_packages])
  end
  let(:role_without_view_work_packages) do
    FactoryGirl.build(:role,
                      permissions: [:view_time_entries])
  end
  let(:user) do
    FactoryGirl.build(:user,
                      member_in_project: project,
                      member_through_role: role)
  end

  before do
    time_entry.save!
    allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)

    allow(User).to receive(:current).and_return(user)
  end

  shared_examples_for 'spent hours' do
    it 'has the spent time of the time entry' do
      expect(subject).to eql time_entry.hours
    end

    it 'sums up the spent time of the time entries' do
      time_entry2.save!

      sum = time_entry.hours + time_entry2.hours

      expect(subject).to eql sum
    end

    it 'inherits the spent time of the descendants' do
      child_time_entry.save!

      sum = time_entry.hours + child_time_entry.hours

      expect(subject).to eql sum
    end

    context 'permissions' do
      it 'counts the child if that child is in a project in which the user ' +
        'has the necessary permissions' do
        FactoryGirl.create(:member,
                           user: user,
                           project: other_project,
                           roles: [role])
        child_time_entry_in_other_project.save!

        sum = time_entry.hours + child_time_entry_in_other_project.hours

        expect(subject).to eql sum
      end

      it 'does not count the child if that child is in a project in which the user ' +
        'lacks the view_time_entries permission' do
        FactoryGirl.create(:member,
                           user: user,
                           project: other_project,
                           roles: [role_without_view_time_entries])
        child_time_entry_in_other_project.save!

        sum = time_entry.hours

        expect(subject).to eql sum
      end

      it 'does not count the child if that child is in a project in which the user ' +
        'lacks the view_work_packages permission' do
        FactoryGirl.create(:member,
                           user: user,
                           project: other_project,
                           roles: [role_without_view_work_packages])
        child_time_entry_in_other_project.save!

        sum = time_entry.hours

        expect(subject).to eql sum
      end
    end
  end

  context 'for a work_package loaded individually' do
    subject { work_package.spent_hours }

    it_behaves_like 'spent hours'
  end

  context 'for a work package that had spent time eager loaded' do
    subject { WorkPackage.include_spent_hours(user).where(id: work_package.id).first.spent_hours }

    it_behaves_like 'spent hours'
  end
end
