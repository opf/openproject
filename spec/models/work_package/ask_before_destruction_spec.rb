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

describe WorkPackage, type: :model do
  let(:work_package) {
    FactoryGirl.create(:work_package, project: project,
                                      status: status)
  }
  let(:work_package2) {
    FactoryGirl.create(:work_package, project: project2,
                                      status: status)
  }
  let(:user) { FactoryGirl.create(:user) }

  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:project2) { FactoryGirl.create(:project, types: [type]) }
  let(:role) { FactoryGirl.create(:role) }
  let(:role2) { FactoryGirl.create(:role) }
  let(:member) {
    FactoryGirl.create(:member, principal: user,
                                roles: [role])
  }
  let(:member2) {
    FactoryGirl.create(:member, principal: user,
                                roles: [role2],
                                project: work_package2.project)
  }
  let(:status) { FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:time_entry) {
    FactoryGirl.build(:time_entry, work_package: work_package,
                                   project: work_package.project)
  }
  let(:time_entry2) {
    FactoryGirl.build(:time_entry, work_package: work_package2,
                                   project: work_package2.project)
  }

  describe '#cleanup_action_required_before_destructing?' do
    describe 'w/ the work package having a time entry' do
      before do
        work_package
        time_entry.save!
      end

      it 'should be true' do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_truthy
      end
    end

    describe 'w/ two work packages having a time entry' do
      before do
        work_package
        time_entry.save!
        time_entry2.save!
      end

      it 'should be true' do
        expect(WorkPackage.cleanup_action_required_before_destructing?([work_package, work_package2])).to be_truthy
      end
    end

    describe 'w/o the work package having a time entry' do
      before do
        work_package
      end

      it 'should be false' do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_falsey
      end
    end
  end

  describe '#associated_classes_to_address_before_destructing?' do
    describe 'w/ the work package having a time entry' do
      before do
        work_package
        time_entry.save!
      end

      it "should be have 'TimeEntry' as class to address" do
        expect(WorkPackage.associated_classes_to_address_before_destruction_of(work_package)).to eq([TimeEntry])
      end
    end

    describe 'w/o the work package having a time entry' do
      before do
        work_package
      end

      it 'should be empty' do
        expect(WorkPackage.associated_classes_to_address_before_destruction_of(work_package)).to be_empty
      end
    end
  end

  describe '#cleanup_associated_before_destructing_if_required' do
    before do
      work_package.save!

      time_entry.hours = 10
      time_entry.save!
    end

    describe 'w/o a cleanup beeing necessary' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'reassign') }

      before do
        time_entry.destroy
      end

      it 'should return true' do
        expect(action).to be_truthy
      end
    end

    describe 'w/ "destroy" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'destroy') }

      it 'should return true' do
        expect(action).to be_truthy
      end

      it 'should not touch the time_entry' do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'w/o an action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user) }

      it 'should return true' do
        expect(action).to be_truthy
      end

      it 'should not touch the time_entry' do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'w/ "nullify" as action' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'nullify') }

      it 'should return true' do
        expect(action).to be_truthy
      end

      it 'should set the work_package_id of all time entries to nil' do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to be_nil
      end
    end

    describe 'w/ "reassign" as action
              w/ reassigning to a valid work_package' do

      context 'with a single work package' do
        let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required(work_package, user, action: 'reassign', reassign_to_id: work_package2.id) }

        before do
          work_package2.save!
          role2.add_permission! :edit_time_entries
          member2.save!
        end

        it 'should return true' do
          expect(action).to be_truthy
        end

        it 'should set the work_package_id of all time entries to the new work package' do
          action

          time_entry.reload
          expect(time_entry.work_package_id).to eq(work_package2.id)
        end

        it "should set the project_id of all time entries to the new work package's project" do
          action

          time_entry.reload
          expect(time_entry.project_id).to eq(work_package2.project_id)
        end
      end

      context 'with a collection of work packages' do
        let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'reassign', reassign_to_id: work_package2.id) }

        before do
          work_package2.save!
          role2.add_permission! :edit_time_entries
          role2.save!
          member2.save!
        end

        it 'should return true' do
          expect(action).to be_truthy
        end

        it 'should set the work_package_id of all time entries to the new work package' do
          action

          time_entry.reload
          expect(time_entry.work_package_id).to eq(work_package2.id)
        end

        it "should set the project_id of all time entries to the new work package's project" do
          action

          time_entry.reload
          expect(time_entry.project_id).to eq(work_package2.project_id)
        end
      end
    end

    describe 'w/ "reassign" as action
              w/ reassigning to a work_package the user is not allowed to see' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'reassign', reassign_to_id: work_package2.id) }

      before do
        work_package2.save!
      end

      it 'should return true' do
        expect(action).to be_falsey
      end

      it 'should not alter the work_package_id of all time entries' do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end
    end

    describe 'w/ "reassign" as action
              w/ reassigning to a non existing work package' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'reassign', reassign_to_id: 0) }

      it 'should return true' do
        expect(action).to be_falsey
      end

      it 'should not alter the work_package_id of all time entries' do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end

      it 'should set an error on work packages' do
        action

        expect(work_package.errors[:base]).to eq([I18n.t(:'activerecord.errors.models.work_package.is_not_a_valid_target_for_time_entries', id: 0)])
      end
    end

    describe 'w/ "reassign" as action
              w/o providing a reassignment id' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'reassign') }

      it 'should return true' do
        expect(action).to be_falsey
      end

      it 'should not alter the work_package_id of all time entries' do
        action

        time_entry.reload
        expect(time_entry.work_package_id).to eq(work_package.id)
      end

      it 'should set an error on work packages' do
        action

        expect(work_package.errors[:base]).to eq([I18n.t(:'activerecord.errors.models.work_package.is_not_a_valid_target_for_time_entries', id: nil)])
      end
    end

    describe 'w/ an invalid option' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, action: 'bogus') }

      it 'should return false' do
        expect(action).to be_falsey
      end
    end

    describe 'w/ nil as invalid option' do
      let(:action) { WorkPackage.cleanup_associated_before_destructing_if_required([work_package], user, nil) }

      it 'should return false' do
        expect(action).to be_falsey
      end
    end
  end
end
