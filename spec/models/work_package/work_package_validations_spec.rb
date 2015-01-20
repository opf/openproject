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

describe WorkPackage, type: :model do

  let(:project) { FactoryGirl.create(:project) }
  let(:user) { FactoryGirl.create(:user) }

  describe 'validations' do

    # validations
    [:subject, :priority, :project, :type, :author, :status].each do |field|
      it { is_expected.to validate_presence_of field }
    end

    it { is_expected.to ensure_length_of(:subject).is_at_most 255 }
    it { is_expected.to ensure_inclusion_of(:done_ratio).in_range 0..100 }
    it { is_expected.to validate_numericality_of :estimated_hours }

    it 'validates, that start-date is before end-date' do
      wp = FactoryGirl.build(:work_package, start_date: 1.day.from_now, due_date: 1.day.ago)
      expect(wp.errors_on(:due_date).size).to eq(1)
    end

    it 'validates, that correct formats are properly parsed' do
      wp = FactoryGirl.build(:work_package, start_date: '01/01/13', due_date: '31/01/13')
      expect(wp.errors_on(:start_date).size).to eq(0)
      expect(wp.errors_on(:due_date).size).to eq(0)
    end

    describe 'hierarchical work_package-validations' do
      # There are basically __no__ validations for hierarchies: The sole semantic here is, that the start-date of a parent
      # is set to the earliest start-date of its children.

      let(:early_date) { 1.week.from_now.to_date }
      let(:late_date)  { 2.weeks.from_now.to_date }
      let(:parent) { FactoryGirl.create(:work_package, author: user, project: project, start_date: late_date) }
      let(:child_1) { FactoryGirl.create(:work_package, author: user, project: project, parent: parent, start_date: late_date) }
      let(:child_2) { FactoryGirl.create(:work_package, author: user, project: project, parent: parent, start_date: late_date) }

      it "verify, that the start-date of a parent is set to the start-date of it's earliest child." do
        child_1.start_date = early_date
        expect(child_1).to be_valid # yes, I can move the child-start-date before the parent-start-date...
        child_1.save

        expect {
          parent.reload
        }.to change { parent.start_date }.from(late_date).to(early_date) # ... but this changes the parent's start_date to the child's start_date
      end

    end

  end

  describe 'validations of related packages' do
    let(:predecessor) { FactoryGirl.create(:work_package, author: user, project: project, start_date: '31/01/13') }
    let(:successor)  { FactoryGirl.create(:work_package, author: user, project: project, start_date: '31/01/13') }

    it 'validate, that the start date of a work-package is no sooner than the start_dates of preceding work_packages' do
      relation = Relation.new(from: predecessor, to: successor, relation_type: Relation::TYPE_PRECEDES)
      relation.save!

      successor.reload   # TODO this is ugly: We should be able to test all this with stubbed objects and without hitting the db...
      successor.start_date = '01/01/13'

      expect(successor).not_to be_valid
      expect(successor.errors_on(:start_date).size).to eq(1)

    end

  end

  describe 'validations of versions' do

    it 'validate, that versions of the project can be assigned to workpackages' do
      wp = FactoryGirl.build(:work_package)
      assignable_version   = FactoryGirl.create(:version, project: wp.project)

      wp.fixed_version = assignable_version
      expect(wp).to be_valid

    end
    it 'validate, that the fixed_version belongs to the project ticket lives in' do
      other_project = FactoryGirl.create(:project)
      non_assignable_version = FactoryGirl.create(:version, project: other_project)

      wp = FactoryGirl.build(:work_package)
      wp.fixed_version = non_assignable_version

      expect(wp).not_to be_valid
      expect(wp.errors_on(:fixed_version_id).size).to eq(1)
    end

    it 'validate, that closed or locked versions cannot be assigned' do
      wp = FactoryGirl.build(:work_package)
      non_assignable_version   = FactoryGirl.create(:version, project: wp.project)

      %w{locked closed}.each do |status|
        non_assignable_version.update_attribute(:status, status)

        wp.fixed_version = non_assignable_version
        expect(wp).not_to be_valid
        expect(wp.errors_on(:fixed_version_id).size).to eq(1)
      end
    end

    describe 'validations of enabled types' do
      let (:old_type)     { FactoryGirl.create(:type, name: 'old') }

      let (:old_project)  { FactoryGirl.create(:project, types: [old_type]) }
      let (:work_package) { FactoryGirl.create(:work_package, project: old_project, type: old_type) }

      let (:new_type)     { FactoryGirl.create(:type, name: 'new') }
      let (:new_project)  { FactoryGirl.create(:project, types: [new_type]) }

      it 'validate, that the newly selected type is available for the project the wp lives in' do
        # change type to a type of another project

        work_package.type = new_type

        expect(work_package).not_to be_valid
        expect(work_package.errors_on(:type_id).size).to eq(1)
      end

      it 'validate, that the selected type is enabled for the project the wp was moved into' do
        work_package.project = new_project

        expect(work_package).not_to be_valid
        expect(work_package.errors_on(:type_id).size).to eq(1)
      end

    end

    describe 'validations of priority' do
      let (:active_priority) { FactoryGirl.create(:priority) }
      let (:inactive_priority) { FactoryGirl.create(:priority, active: false) }

      let (:wp) { FactoryGirl.create(:work_package) }

      it 'should validate on active priority' do
        wp.priority = active_priority
        expect(wp).to be_valid
      end

      it 'should validate on an inactive priority that has been assigned before becoming inactive' do
        wp.priority = active_priority
        wp.save!

        active_priority.active = false
        active_priority.save!
        wp.reload

        expect(wp.priority.active).to be_falsey
        expect(wp).to be_valid
      end

      it 'should not validate on an inactive priority' do
        wp.priority = inactive_priority
        expect(wp).not_to be_valid
        expect(wp.errors_on(:priority_id).size).to eq(1)
      end
    end

  end

end
