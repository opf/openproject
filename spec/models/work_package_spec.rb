#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe WorkPackage, type: :model do
  let(:stub_work_package) { build_stubbed(:work_package) }
  let(:stub_version) { build_stubbed(:version) }
  let(:stub_project) { build_stubbed(:project) }
  let(:user) { create(:user) }

  let(:type) { create(:type_standard) }
  let(:project) { create(:project, types: [type]) }
  let(:status) { create(:status) }
  let(:priority) { create(:priority) }
  let(:work_package) do
    WorkPackage.new.tap do |w|
      w.attributes = { project_id: project.id,
                       type_id: type.id,
                       author_id: user.id,
                       status_id: status.id,
                       priority: priority,
                       subject: 'test_create',
                       description: 'WorkPackage#create',
                       estimated_hours: '1:30' }
    end
  end

  describe '.new' do
    context 'type' do
      let(:type2) { create(:type) }
      let(:project) { create(:project, types: [type, type2]) }

      before do
        project # loads types as well
      end

      context 'no project chosen' do
        it 'has no type set if no project was chosen' do
          expect(WorkPackage.new.type)
            .to be_nil
        end
      end

      context 'project chosen' do
        it 'has the provided type if one is provided' do
          expect(WorkPackage.new(project: project, type: type2).type)
            .to eql type2
        end
      end
    end
  end

  describe 'create' do
    describe '#save' do
      subject { work_package.save }

      it { is_expected.to be_truthy }
    end

    describe '#estimated_hours' do
      before do
        work_package.save!
        work_package.reload
      end

      subject { work_package.estimated_hours }

      it { is_expected.to eq(1.5) }
    end

    describe 'minimal' do
      let(:work_package_minimal) do
        WorkPackage.new.tap do |w|
          w.attributes = { project_id: project.id,
                           type_id: type.id,
                           author_id: user.id,
                           status_id: status.id,
                           priority: priority,
                           subject: 'test_create' }
        end
      end

      context 'save' do
        subject { work_package_minimal.save }

        it { is_expected.to be_truthy }
      end

      context 'description' do
        before do
          work_package_minimal.save!
          work_package_minimal.reload
        end

        subject { work_package_minimal.description }

        it { is_expected.to be_nil }
      end
    end

    describe '#assigned_to' do
      context 'group_assignment' do
        let(:group) { create(:group) }

        subject do
          create(:work_package,
                            assigned_to: group).assigned_to
        end

        it { is_expected.to eq(group) }
      end
    end
  end

  describe '#category' do
    let(:user_2) { create(:user, member_in_project: project) }
    let(:category) do
      create(:category,
                        project: project,
                        assigned_to: user_2)
    end

    before do
      work_package.attributes = { category_id: category.id }
      work_package.save!
    end

    subject { work_package.assigned_to }

    it { is_expected.to eq(category.assigned_to) }
  end

  describe 'responsible' do
    let(:group) { create(:group) }
    let!(:member) do
      create(:member,
                        principal: group,
                        project: work_package.project,
                        roles: [create(:role)])
    end

    shared_context 'assign group as responsible' do
      before { work_package.responsible = group }
    end

    subject { work_package.valid? }

    context 'with group assigned' do
      include_context 'assign group as responsible'

      it { is_expected.to be_truthy }
    end
  end

  describe '#assignable_versions' do
    let(:stub_version2) { build_stubbed(:version) }
    def stub_shared_versions(v = nil)
      versions = v ? [v] : []

      allow(stub_work_package.project).to receive(:assignable_versions).and_return(versions)
    end

    it "should return all the project's shared versions" do
      stub_shared_versions(stub_version)

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    it 'should return the former version if the version changed' do
      stub_shared_versions

      stub_work_package.version = stub_version2

      allow(stub_work_package).to receive(:version_id_changed?).and_return true
      allow(stub_work_package).to receive(:version_id_was).and_return(stub_version.id)
      allow(Version).to receive(:find_by).with(id: stub_version.id).and_return(stub_version)

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    it 'should return the current version if the version did not change' do
      stub_shared_versions

      stub_work_package.version = stub_version

      allow(stub_work_package).to receive(:version_id_changed?).and_return false

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end
  end

  describe '#assignable_versions' do
    let!(:work_package) do
      wp = create(:work_package,
                             project: project,
                             version: version_current)
      # remove changes to version factored into
      # assignable_versions calculation
      wp.reload
      wp
    end
    let!(:version_current) do
      create(:version,
                        status: 'closed',
                        project: project)
    end
    let!(:version_open) do
      create(:version,
                        status: 'open',
                        project: project)
    end
    let!(:version_locked) do
      create(:version,
                        status: 'locked',
                        project: project)
    end
    let!(:version_closed) do
      create(:version,
                        status: 'closed',
                        project: project)
    end
    let!(:version_other_project) do
      create(:version,
                        status: 'open')
    end

    it 'returns all open versions of the project' do
      expect(work_package.assignable_versions)
        .to match_array [version_current, version_open]
    end
  end

  describe '#destroy' do
    let(:time_entry_1) do
      create(:time_entry,
                        project: project,
                        work_package: work_package)
    end
    let(:time_entry_2) do
      create(:time_entry,
                        project: project,
                        work_package: work_package)
    end

    before do
      time_entry_1
      time_entry_2

      work_package.destroy
    end

    context 'work package' do
      subject { WorkPackage.find_by(id: work_package.id) }

      it { is_expected.to be_nil }
    end

    context 'time entries' do
      subject { TimeEntry.find_by(work_package_id: work_package.id) }

      it { is_expected.to be_nil }
    end
  end

  describe '#done_ratio' do
    let(:status_new) do
      create(:status,
                        name: 'New',
                        is_default: true,
                        is_closed: false,
                        default_done_ratio: 50)
    end
    let(:status_assigned) do
      create(:status,
                        name: 'Assigned',
                        is_default: true,
                        is_closed: false,
                        default_done_ratio: 0)
    end
    let(:work_package_1) do
      create(:work_package,
                        status: status_new)
    end
    let(:work_package_2) do
      create(:work_package,
                        project: work_package_1.project,
                        status: status_assigned,
                        done_ratio: 30)
    end

    before { work_package_2 }

    describe '#value' do
      context 'work package field' do
        before { allow(Setting).to receive(:work_package_done_ratio).and_return 'field' }

        context 'work package 1' do
          subject { work_package_1.done_ratio }

          it { is_expected.to eq(0) }
        end

        context 'work package 2' do
          subject { work_package_2.done_ratio }

          it { is_expected.to eq(30) }
        end
      end

      context 'work package status' do
        before { allow(Setting).to receive(:work_package_done_ratio).and_return 'status' }

        context 'work package 1' do
          subject { work_package_1.done_ratio }

          it { is_expected.to eq(50) }
        end

        context 'work package 2' do
          subject { work_package_2.done_ratio }

          it { is_expected.to eq(0) }
        end
      end
    end

    describe '#update_done_ratio_from_status' do
      context 'work package field' do
        before do
          allow(Setting).to receive(:work_package_done_ratio).and_return 'field'

          work_package_1.update_done_ratio_from_status
          work_package_2.update_done_ratio_from_status
        end

        it 'does not update the done ratio' do
          expect(work_package_1.done_ratio).to eq(0)
          expect(work_package_2.done_ratio).to eq(30)
        end
      end

      context 'work package status' do
        before do
          allow(Setting).to receive(:work_package_done_ratio).and_return 'status'

          work_package_1.update_done_ratio_from_status
          work_package_2.update_done_ratio_from_status
        end

        it 'updates the done ratio' do
          expect(work_package_1.done_ratio).to eq(50)
          expect(work_package_2.done_ratio).to eq(0)
        end
      end
    end
  end

  describe '#group_by' do
    let(:type_2) { create(:type) }
    let(:priority_2) { create(:priority) }
    let(:project) { create(:project, types: [type, type_2]) }
    let(:version_1) do
      create(:version,
                        project: project)
    end
    let(:version_2) do
      create(:version,
                        project: project)
    end
    let(:category_1) do
      create(:category,
                        project: project)
    end
    let(:category_2) do
      create(:category,
                        project: project)
    end
    let(:user_2) { create(:user) }

    let(:work_package_1) do
      create(:work_package,
                        author: user,
                        assigned_to: user,
                        responsible: user,
                        project: project,
                        type: type,
                        priority: priority,
                        version: version_1,
                        category: category_1)
    end
    let(:work_package_2) do
      create(:work_package,
                        author: user_2,
                        assigned_to: user_2,
                        responsible: user_2,
                        project: project,
                        type: type_2,
                        priority: priority_2,
                        version: version_2,
                        category: category_2)
    end

    before do
      version_1
      version_2
      project.reload
      work_package_1
      work_package_2
    end

    shared_examples_for 'group by' do
      context 'size' do
        subject { groups.size }

        it { is_expected.to eq(2) }
      end

      context 'total' do
        subject { groups.inject(0) { |sum, group| sum + group['total'].to_i } }

        it { is_expected.to eq(2) }
      end
    end

    context 'by type' do
      let(:groups) { WorkPackage.by_type(project) }

      it_behaves_like 'group by'
    end

    context 'by version' do
      let(:groups) { WorkPackage.by_version(project) }

      it_behaves_like 'group by'
    end

    context 'by priority' do
      let(:groups) { WorkPackage.by_priority(project) }

      it_behaves_like 'group by'
    end

    context 'by category' do
      let(:groups) { WorkPackage.by_category(project) }

      it_behaves_like 'group by'
    end

    context 'by assigned to' do
      let(:groups) { WorkPackage.by_assigned_to(project) }

      it_behaves_like 'group by'
    end

    context 'by responsible' do
      let(:groups) { WorkPackage.by_responsible(project) }

      it_behaves_like 'group by'
    end

    context 'by author' do
      let(:groups) { WorkPackage.by_author(project) }

      it_behaves_like 'group by'
    end

    context 'by project' do
      let(:project_2) do
        create(:project,
                          parent: project)
      end
      let(:work_package_3) do
        create(:work_package,
                          project: project_2)
      end

      before { work_package_3 }

      let(:groups) { WorkPackage.by_author(project) }

      it_behaves_like 'group by'
    end
  end

  describe '#recently_updated' do
    let(:work_package_1) { create(:work_package) }
    let(:work_package_2) { create(:work_package) }

    before do
      work_package_1
      work_package_2

      without_timestamping do
        work_package_1.updated_at = 1.minute.ago
        work_package_1.save!
      end
    end

    context 'limit' do
      subject { WorkPackage.recently_updated.limit(1).first }

      it { is_expected.to eq(work_package_2) }
    end
  end

  describe '#on_active_project' do
    let(:project_archived) do
      create(:project,
                        active: false)
    end
    let!(:work_package) { create(:work_package) }
    let(:work_package_in_archived_project) do
      create(:work_package,
                        project: project_archived)
    end

    subject { WorkPackage.on_active_project.length }

    context 'one work package in active projects' do
      it { is_expected.to eq(1) }

      context 'and one work package in archived projects' do
        before { work_package_in_archived_project }

        it { is_expected.to eq(1) }
      end
    end
  end

  describe '#with_author' do
    let(:user) { create(:user) }
    let(:project_archived) do
      create(:project,
                        active: false)
    end
    let!(:work_package) { create(:work_package, author: user) }
    let(:work_package_in_archived_project) do
      create(:work_package,
                        project: project_archived,
                        author: user)
    end

    subject { WorkPackage.with_author(user).length }

    context 'one work package in active projects' do
      it { is_expected.to eq(1) }

      context 'and one work package in archived projects' do
        before { work_package_in_archived_project }

        it { is_expected.to eq(2) }
      end
    end
  end

  describe '#add_time_entry' do
    it 'should return a new time entry' do
      expect(stub_work_package.add_time_entry).to be_a TimeEntry
    end

    it 'should already have the project assigned' do
      stub_work_package.project = stub_project

      expect(stub_work_package.add_time_entry.project).to eq(stub_project)
    end

    it 'should already have the work_package assigned' do
      expect(stub_work_package.add_time_entry.work_package).to eq(stub_work_package)
    end

    it 'should return an usaved entry' do
      expect(stub_work_package.add_time_entry).to be_new_record
    end
  end

  describe '.allowed_target_project_on_move' do
    let(:project) { create(:project) }
    let(:role) { create(:role, permissions: [:move_work_packages]) }
    let(:user) do
      create(:user, member_in_project: project, member_through_role: role)
    end

    context 'when having the move_work_packages permission' do
      it 'returns the project' do
        expect(WorkPackage.allowed_target_projects_on_move(user))
          .to match_array [project]
      end
    end

    context 'when lacking the move_work_packages permission' do
      let(:role) { create(:role, permissions: []) }

      it 'does not return the project' do
        expect(WorkPackage.allowed_target_projects_on_move(user))
          .to be_empty
      end
    end
  end

  describe '.allowed_target_project_on_create' do
    let(:project) { create(:project) }
    let(:role) { create(:role, permissions: [:add_work_packages]) }
    let(:user) do
      create(:user, member_in_project: project, member_through_role: role)
    end

    context 'when having the add_work_packages permission' do
      it 'returns the project' do
        expect(WorkPackage.allowed_target_projects_on_create(user))
          .to match_array [project]
      end
    end

    context 'when lacking the add_work_packages permission' do
      let(:role) { create(:role, permissions: []) }

      it 'does not return the project' do
        expect(WorkPackage.allowed_target_projects_on_create(user))
          .to be_empty
      end
    end
  end

  describe '#duration' do
    let(:instance) { send(subclass) }

    describe "w/ today as start date
              w/ tomorrow as finish date" do
      before do
        work_package.start_date = Date.today
        work_package.due_date = Date.today + 1.day
      end

      it 'should have a duration of two' do
        expect(work_package.duration).to eq(2)
      end
    end

    describe "w/ today as start date
              w/ today as finish date" do
      before do
        work_package.start_date = Date.today
        work_package.due_date = Date.today
      end

      it 'should have a duration of one' do
        expect(work_package.duration).to eq(1)
      end
    end

    describe "w/ today as start date
              w/o a finish date" do
      before do
        work_package.start_date = Date.today
        work_package.due_date = nil
      end

      it 'should have a duration of one' do
        expect(work_package.duration).to eq(1)
      end
    end

    describe "w/o a start date
              w today as finish date" do
      before do
        work_package.start_date = nil
        work_package.due_date = Date.today
      end

      it 'should have a duration of one' do
        expect(work_package.duration).to eq(1)
      end
    end
  end

  describe 'changed_since' do
    let!(:work_package) do
      Timecop.travel(5.hours.ago) do
        create(:work_package)
      end
    end

    describe 'null' do
      subject { WorkPackage.changed_since(nil) }

      it { expect(subject).to match_array([work_package]) }
    end

    describe 'now' do
      subject { WorkPackage.changed_since(DateTime.now) }

      it { expect(subject).to be_empty }
    end

    describe 'work package update' do
      subject { WorkPackage.changed_since(work_package.reload.updated_at) }

      it { expect(subject).to match_array([work_package]) }
    end
  end
end
