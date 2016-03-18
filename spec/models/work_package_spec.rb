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
  let(:stub_work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:stub_version) { FactoryGirl.build_stubbed(:version) }
  let(:stub_project) { FactoryGirl.build_stubbed(:project) }
  let(:work_package) { FactoryGirl.create(:work_package) }
  let(:user) { FactoryGirl.create(:user) }

  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:status) { FactoryGirl.create(:status) }
  let(:priority) { FactoryGirl.create(:priority) }
  let(:work_package) {
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
  }

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
      let(:work_package_minimal) {
        WorkPackage.new.tap do |w|
          w.attributes = { project_id: project.id,
                                 type_id: type.id,
                                 author_id: user.id,
                                 status_id: status.id,
                                 priority: priority,
                                 subject: 'test_create' }
        end
      }

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
        let(:group) { FactoryGirl.create(:group) }

        before do
          allow(Setting).to receive(:work_package_group_assignment).and_return(true)
        end

        subject {
          FactoryGirl.create(:work_package,
                             assigned_to: group).assigned_to
        }

        it { is_expected.to eq(group) }
      end
    end
  end

  describe '#type' do
    context 'disabled type' do
      describe 'allows work package update' do
        before do
          work_package.save!

          project.types.delete work_package.type

          work_package.reload
          work_package.subject = 'New subject'
        end

        subject { work_package.save }

        it { is_expected.to be_truthy }
      end

      describe 'must not be set on work package' do
        before do
          project.types.delete work_package.type
        end

        context 'save' do
          subject { work_package.save }

          it { is_expected.to be_falsey }
        end

        context 'errors' do
          before do work_package.save end

          subject { work_package.errors[:type_id] }

          it { is_expected.not_to be_empty }
        end
      end
    end
  end

  describe '#category' do
    let(:user_2) { FactoryGirl.create(:user, member_in_project: project) }
    let(:category) {
      FactoryGirl.create(:category,
                         project: project,
                         assigned_to: user_2)
    }

    before do
      work_package.attributes = { category_id: category.id }
      work_package.save!
    end

    subject { work_package.assigned_to }

    it { is_expected.to eq(category.assigned_to) }
  end

  describe '#assignable_assignees' do
    let(:value) { double('value') }

    before do
      allow(stub_work_package.project).to receive(:possible_assignees).and_return(value)
    end

    subject { stub_work_package.assignable_assignees }

    it 'calls project#possible_assignees and returns the value' do
      is_expected.to eql(value)
    end
  end

  describe '#assignable_responsibles' do
    let(:value) { double('value') }

    before do
      allow(stub_work_package.project).to receive(:possible_responsibles).and_return(value)
    end

    subject { stub_work_package.assignable_responsibles }

    it 'calls project#possible_responsibles and returns the value' do
      is_expected.to eql(value)
    end
  end

  describe 'responsible' do
    let(:group) { FactoryGirl.create(:group) }

    before do work_package.project.add_member! group, FactoryGirl.create(:role) end

    shared_context 'assign group as responsible' do
      before { work_package.responsible = group }
    end

    subject { work_package.valid? }

    context 'with assignable groups' do
      before do allow(Setting).to receive(:work_package_group_assignment?).and_return(true) end

      include_context 'assign group as responsible'

      it { is_expected.to be_truthy }
    end
  end

  describe '#assignable_versions' do
    let(:stub_version2) { FactoryGirl.build_stubbed(:version) }
    def stub_shared_versions(v = nil)
      versions = v ? [v] : []

      allow(stub_work_package.project).to receive(:assignable_versions).and_return(versions)
    end

    it "should return all the project's shared versions" do
      stub_shared_versions(stub_version)

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    it 'should return the former fixed_version if the version changed' do
      stub_shared_versions

      stub_work_package.fixed_version = stub_version2

      allow(stub_work_package).to receive(:fixed_version_id_changed?).and_return true
      allow(stub_work_package).to receive(:fixed_version_id_was).and_return(stub_version.id)
      allow(Version).to receive(:find_by).with(id: stub_version.id).and_return(stub_version)

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end

    it 'should return the current fixed_version if the versiondid not change' do
      stub_shared_versions

      stub_work_package.fixed_version = stub_version

      allow(stub_work_package).to receive(:fixed_version_id_changed?).and_return false

      expect(stub_work_package.assignable_versions).to eq([stub_version])
    end
  end

  describe '#assignable_versions' do
    let(:work_package) {
      FactoryGirl.build(:work_package,
                        project: project,
                        fixed_version: version)
    }
    let(:version_open) {
      FactoryGirl.create(:version,
                         status: 'open',
                         project: project)
    }
    let(:version_locked) {
      FactoryGirl.create(:version,
                         status: 'locked',
                         project: project)
    }
    let(:version_closed) {
      FactoryGirl.create(:version,
                         status: 'closed',
                         project: project)
    }

    describe '#assignment' do
      context 'open version' do
        let(:version) { version_open }

        subject { work_package.assignable_versions.map(&:status).uniq }

        it { is_expected.to include('open') }
      end

      shared_examples_for 'invalid version' do
        before do work_package.save end

        subject { work_package.errors[:fixed_version_id] }

        it { is_expected.not_to be_empty }
      end

      context 'closed version' do
        let(:version) { version_closed }

        it_behaves_like 'invalid version'
      end

      context 'locked version' do
        let(:version) { version_locked }

        it_behaves_like 'invalid version'
      end

      context 'open version' do
        let(:version) { version_open }

        before do work_package.save end

        it { is_expected.to be_truthy }
      end
    end

    describe 'work package update' do
      let(:status_closed) {
        FactoryGirl.create(:status,
                           is_closed: true)
      }
      let(:status_open) {
        FactoryGirl.create(:status,
                           is_closed: false)
      }

      context 'closed version' do
        let(:version) {
          FactoryGirl.create(:version,
                             status: 'open',
                             project: project)
        }

        before do
          version_open

          work_package.status = status_closed
          work_package.save!
        end

        shared_context 'in closed version' do
          before do
            version.status = 'closed'
            version.save!
          end
        end

        context 'attribute update' do
          include_context 'in closed version'

          before do work_package.subject = 'Subject changed' end

          subject { work_package.save }

          it { is_expected.to be_truthy }
        end

        context 'status changed' do
          let!(:workflow) {
            FactoryGirl.create(:workflow,
                               old_status: status_closed,
                               new_status: status_open,
                               type_id: work_package.type_id)
          }
          let(:user) { FactoryGirl.create(:user) }
          let!(:membership) {
            FactoryGirl.create(:member,
                               user: user,
                               project: work_package.project,
                               roles: [workflow.role])
          }

          before do login_as(user) end

          shared_context 'in locked version' do
            before do
              version.status = 'locked'
              version.save!
            end
          end

          shared_examples_for 'save with open version' do
            before do
              work_package.status = status_open
              work_package.fixed_version = version_open
            end

            subject { work_package.save }

            it { is_expected.to be_truthy }
          end

          context 'in closed version' do
            include_context 'in closed version'

            before do
              work_package.status = status_open
              work_package.save
            end

            subject { work_package.errors[:base] }

            it { is_expected.not_to be_empty }
          end

          context 'from closed version' do
            include_context 'in closed version'

            it_behaves_like 'save with open version'
          end

          context 'from locked version' do
            include_context 'in locked version'

            it_behaves_like 'save with open version'
          end
        end
      end
    end
  end

  describe '#copy_from' do
    let(:type) { FactoryGirl.create(:type_standard) }
    let(:project) { FactoryGirl.create(:project, types: [type]) }
    let(:custom_field) {
      FactoryGirl.create(:work_package_custom_field,
                         name: 'Database',
                         field_format: 'list',
                         possible_values: ['MySQL', 'PostgreSQL', 'Oracle'],
                         is_required: true)
    }

    let(:source) { FactoryGirl.build(:work_package) }
    let(:sink) { FactoryGirl.build(:work_package) }

    before do
      def self.change_custom_field_value(work_package, value)
        work_package.custom_field_values = { custom_field.id => value } unless value.nil?
        work_package.save
      end
    end

    before do
      project.work_package_custom_fields << custom_field
      type.custom_fields << custom_field

      source.save
    end

    before do
      source.project_id = project.id
      change_custom_field_value(source, 'MySQL')
    end

    shared_examples_for 'work package copy' do
      context 'subject' do
        subject { sink.subject }

        it { is_expected.to eq(source.subject) }
      end

      context 'type' do
        subject { sink.type }

        it { is_expected.to eq(source.type) }
      end

      context 'status' do
        subject { sink.status }

        it { is_expected.to eq(source.status) }
      end

      context 'project' do
        subject { sink.project_id }

        it { is_expected.to eq(project_id) }
      end

      context 'watchers' do
        subject { sink.watchers.map(&:user_id) }

        it do
          is_expected.to match_array(source.watchers.map(&:user_id))
          sink.watchers.each { |w| expect(w).to be_valid }
        end
      end
    end

    shared_examples_for 'work package copy with custom field' do
      it_behaves_like 'work package copy'

      context 'custom_field' do
        subject { sink.custom_value_for(custom_field.id).value }

        it { is_expected.to eq('MySQL') }
      end
    end

    context 'with project' do
      let(:project_id) { source.project_id }

      describe 'should copy project' do

        before { sink.copy_from(source) }

        it_behaves_like 'work package copy with custom field'
      end

      describe 'should not copy excluded project' do
        let(:project_id) { sink.project_id }

        before { sink.copy_from(source, exclude: [:project_id]) }

        it_behaves_like 'work package copy'
      end

      describe 'should copy over watchers' do
        let(:project_id) { sink.project_id }
        let(:stub_user) { FactoryGirl.create(:user, member_in_project: project) }

        before do
          source.watchers.build(user: stub_user, watchable: source)

          sink.copy_from(source)
        end

        it_behaves_like 'work package copy'
      end
    end
  end

  describe '#destroy' do
    let(:time_entry_1) {
      FactoryGirl.create(:time_entry,
                         project: project,
                         work_package: work_package)
    }
    let(:time_entry_2) {
      FactoryGirl.create(:time_entry,
                         project: project,
                         work_package: work_package)
    }

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
    let(:status_new) {
      FactoryGirl.create(:status,
                         name: 'New',
                         is_default: true,
                         is_closed: false,
                         default_done_ratio: 50)
    }
    let(:status_assigned) {
      FactoryGirl.create(:status,
                         name: 'Assigned',
                         is_default: true,
                         is_closed: false,
                         default_done_ratio: 0)
    }
    let(:work_package_1) {
      FactoryGirl.create(:work_package,
                         status: status_new)
    }
    let(:work_package_2) {
      FactoryGirl.create(:work_package,
                         project: work_package_1.project,
                         status: status_assigned,
                         done_ratio: 30)
    }

    before do work_package_2 end

    describe '#value' do
      context 'work package field' do
        before do allow(Setting).to receive(:work_package_done_ratio).and_return 'field' end

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
        before do allow(Setting).to receive(:work_package_done_ratio).and_return 'status' end

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
    let(:type_2) { FactoryGirl.create(:type) }
    let(:priority_2) { FactoryGirl.create(:priority) }
    let(:project) { FactoryGirl.create(:project, types: [type, type_2]) }
    let(:version_1) {
      FactoryGirl.create(:version,
                         project: project)
    }
    let(:version_2) {
      FactoryGirl.create(:version,
                         project: project)
    }
    let(:category_1) {
      FactoryGirl.create(:category,
                         project: project)
    }
    let(:category_2) {
      FactoryGirl.create(:category,
                         project: project)
    }
    let(:user_2) { FactoryGirl.create(:user) }

    let(:work_package_1) {
      FactoryGirl.create(:work_package,
                         author: user,
                         assigned_to: user,
                         responsible: user,
                         project: project,
                         type: type,
                         priority: priority,
                         fixed_version: version_1,
                         category: category_1)
    }
    let(:work_package_2) {
      FactoryGirl.create(:work_package,
                         author: user_2,
                         assigned_to: user_2,
                         responsible: user_2,
                         project: project,
                         type: type_2,
                         priority: priority_2,
                         fixed_version: version_2,
                         category: category_2)
    }

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
      let(:project_2) {
        FactoryGirl.create(:project,
                           parent: project)
      }
      let(:work_package_3) {
        FactoryGirl.create(:work_package,
                           project: project_2)
      }

      before do work_package_3 end

      let(:groups) { WorkPackage.by_author(project) }

      it_behaves_like 'group by'
    end
  end

  describe '#recently_updated' do
    let(:work_package_1) { FactoryGirl.create(:work_package) }
    let(:work_package_2) { FactoryGirl.create(:work_package) }

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
    let(:project_archived) {
      FactoryGirl.create(:project,
                         status: Project::STATUS_ARCHIVED)
    }
    let!(:work_package) { FactoryGirl.create(:work_package) }
    let(:work_package_in_archived_project) {
      FactoryGirl.create(:work_package,
                         project: project_archived)
    }

    subject { WorkPackage.on_active_project.length }

    context 'one work package in active projects' do
      it { is_expected.to eq(1) }

      context 'and one work package in archived projects' do
        before do work_package_in_archived_project end

        it { is_expected.to eq(1) }
      end
    end
  end

  describe '#with_author' do
    let(:user) { FactoryGirl.create(:user) }
    let(:project_archived) {
      FactoryGirl.create(:project,
                         status: Project::STATUS_ARCHIVED)
    }
    let!(:work_package) { FactoryGirl.create(:work_package, author: user) }
    let(:work_package_in_archived_project) {
      FactoryGirl.create(:work_package,
                         project: project_archived,
                         author: user)
    }

    subject { WorkPackage.with_author(user).length }

    context 'one work package in active projects' do
      it { is_expected.to eq(1) }

      context 'and one work package in archived projects' do
        before do work_package_in_archived_project end

        it { is_expected.to eq(2) }
      end
    end
  end

  describe '#recipients' do
    let(:project) { FactoryGirl.create(:project) }
    let(:member) { FactoryGirl.create(:user) }
    let(:author) { FactoryGirl.create(:user) }
    let(:assignee) { FactoryGirl.create(:user) }
    let(:role) {
      FactoryGirl.create(:role,
                         permissions: [:view_work_packages])
    }
    let(:project_member) {
      FactoryGirl.create(:member,
                         user: member,
                         project: project,
                         roles: [role])
    }
    let(:project_author) {
      FactoryGirl.create(:member,
                         user: author,
                         project: project,
                         roles: [role])
    }
    let(:project_assignee) {
      FactoryGirl.create(:member,
                         user: assignee,
                         project: project,
                         roles: [role])
    }
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         author: author,
                         assigned_to: assignee,
                         project: project)
    }

    shared_examples_for 'includes expected users' do
      subject { work_package.recipients }

      it { is_expected.to include(*expected_users) }
    end

    shared_examples_for 'includes not expected users' do
      subject { work_package.recipients }

      it { is_expected.not_to include(*expected_users) }
    end

    describe 'includes project recipients' do
      before do project_member end

      context 'pre-condition' do
        subject { project.recipients }

        it { is_expected.not_to be_empty }
      end

      let(:expected_users) { project.recipients }

      it_behaves_like 'includes expected users'
    end

    describe 'includes work package author' do
      before do project_author end

      context 'pre-condition' do
        subject { work_package.author }

        it { is_expected.not_to be_nil }
      end

      let(:expected_users) { work_package.author }

      it_behaves_like 'includes expected users'
    end

    describe 'includes work package assignee' do
      before do project_assignee end

      context 'pre-condition' do
        subject { work_package.assigned_to }

        it { is_expected.not_to be_nil }
      end

      let(:expected_users) { work_package.assigned_to }

      it_behaves_like 'includes expected users'
    end

    context 'mail notification settings' do
      before do
        project_author
        project_assignee
      end

      describe '#none' do
        before do author.update_attribute(:mail_notification, :none) end

        let(:expected_users) { work_package.author.mail }

        it_behaves_like 'includes not expected users'
      end

      describe '#only_assigned' do
        before do author.update_attribute(:mail_notification, :only_assigned) end

        let(:expected_users) { work_package.author.mail }

        it_behaves_like 'includes not expected users'
      end

      describe '#only_assigned' do
        before do assignee.update_attribute(:mail_notification, :only_owner) end

        let(:expected_users) { work_package.assigned_to.mail }

        it_behaves_like 'includes not expected users'
      end
    end
  end

  describe '#new_statuses_allowed_to' do
    let(:role) { FactoryGirl.create(:role) }
    let(:type) { FactoryGirl.create(:type) }
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    let(:statuses) { (1..5).map { |_i| FactoryGirl.create(:status) } }
    let(:priority) { FactoryGirl.create :priority, is_default: true }
    let(:status) { statuses[0] }
    let(:project) do
      FactoryGirl.create(:project, types: [type]).tap { |p| p.add_member(user, role).save }
    end
    let(:workflow_a) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[1].id,
                                    author: false,
                                    assignee: false)
    }
    let(:workflow_b) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[2].id,
                                    author: true,
                                    assignee: false)
    }
    let(:workflow_c) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[3].id,
                                    author: false,
                                    assignee: true)
    }
    let(:workflow_d) {
      FactoryGirl.create(:workflow, role_id: role.id,
                                    type_id: type.id,
                                    old_status_id: statuses[0].id,
                                    new_status_id: statuses[4].id,
                                    author: true,
                                    assignee: true)
    }
    let(:workflows) { [workflow_a, workflow_b, workflow_c, workflow_d] }

    it 'should respect workflows w/o author and w/o assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, false, false))
        .to match_array([statuses[1]])
      expect(status.find_new_statuses_allowed_to([role], type, false, false))
        .to match_array([statuses[1]])
    end

    it 'should respect workflows w/ author and w/o assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
      expect(status.find_new_statuses_allowed_to([role], type, true, false))
        .to match_array([statuses[1], statuses[2]])
    end

    it 'should respect workflows w/o author and w/ assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
      expect(status.find_new_statuses_allowed_to([role], type, false, true))
        .to match_array([statuses[1], statuses[3]])
    end

    it 'should respect workflows w/ author and w/ assignee' do
      workflows
      expect(status.new_statuses_allowed_to([role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3], statuses[4]])
      expect(status.find_new_statuses_allowed_to([role], type, true, true))
        .to match_array([statuses[1], statuses[2], statuses[3], statuses[4]])
    end

    it 'should respect workflows w/o author and w/o assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        priority: priority,
                                        project: project)
      expect(work_package.new_statuses_allowed_to(user)).to match_array([statuses[0], statuses[1]])
    end

    it 'should respect workflows w/ author and w/o assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        priority: priority,
                                        project: project,
                                        author: user)
      expect(work_package.new_statuses_allowed_to(user))
        .to match_array([statuses[0], statuses[1], statuses[2]])
    end

    it 'should respect workflows w/o author and w/ assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        subject: 'test',
                                        priority: priority,
                                        project: project,
                                        assigned_to: user,
                                        author: other_user)
      expect(work_package.new_statuses_allowed_to(user))
        .to match_array([statuses[0], statuses[1], statuses[3]])
    end

    it 'should respect workflows w/ author and w/ assignee on work packages' do
      workflows
      work_package = WorkPackage.create(type_id: type.id,
                                        status: status,
                                        subject: 'test',
                                        priority: priority,
                                        project: project,
                                        author: user,
                                        assigned_to: user)
      expect(work_package.new_statuses_allowed_to(user))
        .to match_array([statuses[0], statuses[1], statuses[2], statuses[3], statuses[4]])
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

  describe '#move_time_entries' do
    let(:time_entry) do
      FactoryGirl.build(:time_entry,
                        work_package: work_package,
                        project: work_package.project)
    end
    let(:target_project) { FactoryGirl.build(:project) }

    before do
      time_entry.save!
      target_project.save!
    end

    it 'moves the time_entry to the defined project' do
      work_package.move_time_entries(target_project)

      time_entry.reload

      expect(time_entry.project).to eql(target_project)
    end
  end

  describe '#allowed_target_projects_on_move' do
    let(:project) { FactoryGirl.create :project }

    subject { WorkPackage.allowed_target_projects_on_move(user) }

    before do
      allow(User).to receive(:current).and_return user
      project
    end

    shared_examples_for 'has the permission to see projects' do
      it 'sees the project' do
        is_expected.to match_array [project]
      end

      it 'does not see the archived project' do
        project.update_attribute(:status, Project::STATUS_ARCHIVED)

        is_expected.to match_array []
      end

      it 'does not see the project having the work package module disabled' do
        enabled_modules = project.enabled_module_names.delete(:work_package_tracking)
        project.enabled_module_names = enabled_modules
        project.save!

        is_expected.to match_array []
      end
    end

    shared_examples_for 'lacks the permission to see projects' do
      it 'does not see the project' do
        is_expected.to match_array []
      end
    end

    context 'admin user' do
      let(:admin_user) { FactoryGirl.create :admin }

      it_behaves_like 'has the permission to see projects' do
        let(:user) { admin_user }
      end
    end

    context 'non admin user' do
      let(:role) { FactoryGirl.build(:role, permissions: user_in_project_permissions) }
      let(:user_in_project_permissions) { [:move_work_packages] }
      let(:user_in_project) {
        FactoryGirl.build :user,
                          member_in_project: project,
                          member_through_role: role
      }

      it_behaves_like 'has the permission to see projects' do
        before do
          user_in_project.save!
        end

        let(:user) { user_in_project }
      end

      it_behaves_like 'lacks the permission to see projects' do
        let(:user_in_project_permissions) { [] }

        before do
          user_in_project.save!
        end

        let(:user) { user_in_project }
      end
    end

    context 'non member user' do
      it_behaves_like 'lacks the permission to see projects' do
        before do
          project.update_attribute(:is_public, true)
          FactoryGirl.create(:non_member, permissions: [])
        end

        let(:user) { FactoryGirl.create(:user) }
      end

      it_behaves_like 'has the permission to see projects' do
        before do
          project.update_attribute(:is_public, true)
          FactoryGirl.create(:non_member, permissions: [:move_work_packages])
        end

        let(:user) { FactoryGirl.create(:user) }
      end
    end

    context 'anonymous user' do
      it_behaves_like 'lacks the permission to see projects' do
        before do
          project.update_attribute(:is_public, true)
        end

        let(:user) { FactoryGirl.create(:anonymous) }
      end
    end
  end

  describe '#duration' do
    # TODO remove once only WP exists
    [:work_package].each do |subclass|
      describe "for #{subclass}" do
        let(:instance) { send(subclass) }

        describe "w/ today as start date
                  w/ tomorrow as due date" do
          before do
            instance.start_date = Date.today
            instance.due_date = Date.today + 1.day
          end

          it 'should have a duration of two' do
            expect(instance.duration).to eq(2)
          end
        end

        describe "w/ today as start date
                  w/ today as due date" do
          before do
            instance.start_date = Date.today
            instance.due_date = Date.today
          end

          it 'should have a duration of one' do
            expect(instance.duration).to eq(1)
          end
        end

        describe "w/ today as start date
                  w/o a due date" do
          before do
            instance.start_date = Date.today
            instance.due_date = nil
          end

          it 'should have a duration of one' do
            expect(instance.duration).to eq(1)
          end
        end

        describe "w/o a start date
                  w today as due date" do
          before do
            instance.start_date = nil
            instance.due_date = Date.today
          end

          it 'should have a duration of one' do
            expect(instance.duration).to eq(1)
          end
        end

        describe "w/o a start date
                  w an erroneous due date" do
          before do
            instance.start_date = nil
            instance.due_date = '856742858941748214577'
            instance.valid?
          end

          it 'should have a validation error' do
            expect(instance.errors[:due_date].size).to eq(1)
          end
        end
      end
    end
  end

  describe 'Acts as journalized' do
    before(:each) do
      Status.delete_all
      IssuePriority.delete_all

      @type ||= FactoryGirl.create(:type_feature)

      @status_resolved ||= FactoryGirl.create(:status, name: 'Resolved', is_default: false)
      @status_open ||= FactoryGirl.create(:status, name: 'Open', is_default: true)
      @status_rejected ||= FactoryGirl.create(:status, name: 'Rejected', is_default: false)

      role = FactoryGirl.create(:role)
      FactoryGirl.create(:workflow,
                         old_status: @status_open,
                         new_status: @status_resolved,
                         role: role,
                         type_id: @type.id)
      FactoryGirl.create(:workflow,
                         old_status: @status_resolved,
                         new_status: @status_rejected,
                         role: role,
                         type_id: @type.id)

      @priority_low ||= FactoryGirl.create(:priority_low, is_default: true)
      @priority_high ||= FactoryGirl.create(:priority_high)
      @project ||= FactoryGirl.create(:project_with_types)

      @current = FactoryGirl.create(:user, login: 'user1', mail: 'user1@users.com')
      allow(User).to receive(:current).and_return(@current)
      @project.add_member!(@current, role)

      @user2 = FactoryGirl.create(:user, login: 'user2', mail: 'user2@users.com')

      @issue ||= FactoryGirl.create(:work_package,
                                    project: @project,
                                    status: @status_open,
                                    type: @type,
                                    author: @current)
    end

    describe 'ignore blank to blank transitions' do
      it 'should not include the "nil to empty string"-transition' do
        @issue.description = nil
        @issue.save!

        @issue.description = ''
        expect(@issue.send(:incremental_journal_changes)).to be_empty
      end
    end

    describe 'Acts as journalized recreate initial journal' do
      it 'should not include certain attributes' do
        recreated_journal = @issue.recreate_initial_journal!

        expect(recreated_journal.details.include?('rgt')).to eq(false)
        expect(recreated_journal.details.include?('lft')).to eq(false)
        expect(recreated_journal.details.include?('lock_version')).to eq(false)
        expect(recreated_journal.details.include?('updated_at')).to eq(false)
        expect(recreated_journal.details.include?('updated_on')).to eq(false)
        expect(recreated_journal.details.include?('id')).to eq(false)
        expect(recreated_journal.details.include?('type')).to eq(false)
        expect(recreated_journal.details.include?('root_id')).to eq(false)
      end

      it 'should not include useless transitions' do
        recreated_journal = @issue.recreate_initial_journal!

        recreated_journal.details.values.each do |change|
          expect(change.first).not_to eq(change.last)
        end
      end

      it 'should not be different from the initially created journal by aaj' do
        # Creating four journals total
        @issue.status = @status_resolved
        @issue.assigned_to = @user2
        @issue.save!
        @issue.reload

        @issue.priority = @priority_high
        @issue.save!
        @issue.reload

        @issue.status = @status_rejected
        @issue.priority = @priority_low
        @issue.estimated_hours = 3
        @issue.save!

        initial_journal = @issue.journals.first
        recreated_journal = @issue.recreate_initial_journal!

        expect(initial_journal).to be_identical(recreated_journal)
      end

      it 'should not validate with oddly set estimated_hours' do
        @issue.estimated_hours = 'this should not work'
        expect(@issue).not_to be_valid
      end

      it 'should validate with sane estimated_hours' do
        @issue.estimated_hours = '13h'
        expect(@issue).to be_valid
      end
    end
  end

  describe '#inherit_done_ratio_from_leaves' do
    describe 'with done ratio disabled' do
      let(:project) { FactoryGirl.create(:project) }
      let(:work_package) { FactoryGirl.create(:work_package, project: project) }
      let(:child) {
        FactoryGirl.create(:work_package, parent: work_package,
                                          project: project)
      }
      let(:closed_status) { FactoryGirl.create(:closed_status) }
      let!(:workflow) {
        FactoryGirl.create(:workflow,
                           old_status: child.status,
                           new_status: closed_status,
                           type_id: child.type_id)
      }
      let(:user) {
        FactoryGirl.create(:user,
                           member_in_project: project,
                           member_through_role: workflow.role)
      }

      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')

        login_as(user)
      end

      it 'should not update the work package done_ratio' do
        expect(work_package.done_ratio).to eq(0)

        child.status = closed_status
        child.save!

        work_package.reload
        expect(work_package.done_ratio).to eq(0)
      end
    end
  end

  describe 'parent work package' do
    describe 'with parent_id for a not existing work package' do
      let(:project) { FactoryGirl.create(:project) }
      let(:invalid_work_package) do
        FactoryGirl.build(:work_package, project: project, parent_id: 1)
      end

      it 'should raise an error' do
        expect(invalid_work_package).not_to be_valid
      end
    end
  end

  describe 'custom fields' do
    let(:included_cf) { FactoryGirl.build(:work_package_custom_field) }
    let(:other_cf) { FactoryGirl.build(:work_package_custom_field) }

    before do
      included_cf.save
      other_cf.save

      project.work_package_custom_fields << included_cf
      type.custom_fields << included_cf
    end

    it 'says to respond to valid custom field accessors' do
      expect(work_package.respond_to?(included_cf.accessor_name)).to be_truthy
    end

    it 'really responds to valid custom field accessors' do
      expect(work_package.send(included_cf.accessor_name)).to eql(nil)
    end

    it 'says to not respond to foreign custom field accessors' do
      expect(work_package.respond_to?(other_cf.accessor_name)).to be_falsey
    end

    it 'does really not respond to foreign custom field accessors' do
      expect { work_package.send(other_cf.accessor_name) }.to raise_error(NoMethodError)
    end

    it 'should not duplicate error messages when invalid' do
      cf1 = FactoryGirl.create(:work_package_custom_field, is_required: true)
      cf2 = FactoryGirl.create(:work_package_custom_field, is_required: true)

      # create work_package with one required custom field
      work_package = FactoryGirl.create :work_package
      work_package.project.work_package_custom_fields << cf1
      work_package.type.custom_fields << cf1

      # set that custom field with a value, should be fine
      work_package.custom_field_values = { cf1.id => 'test' }
      work_package.save!
      work_package.reload

      # now give the work_package another required custom field, but don't assign a value
      work_package.project.work_package_custom_fields << cf2
      work_package.type.custom_fields << cf2
      work_package.custom_field_values # #custom_field_values needs to be touched

      # that should not be valid
      expect(work_package).not_to be_valid

      # assert that there is only one error
      expect(work_package.errors.size).to eq 1
      expect(work_package.errors["custom_field_#{cf2.id}"].size).to eq 1
    end
  end

  describe 'changed_since' do
    let!(:work_package) do
      work_package = Timecop.travel(5.hours.ago) {
        wp = FactoryGirl.create(:work_package)
        wp.save!
        wp
      }
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
      subject { WorkPackage.changed_since(work_package.updated_at) }

      it { expect(subject).to match_array([work_package]) }
    end
  end
end
