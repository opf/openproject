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

describe 'Planning Comparison', type: :model do
  let (:project) { FactoryGirl.create(:project) }
  let (:admin)  { FactoryGirl.create(:admin) }

  before do
    # query implicitly uses the logged in user to check for allowed work_packages/projects
    allow(User).to receive(:current).and_return(admin)
  end

  describe 'going back in history' do
    let(:journalized_work_package) do
      # TODO are these actually unit-tests?!
      wp = nil
      # create 2 journal-entries, to make sure, that the comparison actually picks up the latest one
      Timecop.travel(2.weeks.ago) do
        wp = FactoryGirl.create(:work_package, project: project, start_date: '01/01/2020', due_date: '01/03/2020')
        wp.save # triggers the journaling and saves the old due_date, creating the baseline for the comparison
      end

      Timecop.travel(1.week.ago) do
        wp.reload
        wp.due_date = '01/04/2020'
        wp.save # triggers the journaling and saves the old due_date, creating the baseline for the comparison
      end

      wp.reload
      wp.due_date = '01/05/2020'
      wp.save # adds another journal-entry
      wp
    end

    before do wp = journalized_work_package end

    it 'should return the changes as a work_package' do
      # beware of these date-conversions: 1.week.ago does not catch the change, as created_at is stored as a timestamp
      expect(PlanningComparisonService.compare(project, 5.days.ago).size).to eql 1
      expect(PlanningComparisonService.compare(project, 5.days.ago).first).to be_instance_of WorkPackage
    end

    it 'should return the old due_date in the comparison' do
      # beware of these date-conversions: 1.week.ago does not catch the change, as created_at is stored as a timestamp
      old_work_package = PlanningComparisonService.compare(project, 5.days.ago).first
      expect(old_work_package.due_date).to eql Date.parse '01/04/2020'
    end

    it 'should return only the latest change when the workpackage was edited on the same day more than once' do
      Timecop.travel(1.week.ago) do
        journalized_work_package.reload
        journalized_work_package.due_date = '01/05/2020'
        journalized_work_package.save # triggers the journaling and saves the old due_date, creating the baseline for the comparison

        journalized_work_package.reload
        journalized_work_package.due_date = '01/07/2020'
        journalized_work_package.save
      end

      old_work_packages = PlanningComparisonService.compare(project, 5.days.ago)
      expect(old_work_packages.size).to eql 1

      expect(old_work_packages.first.due_date).to eql Date.parse '01/07/2020'
    end
  end

  describe 'filtering work_packages also applies to the history' do
    let(:assigned_to_user) do
      FactoryGirl.create(:user,
                         member_in_project: project,
                         member_through_role: FactoryGirl.build(:role))
    end
    let (:filter) do
      { f: ['assigned_to_id'],
        op: { 'assigned_to_id' => '=' },
        v: { 'assigned_to_id' => ["#{assigned_to_user.id}"] } }
    end

    let (:work_package) do
      wp = nil
      # create 2 journal-entries, to make sure, that the comparison actually picks up the latest one
      Timecop.travel(1.week.ago) do
        wp = FactoryGirl.create(:work_package, project: project, due_date: '01/03/2020', assigned_to_id: assigned_to_user.id)
        wp.save # triggers the journaling and saves the old due_date, creating the baseline for the comparison
      end

      wp.reload
      wp.due_date = '01/05/2020'
      wp.save # adds another journal-entry
      wp
    end

    let (:filtered_work_package) do
      other_user = FactoryGirl.create(:user)
      wp = nil
      # create 2 journal-entries, to make sure, that the comparison actually picks up the latest one
      Timecop.travel(1.week.ago) do
        wp = FactoryGirl.create(:work_package, project: project, due_date: '01/03/2020', assigned_to_id: other_user.id)
        wp.save # triggers the journaling and saves the old due_date, creating the baseline for the comparison
      end

      wp.reload
      wp.due_date = '01/05/2020'
      wp.save # adds another journal-entry
      wp
    end

    before do
      work_package
      filtered_work_package
    end

    it 'should filter out the work_package assigned to the wrong person' do
      filtered_packages = PlanningComparisonService.compare(project, 5.days.ago, filter)
      expect(filtered_packages).to include work_package
      expect(filtered_packages).not_to include filtered_work_package
    end
  end
end
