#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
        .with(permission, project)
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

  describe 'estimated hours' do
    it_behaves_like 'a parent unwritable property', :estimated_hours

    let(:estimated_hours) { 1 }

    before do
      work_package.estimated_hours = estimated_hours

      contract.validate
    end

    context '> 0' do
      let(:estimated_hours) { 1 }

      it 'is valid' do
        expect(subject.errors.symbols_for(:estimated_hours))
          .to be_empty
      end
    end

    context '0' do
      let(:estimated_hours) { 0 }

      it 'is valid' do
        expect(subject.errors.symbols_for(:estimated_hours))
          .to be_empty
      end
    end

    context 'nil' do
      let(:estimated_hours) { nil }

      it 'is valid' do
        expect(subject.errors.symbols_for(:estimated_hours))
          .to be_empty
      end
    end

    context '< 0' do
      let(:estimated_hours) { -1 }

      it 'is invalid' do
        expect(subject.errors.symbols_for(:estimated_hours))
          .to match_array [:only_values_greater_or_equal_zeroes_allowed]
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

  describe 'fixed_version' do
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
        work_package.fixed_version = assignable_version
        subject.validate
      end

      it 'is valid' do
        expect(subject.errors).to be_empty
      end
    end

    context 'for non assignable version' do
      before do
        work_package.fixed_version = invalid_version
        subject.validate
      end

      it 'is invalid' do
        expect(subject.errors.symbols_for(:fixed_version_id)).to eql [:inclusion]
      end
    end

    context 'for a closed version' do
      let(:assignable_version) { FactoryBot.build_stubbed(:version, status: 'closed') }

      context 'when reopening a work package' do
        before do
          allow(work_package)
            .to receive(:reopened?)
            .and_return(true)

          work_package.fixed_version = assignable_version
          subject.validate
        end

        it 'is invalid' do
          expect(subject.errors[:base]).to eql [I18n.t(:error_can_not_reopen_work_package_on_closed_version)]
        end
      end

      context 'when not reopening the work package' do
        before do
          work_package.fixed_version = assignable_version
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
  end

  describe 'status' do
    let(:roles) { [FactoryBot.build_stubbed(:role)] }
    let(:valid_transition_result) { true }
    let(:new_status) { FactoryBot.build_stubbed(:status) }
    let(:from_id) { work_package.status_id }
    let(:to_id) { new_status.id }
    let(:status_change) { work_package.status = new_status }

    before do
      allow(current_user)
        .to receive(:roles)
        .with(work_package.project)
        .and_return(roles)

      allow(type)
        .to receive(:valid_transition?)
        .with(from_id,
              to_id,
              roles)
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
