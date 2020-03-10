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

describe WorkPackage, type: :model do
  let(:work_package) do
    FactoryBot.create(:work_package, project: project,
                                      status: status)
  end
  let(:work_package2) do
    FactoryBot.create(:work_package, project: project2,
                                      status: status)
  end
  let(:user) { FactoryBot.create(:user) }

  let(:type) { FactoryBot.create(:type_standard) }
  let(:project) { FactoryBot.create(:project, types: [type]) }
  let(:project2) { FactoryBot.create(:project, types: [type]) }
  let(:role) { FactoryBot.create(:role) }
  let(:role2) { FactoryBot.create(:role) }
  let(:member) do
    FactoryBot.create(:member,
                      principal: user,
                      roles: [role])
  end
  let(:member2) do
    FactoryBot.create(:member,
                      principal: user,
                      roles: [role2],
                      project: work_package2.project)
  end
  let(:status) { FactoryBot.create(:status) }
  let(:priority) { FactoryBot.create(:priority) }
  let(:time_entry_hours) { 10 }
  let(:time_entry) do
    FactoryBot.create(:time_entry,
                      hours: time_entry_hours,
                      work_package: work_package,
                      project: work_package.project)
  end
  let(:time_entry2) do
    FactoryBot.create(:time_entry,
                      work_package: work_package2,
                      project: work_package2.project)
  end

  describe '#cleanup_action_required_before_destructing?' do
    describe 'w/ the work package having a time entry' do
      before do
        work_package
        time_entry
      end

      it 'should be true' do
        expect(WorkPackage.cleanup_action_required_before_destructing?(work_package)).to be_truthy
      end
    end

    describe 'w/ two work packages having a time entry' do
      before do
        work_package
        time_entry
        time_entry2
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
        time_entry
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
      work_package

      time_entry
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
        let(:action) do
          WorkPackage.cleanup_associated_before_destructing_if_required(work_package,
                                                                        user,
                                                                        action: 'reassign',
                                                                        reassign_to_id: work_package2.id)
        end

        before do
          work_package2
          role2.add_permission! :edit_time_entries
          member2
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
        let(:action) do
          WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                        user,
                                                                        action: 'reassign',
                                                                        reassign_to_id: work_package2.id)
        end

        before do
          work_package2
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
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: 'reassign',
                                                                      reassign_to_id: work_package2.id)
      end

      before do
        work_package2
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
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: 'reassign',
                                                                      reassign_to_id: 0)
      end

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

        expect(work_package.errors[:base])
          .to eq([I18n.t(:'activerecord.errors.models.work_package.is_not_a_valid_target_for_time_entries', id: 0)])
      end
    end

    describe 'w/ "reassign" as action
              w/o providing a reassignment id' do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: 'reassign')
      end

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

        expect(work_package.errors[:base])
          .to eq([I18n.t(:'activerecord.errors.models.work_package.is_not_a_valid_target_for_time_entries', id: nil)])
      end
    end

    describe 'w/ an invalid option' do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      action: 'bogus')
      end

      it 'should return false' do
        expect(action).to be_falsey
      end
    end

    describe 'w/ nil as invalid option' do
      let(:action) do
        WorkPackage.cleanup_associated_before_destructing_if_required([work_package],
                                                                      user,
                                                                      nil)
      end

      it 'should return false' do
        expect(action).to be_falsey
      end
    end
  end
end
