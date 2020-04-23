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

describe WorkPackages::BaseContract do
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             type: type,
                             done_ratio: 50,
                             estimated_hours: 6.0,
                             project: project)
  end
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:member) do
    u = FactoryBot.build_stubbed(:user)

    allow(u)
      .to receive(:allowed_to?)
      .and_return(false)

    permissions.each do |permission|
      allow(u)
        .to receive(:allowed_to?)
        .with(permission, project, global: project.nil?)
        .and_return(true)
    end

    u
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:current_user) { member }
  let(:permissions) do
    %i(
      view_work_packages
      view_work_package_watchers
      edit_work_packages
      add_work_package_watchers
      delete_work_package_watchers
      manage_work_package_relations
      add_work_package_notes
      assign_versions
    )
  end
  let(:changed_values) { [] }

  subject(:contract) { described_class.new(work_package, current_user) }

  shared_examples_for 'invalid if changed' do |attribute|
    before do
      allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))
    end

    before do
      contract.validate
    end

    context 'has changed' do
      let(:changed_values) { [attribute] }

      it('is invalid') do
        expect(contract.errors.symbols_for(attribute)).to match_array([:error_readonly])
      end
    end

    context 'has not changed' do
      let(:changed_values) { [] }

      it('is valid') { expect(contract.errors).to be_empty }
    end
  end

  shared_examples 'a parent unwritable property' do |attribute|
    before do
      allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))
    end

    context 'is no parent' do
      before do
        allow(work_package)
          .to receive(:leaf?)
          .and_return(true)

        contract.validate
      end

      context 'has not changed' do
        let(:changed_values) { [] }

        it('is valid') { expect(contract.errors).to be_empty }
      end

      context 'has changed' do
        let(:changed_values) { [attribute] }

        it('is valid') { expect(contract.errors).to be_empty }
      end
    end

    context 'is a parent' do
      before do
        allow(work_package)
          .to receive(:leaf?)
          .and_return(false)
        contract.validate
      end

      context 'has not changed' do
        let(:changed_values) { [] }

        it('is valid') { expect(contract.errors).to be_empty }
      end

      context 'has changed' do
        let(:changed_values) { [attribute] }

        it('is invalid (read only)') do
          expect(contract.errors.symbols_for(attribute)).to match_array([:error_readonly])
        end
      end
    end
  end

  describe 'status' do
    context 'on a readonly status' do
      before do
        allow(work_package)
          .to receive(:readonly_status?)
          .and_return true
      end

      it 'only sets status to allowed' do
        expect(contract.writable_attributes).to eq(%w[status status_id])
      end
    end

    context 'work_package has a closed version and status' do
      before do
        version = FactoryBot.build_stubbed(:version, status: 'closed')

        work_package.version = version
        allow(work_package.status)
          .to receive(:is_closed?)
          .and_return(true)
      end

      it 'is not writable' do
        expect(contract.writable?(:status)).to be_falsey
      end

      context 'if we only switched into that status now' do
        before do
          allow(work_package)
            .to receive(:status_id_change)
            .and_return [1, 2]
        end

        it 'is writable' do
          expect(contract.writable?(:status)).to be_truthy
        end
      end
    end

    context 'is an inexistent status' do
      before do
        work_package.status = Status::InexistentStatus.new
      end

      it 'is invalid' do
        contract.validate

        expect(subject.errors.symbols_for(:status))
          .to match_array [:does_not_exist]
      end
    end

    context 'transitions' do
      let(:roles) { [FactoryBot.build_stubbed(:role)] }
      let(:valid_transition_result) { true }
      let(:new_status) { FactoryBot.build_stubbed(:status) }
      let(:from_id) { work_package.status_id }
      let(:to_id) { new_status.id }
      let(:status_change) { work_package.status = new_status }

      before do
        new_statuses_scope = double('new statuses scope')

        allow(Status)
          .to receive(:find_by)
          .with(id: work_package.status_id)
          .and_return(work_package.status)

        # Breaking abstraction here to avoid mocking hell.
        # We might want to extract the assignable_... into separate
        # objects.
        allow(contract)
          .to receive(:new_statuses_allowed_from)
          .with(work_package.status)
          .and_return(new_statuses_scope)

        allow(new_statuses_scope)
          .to receive(:order_by_position)
          .and_return(new_statuses_scope)

        allow(new_statuses_scope)
          .to receive(:exists?)
          .with(new_status.id)
          .and_return(valid_transition_result)

        status_change

        contract.validate
      end

      context 'valid transition' do
        it 'is valid' do
          expect(subject.errors.symbols_for(:status_id))
            .to be_empty
        end
      end

      context 'invalid transition' do
        let(:valid_transition_result) { false }

        it 'is invalid' do
          expect(subject.errors.symbols_for(:status_id))
            .to match_array [:status_transition_invalid]
        end
      end

      context 'status is nil' do
        let(:status_change) { work_package.status = nil }

        it 'is invalid' do
          expect(subject.errors.symbols_for(:status))
            .to match_array [:blank]
        end
      end

      context 'invalid transition but the type changed as well' do
        let(:valid_transition_result) { false }
        let(:status_change) do
          work_package.status = new_status
          work_package.type = FactoryBot.build_stubbed(:type)
        end

        it 'is valid' do
          expect(subject.errors.symbols_for(:status_id))
            .to be_empty
        end
      end
    end
  end

  describe 'estimated hours' do
    let(:estimated_hours) { 1 }

    before do
      work_package.estimated_hours = estimated_hours
    end

    context '> 0' do
      let(:estimated_hours) { 1 }

      it 'is valid' do
        contract.validate

        expect(subject.errors.symbols_for(:estimated_hours))
          .to be_empty
      end
    end

    context '0' do
      let(:estimated_hours) { 0 }

      it 'is valid' do
        contract.validate

        expect(subject.errors.symbols_for(:estimated_hours))
          .to be_empty
      end
    end

    context 'nil' do
      let(:estimated_hours) { nil }

      it 'is valid' do
        contract.validate

        expect(subject.errors.symbols_for(:estimated_hours))
          .to be_empty
      end
    end

    context '< 0' do
      let(:estimated_hours) { -1 }

      it 'is invalid' do
        contract.validate

        expect(subject.errors.symbols_for(:estimated_hours))
          .to match_array [:only_values_greater_or_equal_zeroes_allowed]
      end
    end
  end

  describe 'derived estimated hours' do
    let(:changed_values) { [] }
    let(:attribute) { :derived_estimated_hours }

    before do
      allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))

      contract.validate
    end

    context 'has not changed' do
      let(:changed_values) { [] }

      it('is valid') { expect(contract.errors).to be_empty }
    end

    context 'has changed' do
      let(:changed_values) { [attribute] }

      it('is invalid (read only)') do
        expect(contract.errors.symbols_for(attribute)).to match_array([:error_readonly])
      end
    end
  end

  shared_examples_for 'a date attribute' do |attribute|
    context 'a date' do
      before do
        work_package.send(:"#{attribute}=", Date.today)
        contract.validate
      end

      it 'is valid' do
        expect(subject.errors.symbols_for(attribute))
          .to be_empty
      end
    end

    context 'a string representing a date' do
      before do
        work_package.send(:"#{attribute}=", '01/01/17')
        contract.validate
      end

      it 'is valid' do
        expect(subject.errors.symbols_for(attribute))
          .to be_empty
      end
    end

    context 'not a date' do
      before do
        work_package.send(:"#{attribute}=", 'not a date')
        contract.validate
      end

      it 'is invalid' do
        expect(subject.errors.symbols_for(attribute))
          .to match_array [:not_a_date]
      end
    end
  end

  describe 'start date' do
    it_behaves_like 'a parent unwritable property', :start_date
    it_behaves_like 'a date attribute', :start_date

    context 'before soonest start date of parent' do
      before do
        work_package.parent = FactoryBot.build_stubbed(:work_package)
        allow(work_package)
          .to receive(:soonest_start)
          .and_return(Date.today + 4.days)

        work_package.start_date = Date.today + 2.days
      end

      it 'notes the error' do
        contract.validate

        message = I18n.t('activerecord.errors.models.work_package.attributes.start_date.violates_relationships',
                         soonest_start: Date.today + 4.days)

        expect(contract.errors[:start_date])
          .to match_array [message]
      end
    end
  end

  describe 'finish date' do
    it_behaves_like 'a parent unwritable property', :due_date
    it_behaves_like 'a date attribute', :due_date

    it 'returns an error when trying to set it before the start date' do
      work_package.start_date = Date.today + 2.days
      work_package.due_date = Date.today

      contract.validate

      message = I18n.t('activerecord.errors.messages.greater_than_or_equal_to_start_date')

      expect(contract.errors[:due_date])
        .to include message
    end
  end

  describe 'percentage done' do
    it_behaves_like 'a parent unwritable property', :done_ratio

    context 'done ratio inferred by status' do
      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return('status')
      end

      it_behaves_like 'invalid if changed', :done_ratio
    end

    context 'done ratio disabled' do
      let(:changed_values) { [:done_ratio] }

      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')
      end

      it_behaves_like 'invalid if changed', :done_ratio
    end
  end

  describe 'version' do
    subject(:contract) { described_class.new(work_package, current_user) }

    let(:assignable_version) { FactoryBot.build_stubbed(:version) }
    let(:invalid_version) { FactoryBot.build_stubbed(:version) }

    before do
      allow(work_package)
        .to receive(:assignable_versions)
        .and_return [assignable_version]
    end

    context 'for assignable version' do
      before do
        work_package.version = assignable_version
        subject.validate
      end

      it 'is valid' do
        expect(subject.errors).to be_empty
      end
    end

    context 'for non assignable version' do
      before do
        work_package.version = invalid_version
        subject.validate
      end

      it 'is invalid' do
        expect(subject.errors.symbols_for(:version_id)).to eql [:inclusion]
      end
    end

    context 'for a closed version' do
      let(:assignable_version) { FactoryBot.build_stubbed(:version, status: 'closed') }

      context 'when reopening a work package' do
        before do
          allow(work_package)
            .to receive(:reopened?)
            .and_return(true)

          work_package.version = assignable_version
          subject.validate
        end

        it 'is invalid' do
          expect(subject.errors[:base]).to eql [I18n.t(:error_can_not_reopen_work_package_on_closed_version)]
        end
      end

      context 'when not reopening the work package' do
        before do
          work_package.version = assignable_version
          subject.validate
        end

        it 'is valid' do
          expect(subject.errors).to be_empty
        end
      end
    end
  end

  describe 'parent' do
    let(:child) { FactoryBot.build_stubbed(:stubbed_work_package) }
    let(:parent) { FactoryBot.build_stubbed(:stubbed_work_package) }

    before do
      work_package.parent = parent
    end

    subject do
      contract.validate

      # while we do validate the parent
      # the errors are still put on :base so that the messages can be reused
      contract.errors.symbols_for(:base)
    end

    context 'a relation exists between the parent and its ancestors and the work package and its descendants' do
      let(:parent) { child }

      before do
        from_parent_stub = double('from parent stub')
        allow(Relation)
          .to receive(:from_parent_to_self_and_descendants)
          .with(work_package)
          .and_return(from_parent_stub)

        from_descendants_stub = double('from descendants stub')
        allow(Relation)
          .to receive(:from_self_and_descendants_to_ancestors)
          .with(work_package)
          .and_return(from_descendants_stub)

        allow(from_parent_stub)
          .to receive(:or)
          .with(from_descendants_stub)
          .and_return(from_parent_stub)

        allow(from_parent_stub)
          .to receive_message_chain(:direct, :exists?)
          .and_return(true)
      end

      it 'is invalid' do
        expect(subject.include?(:cant_link_a_work_package_with_a_descendant))
          .to be_truthy
      end
    end
  end

  describe 'type' do
    context 'disabled type' do
      before do
        allow(project)
          .to receive(:types)
          .and_return([])
      end

      describe 'not changing the type' do
        it 'is valid' do
          subject.validate

          expect(subject)
            .to be_valid
        end
      end

      describe 'changing the type' do
        let(:other_type) { FactoryBot.build_stubbed(:type) }

        it 'is invalid' do
          work_package.type = other_type

          subject.validate

          expect(subject.errors.symbols_for(:type_id))
            .to match_array [:inclusion]
        end
      end

      describe 'changing the project (and that one not having the type)' do
        let(:other_project) { FactoryBot.build_stubbed(:project) }

        it 'is invalid' do
          work_package.project = other_project

          subject.validate

          expect(subject.errors.symbols_for(:type_id))
            .to match_array [:inclusion]
        end
      end
    end

    context 'inexistent type' do
      before do
        work_package.type = Type::InexistentType.new

        contract.validate
      end

      it 'is invalid' do
        expect(contract.errors.symbols_for(:type))
          .to match_array [:does_not_exist]
      end
    end
  end

  context 'assigned_to' do
    context 'inexistent user' do
      before do
        work_package.assigned_to = User::InexistentUser.new

        contract.validate
      end

      it 'is invalid' do
        expect(contract.errors.symbols_for(:assigned_to))
          .to match_array [:does_not_exist]
      end
    end
  end

  describe 'category' do
    let(:category) { FactoryBot.build_stubbed(:category) }

    context "one of the project's categories" do
      before do
        allow(project)
          .to receive(:categories)
          .and_return [category]

        work_package.category = category

        contract.validate
      end

      it 'is valid' do
        expect(contract.errors.symbols_for(:category))
          .to be_empty
      end
    end

    context 'empty' do
      before do
        work_package.category = nil

        contract.validate
      end

      it 'is valid' do
        expect(contract.errors.symbols_for(:category))
          .to be_empty
      end
    end

    context 'inexistent category (e.g. removed)' do
      before do
        work_package.category_id = 5

        contract.validate
      end

      it 'is invalid' do
        expect(contract.errors.symbols_for(:category))
          .to match_array [:does_not_exist]
      end
    end

    context 'not of the project' do
      before do
        allow(project)
          .to receive(:categories)
          .and_return []

        work_package.category = category

        contract.validate
      end

      it 'is invalid' do
        expect(contract.errors.symbols_for(:category))
          .to match_array [:only_same_project_categories_allowed]
      end
    end
  end

  describe 'priority' do
    let (:active_priority) { FactoryBot.build_stubbed(:priority) }
    let (:inactive_priority) { FactoryBot.build_stubbed(:priority, active: false) }

    context 'active priority' do
      before do
        work_package.priority = active_priority

        contract.validate
      end

      it 'is valid' do
        expect(contract.errors.symbols_for(:priority_id))
          .to be_empty
      end
    end

    context 'inactive priority' do
      before do
        work_package.priority = inactive_priority

        contract.validate
      end

      it 'is invalid' do
        expect(contract.errors.symbols_for(:priority_id))
          .to match_array [:only_active_priorities_allowed]
      end
    end

    context 'inactive priority but priority not changed' do
      before do
        work_package.priority = inactive_priority
        work_package.clear_changes_information

        contract.validate
      end

      it 'is valid' do
        expect(contract.errors.symbols_for(:priority_id))
          .to be_empty
      end
    end

    context 'inexistent priority' do
      before do
        work_package.priority = Priority::InexistentPriority.new

        contract.validate
      end

      it 'is invalid' do
        expect(contract.errors.symbols_for(:priority))
          .to match_array [:does_not_exist]
      end
    end
  end

  describe '#assignable_statuses' do
    let(:role) { FactoryBot.build_stubbed(:role) }
    let(:type) { FactoryBot.build_stubbed(:type) }
    let(:assignee_user) { FactoryBot.build_stubbed(:user) }
    let(:author_user) { FactoryBot.build_stubbed(:user) }
    let(:current_status) { FactoryBot.build_stubbed(:status) }
    let(:version) { FactoryBot.build_stubbed(:version) }
    let(:work_package) do
      FactoryBot.build_stubbed(:work_package,
                               assigned_to: assignee_user,
                               author: author_user,
                               status: current_status,
                               version: version,
                               type: type)
    end
    let!(:default_status) do
      status = FactoryBot.build_stubbed(:status)

      allow(Status)
        .to receive(:default)
        .and_return(status)

      status
    end

    let(:roles) { [role] }

    before do
      allow(current_user)
        .to receive(:roles_for_project)
         .with(work_package.project)
         .and_return(roles)
    end

    shared_examples_for 'new_statuses_allowed_to' do
      let(:base_scope) do
        from_workflows = Workflow
                        .from_status(current_status.id, type.id, [role.id], author, assignee)
                        .select(:new_status_id)

        Status.where(id: from_workflows)
          .or(Status.where(id: current_status.id))
      end

      it 'returns a scope that returns current_status and those available by workflow' do
        expect(contract.assignable_statuses.to_sql)
          .to eql base_scope.order_by_position.to_sql
      end

      it 'removes closed statuses if blocked' do
        allow(work_package)
          .to receive(:blocked?)
          .and_return(true)

        expected = base_scope.where(is_closed: false).order_by_position

        expect(contract.assignable_statuses.to_sql)
          .to eql expected.to_sql
      end

      context 'if the current status is closed and the version is closed as well' do
        let(:version) { FactoryBot.build_stubbed(:version, status: 'closed') }
        let(:current_status) { FactoryBot.build_stubbed(:status, is_closed: true) }

        it 'only allows the current status' do
          expect(contract.assignable_statuses.to_sql)
            .to eql Status.where(id: current_status.id).to_sql
        end
      end
    end

    context 'with somebody else asking' do
      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { false }
      end
    end

    context 'with the author asking' do
      let(:current_user) { author_user }

      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { true }
        let(:assignee) { false }
      end
    end

    context 'with the assignee asking' do
      let(:current_user) { assignee_user }

      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { true }
      end
    end

    context 'with the assignee changing and asking as new assignee' do
      before do
        work_package.assigned_to = current_user
      end

      # is using the former assignee
      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { false }
      end
    end

    context 'with the status having changed' do
      let(:new_status) { FactoryBot.build_stubbed(:status) }

      before do
        allow(work_package).to receive(:persisted?).and_return(true)
        allow(work_package).to receive(:status_id_changed?).and_return(true)

        allow(Status)
          .to receive(:find_by)
          .with(id: work_package.status_id_was)
          .and_return(current_status)

        work_package.status = new_status
      end

      it_behaves_like 'new_statuses_allowed_to' do
        let(:author) { false }
        let(:assignee) { false }
      end
    end
  end

  describe '#assignable_types' do
    let(:scope) do
      double('type scope').tap do |s|
        allow(s)
          .to receive(:includes)
          .and_return(s)
      end
    end

    context 'project nil' do
      before do
        work_package.project = nil
      end

      it 'is all types' do
        allow(Type)
          .to receive(:includes)
          .and_return(scope)

        expect(contract.assignable_types)
          .to eql(scope)
      end
    end

    context 'project defined' do
      it 'is all types of the project' do
        allow(work_package.project)
          .to receive(:types)
          .and_return(scope)

        expect(contract.assignable_types)
          .to eql(scope)
      end
    end
  end

  describe '#assignable_versions' do
    let(:result) { double }

    it 'calls through to the work package' do
      expect(work_package).to receive(:assignable_versions).and_return(result)
      expect(subject.assignable_values(:version, current_user)).to eql(result)
    end
  end

  describe '#assignable_priorities' do
    let(:active_priority) { FactoryBot.build(:priority, active: true) }
    let(:inactive_priority) { FactoryBot.build(:priority, active: false) }

    before do
      active_priority.save!
      inactive_priority.save!
    end

    it 'returns only active priorities' do
      expect(subject.assignable_values(:priority, current_user).size).to be >= 1
      subject.assignable_values(:priority, current_user).each do |priority|
        expect(priority.active).to be_truthy
      end
    end
  end

  describe '#assignable_categories' do
    let(:category) { double('category') }

    before do
      allow(project).to receive(:categories).and_return([category])
    end

    it 'returns all categories of the project' do
      expect(subject.assignable_values(:category, current_user)).to match_array([category])
    end
  end
end
