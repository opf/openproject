#-- encoding: UTF-8

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

describe WorkPackages::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:project) do
    p = build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    wp = build_stubbed(:work_package, project: project)
    wp.type = initial_type
    wp.send(:clear_changes_information)

    wp
  end
  let(:new_work_package) do
    WorkPackage.new
  end
  let(:initial_type) { build_stubbed(:type) }
  let(:statuses) { [] }
  let(:contract_class) { WorkPackages::UpdateContract }
  let(:mock_contract) do
    double(contract_class,
           new: mock_contract_instance)
  end
  let(:mock_contract_instance) do
    double(contract_class,
           assignable_statuses: statuses,
           errors: contract_errors,
           validate: contract_valid)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double('contract_errors')
  end
  let(:instance) do
    described_class.new(user: user,
                        model: work_package,
                        contract_class: mock_contract)
  end

  describe 'call' do
    shared_examples_for 'service call' do
      subject { instance.call(call_attributes) }

      it 'is successful' do
        expect(subject.success?).to be_truthy
      end

      it 'sets the value' do
        subject

        attributes.each do |attribute, key|
          expect(work_package.send(attribute)).to eql key
        end
      end

      it 'does not persist the work_package' do
        expect(work_package)
          .not_to receive(:save)

        subject
      end

      it 'has no errors' do
        expect(subject.errors).to be_empty
      end

      context 'when the contract does not validate' do
        let(:contract_valid) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'does not persist the changes' do
          subject

          expect(work_package).to_not receive(:save)
        end

        it "exposes the contract's errors" do
          subject

          expect(subject.errors).to eql mock_contract_instance.errors
        end
      end
    end

    context 'update subject before calling the service' do
      let(:call_attributes) { {} }
      let(:attributes) { { subject: 'blubs blubs' } }

      before do
        work_package.attributes = attributes
      end

      it_behaves_like 'service call'
    end

    context 'updating subject via attributes' do
      let(:call_attributes) { attributes }
      let(:attributes) { { subject: 'blubs blubs' } }

      it_behaves_like 'service call'
    end

    context 'status' do
      let(:default_status) { build_stubbed(:default_status) }
      let(:other_status) { build_stubbed(:status) }
      let(:new_statuses) { [other_status, default_status] }

      before do
        allow(Status)
          .to receive(:default)
          .and_return(default_status)
      end

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        before do
          work_package.status = nil
        end

        it_behaves_like 'service call' do
          it 'sets the default status' do
            subject

            expect(work_package.status)
              .to eql default_status
          end
        end
      end

      context 'no value set on existing work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }

        before do
          work_package.status = nil
        end

        it_behaves_like 'service call' do
          it 'stays nil' do
            subject

            expect(work_package.status)
              .to be_nil
          end
        end
      end

      context 'update status before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { status: other_status } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call'
      end

      context 'updating status via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { status: other_status } }

        it_behaves_like 'service call'
      end
    end

    context 'author' do
      let(:other_user) { build_stubbed(:user) }

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        it_behaves_like 'service call' do
          it "sets the service's author" do
            subject

            expect(work_package.author)
              .to eql user
          end

          it 'notes the author to be system changed' do
            subject

            expect(work_package.changed_by_system['author_id'])
              .to eql [0, user.id]
          end
        end
      end

      context 'no value set on existing work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }

        before do
          work_package.author = nil
        end

        it_behaves_like 'service call' do
          it 'stays nil' do
            subject

            expect(work_package.author)
              .to be_nil
          end
        end
      end

      context 'update author before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { author: other_user } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call'
      end

      context 'updating author via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { author: other_user } }

        it_behaves_like 'service call'
      end
    end

    context 'with the actual contract' do
      let(:invalid_wp) do
        wp = create(:work_package)
        wp.start_date = Date.today + 5.days
        wp.due_date = Date.today
        wp.save!(validate: false)

        wp
      end
      let(:user) { build_stubbed(:admin) }
      let(:instance) do
        described_class.new(user: user,
                            model: invalid_wp,
                            contract_class: contract_class)
      end

      context 'with a current invalid start date' do
        let(:call_attributes) { attributes }
        let(:attributes) { { start_date: Date.today - 5.days } }
        let(:contract_valid) { true }
        subject { instance.call(call_attributes) }

        it 'is successful' do
          expect(subject.success?).to be_truthy
          expect(subject.errors).to be_empty
        end
      end
    end

    context 'start_date & due_date' do
      let(:parent) do
        build_stubbed(:stubbed_work_package,
                                 start_date: parent_start_date,
                                 due_date: parent_due_date)
      end
      let(:parent_start_date) { Date.today - 5.days }
      let(:parent_due_date) { Date.today + 10.days }

      context 'with a parent' do
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        context 'with the parent having dates and not providing own dates' do
          let(:call_attributes) { { parent: parent } }

          it_behaves_like 'service call' do
            it "sets the start_date to the parent`s start_date" do
              subject

              expect(work_package.start_date)
                .to eql parent_start_date
            end

            it "sets the due_date to the parent`s due_date" do
              subject

              expect(work_package.due_date)
                .to eql parent_due_date
            end
          end
        end

        context 'with the parent having start date (no due) and not providing own dates' do
          let(:call_attributes) { { parent: parent } }
          let(:parent_due_date) { nil }

          it_behaves_like 'service call' do
            it "sets the start_date to the parent`s start_date" do
              subject

              expect(work_package.start_date)
                .to eql parent_start_date
            end

            it "sets the due_date to nil" do
              subject

              expect(work_package.due_date)
                .to be_nil
            end
          end
        end

        context 'with the parent having due date (no start) and not providing own dates' do
          let(:call_attributes) { { parent: parent } }
          let(:parent_start_date) { nil }

          it_behaves_like 'service call' do
            it "sets the start_date to nil" do
              subject

              expect(work_package.start_date)
                .to be_nil
            end

            it "sets the due_date to the parent`s due_date" do
              subject

              expect(work_package.due_date)
                .to eql parent_due_date
            end
          end
        end

        context 'with the parent having dates but providing own dates' do
          let(:call_attributes) { { parent: parent, start_date: Date.today, due_date: Date.today + 1.day } }

          it_behaves_like 'service call' do
            it "sets the start_date to the provided date" do
              subject

              expect(work_package.start_date)
                .to eql Date.today
            end

            it "sets the due_date to the provided date" do
              subject

              expect(work_package.due_date)
                .to eql Date.today + 1.day
            end
          end
        end

        context 'with the parent having dates but providing own start_date' do
          let(:call_attributes) { { parent: parent, start_date: Date.today } }

          it_behaves_like 'service call' do
            it "sets the start_date to the provided date" do
              subject

              expect(work_package.start_date)
                .to eql Date.today
            end

            it "sets the due_date to the parent's due_date" do
              subject

              expect(work_package.due_date)
                .to eql parent_due_date
            end
          end
        end

        context 'with the parent having dates but providing own due_date' do
          let(:call_attributes) { { parent: parent, due_date: Date.today + 4.days } }

          it_behaves_like 'service call' do
            it "sets the start_date to the parent's start date" do
              subject

              expect(work_package.start_date)
                .to eql parent_start_date
            end

            it "sets the due_date to the provided date" do
              subject

              expect(work_package.due_date)
                .to eql Date.today + 4.days
            end
          end
        end

        context 'with the parent having dates but providing own empty start_date' do
          let(:call_attributes) { { parent: parent, start_date: nil } }

          it_behaves_like 'service call' do
            it "sets the start_date to nil" do
              subject

              expect(work_package.start_date)
                .to be_nil
            end

            it "sets the due_date to the parent's due_date" do
              subject

              expect(work_package.due_date)
                .to eql parent_due_date
            end
          end
        end

        context 'with the parent having dates but providing own empty due_date' do
          let(:call_attributes) { { parent: parent, due_date: nil } }

          it_behaves_like 'service call' do
            it "sets the start_date to the parent's start date" do
              subject

              expect(work_package.start_date)
                .to eql parent_start_date
            end

            it "sets the due_date to nil" do
              subject

              expect(work_package.due_date)
                .to be_nil
            end
          end
        end

        context 'with the parent having dates but providing a start date that is before parent`s due date`' do
          let(:call_attributes) { { parent: parent, start_date: parent_due_date - 4.days } }

          it_behaves_like 'service call' do
            it "sets the start_date to the provided date" do
              subject

              expect(work_package.start_date)
                .to eql parent_due_date - 4.days
            end

            it "sets the due_date to the parent's due_date" do
              subject

              expect(work_package.due_date)
                .to eql parent_due_date
            end
          end
        end

        context 'with the parent having dates but providing a start date that is after the parent`s due date`' do
          let(:call_attributes) { { parent: parent, start_date: parent_due_date + 1.day } }

          it_behaves_like 'service call' do
            it "sets the start_date to the provided date" do
              subject

              expect(work_package.start_date)
                .to eql parent_due_date + 1.day
            end

            it "leaves the due date empty" do
              subject

              expect(work_package.due_date)
                .to be_nil
            end
          end
        end

        context 'with the parent having dates but providing a due date that is before the parent`s start date`' do
          let(:call_attributes) { { parent: parent, due_date: parent_start_date - 3.day } }

          it_behaves_like 'service call' do
            it "leaves the start date empty" do
              subject

              expect(work_package.start_date)
                .to be_nil
            end

            it "set the due date to the provided date" do
              subject

              expect(work_package.due_date)
                .to eql parent_start_date - 3.day
            end
          end
        end
      end

      context 'with default setting', with_settings: { work_package_startdate_is_adddate: true } do
        context 'no value set before for a new work package' do
          let(:call_attributes) { {} }
          let(:attributes) { {} }
          let(:work_package) { new_work_package }

          it_behaves_like 'service call' do
            it "sets the default priority" do
              subject

              expect(work_package.start_date)
                .to eql Date.today
            end
          end
        end

        context 'value set on new work package' do
          let(:call_attributes) { { start_date: Date.today + 1.day } }
          let(:attributes) { {} }
          let(:work_package) { new_work_package }

          it_behaves_like 'service call' do
            it 'stays that value' do
              subject

              expect(work_package.start_date)
                .to eq(Date.today + 1.day)
            end
          end
        end
      end
    end

    context 'priority' do
      let(:default_priority) { build_stubbed(:priority) }
      let(:other_priority) { build_stubbed(:priority) }

      before do
        allow(IssuePriority)
          .to receive_message_chain(:active, :default)
          .and_return(default_priority)
      end

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        before do
          work_package.priority = nil
        end

        it_behaves_like 'service call' do
          it "sets the default priority" do
            subject

            expect(work_package.priority)
              .to eql default_priority
          end
        end
      end

      context 'update priority before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { priority: other_priority } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call'
      end

      context 'updating priority via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { priority: other_priority } }

        it_behaves_like 'service call'
      end
    end

    context 'when switching the type' do
      let(:target_type) { build_stubbed(:type) }

      context 'with a type that is no milestone' do
        before do
          allow(target_type)
            .to receive(:is_milestone?)
            .and_return(false)
        end

        it 'sets the start date to the due date' do
          work_package.due_date = Date.today

          instance.call(type: target_type)

          expect(work_package.start_date).to be_nil
        end
      end

      context 'with a type that is a milestone' do
        before do
          allow(target_type)
            .to receive(:is_milestone?)
            .and_return(true)
        end

        it 'sets the start date to the due date' do
          date = Date.today
          work_package.due_date = date

          instance.call(type: target_type)

          expect(work_package.start_date).to eql date
        end

        it 'set the due date to the start date if the due date is nil' do
          date = Date.today
          work_package.start_date = date

          instance.call(type: target_type)

          expect(work_package.due_date).to eql date
        end
      end
    end

    context 'when switching the project' do
      let(:new_project) { build_stubbed(:project) }
      let(:version) { build_stubbed(:version) }
      let(:category) { build_stubbed(:category) }
      let(:new_category) { build_stubbed(:category, name: category.name) }
      let(:new_statuses) { [work_package.status] }
      let(:new_versions) { [] }
      let(:type) { work_package.type }
      let(:new_types) { [type] }
      let(:default_type) { build_stubbed(:type_standard) }
      let(:other_type) { build_stubbed(:type) }
      let(:yet_another_type) { build_stubbed(:type) }

      let(:call_attributes) { {} }
      let(:new_project_categories) do
        categories_stub = double('categories')
        allow(new_project)
          .to receive(:categories)
          .and_return(categories_stub)

        categories_stub
      end

      before do
        allow(new_project)
          .to receive(:shared_versions)
          .and_return(new_versions)
        allow(new_project_categories)
          .to receive(:find_by)
          .with(name: category.name)
          .and_return nil
        allow(new_project)
          .to receive(:types)
          .and_return(new_types)
        allow(new_types)
          .to receive(:order)
          .with(:position)
          .and_return(new_types)
      end

      shared_examples_for 'updating the project' do
        context 'version' do
          before do
            work_package.version = version
          end

          context 'not shared in new project' do
            it 'sets to nil' do
              subject

              expect(work_package.version)
                .to be_nil
            end
          end

          context 'shared in the new project' do
            let(:new_versions) { [version] }

            it 'keeps the version' do
              subject

              expect(work_package.version)
                .to eql version
            end
          end
        end

        context 'category' do
          before do
            work_package.category = category
          end

          context 'no category of same name in new project' do
            it 'sets to nil' do
              subject

              expect(work_package.category)
                .to be_nil
            end
          end

          context 'category of same name in new project' do
            before do
              allow(new_project_categories)
                .to receive(:find_by)
                .with(name: category.name)
                .and_return new_category
            end

            it 'uses the equally named category' do
              subject

              expect(work_package.category)
                .to eql new_category
            end

            it 'adds change to system changes' do
              subject

              expect(work_package.changed_by_system['category_id'])
                .to eql [nil, new_category.id]
            end
          end
        end

        context 'type' do
          context 'current type exists in new project' do
            it 'leaves the type' do
              subject

              expect(work_package.type)
                .to eql type
            end
          end

          context 'a default type exists in new project' do
            let(:new_types) { [other_type, default_type] }

            it 'uses the first type (by position)' do
              subject

              expect(work_package.type)
                .to eql other_type
            end

            it 'adds change to system changes' do
              subject

              expect(work_package.changed_by_system['type_id'])
                .to eql [initial_type.id, other_type.id]
            end
          end

          context 'no default type exists in new project' do
            let(:new_types) { [other_type, yet_another_type] }

            it 'uses the first type (by position)' do
              subject

              expect(work_package.type)
                .to eql other_type
            end

            it 'adds change to system changes' do
              subject

              expect(work_package.changed_by_system['type_id'])
                .to eql [initial_type.id, other_type.id]
            end
          end

          context 'when also setting a new type via attributes' do
            let(:attributes) { { project: new_project, type: yet_another_type } }

            it 'sets the desired type' do
              subject

              expect(work_package.type)
                .to eql yet_another_type
            end

            it 'does not set the change to system changes' do
              subject

              expect(work_package.changed_by_system)
                .not_to include('type_id')
            end
          end
        end
      end

      context 'update project before calling the service' do
        let(:call_attributes) { {} }
        let(:attributes) { { project: new_project } }

        before do
          work_package.attributes = attributes
        end

        it_behaves_like 'service call' do
          it_behaves_like 'updating the project'
        end
      end

      context 'updating project via attributes' do
        let(:call_attributes) { attributes }
        let(:attributes) { { project: new_project } }

        it_behaves_like 'service call' do
          it_behaves_like 'updating the project'
        end
      end
    end

    context 'custom fields' do
      subject { instance.call(call_attributes) }

      context 'non existing fields' do
        let(:call_attributes) { { custom_field_891: '1' } }

        before do
          subject
        end

        it 'is successful' do
          expect(subject).to be_success
        end
      end
    end

    context 'when switching back to automatic scheduling' do
      let(:work_package) do
        wp = build_stubbed(:work_package,
                                      project: project,
                                      schedule_manually: true,
                                      start_date: Date.today,
                                      due_date: Date.today + 5.days)
        wp.type = build_stubbed(:type)
        wp.send(:clear_changes_information)

        allow(wp)
          .to receive(:soonest_start)
          .and_return(soonest_start)

        wp
      end
      let(:call_attributes) { { schedule_manually: false } }
      let(:attributes) { {} }
      let(:soonest_start) { Date.today + 1.day }

      context 'when the soonest start date is later than the current start date' do
        let(:soonest_start) { Date.today + 3.days }

        it_behaves_like 'service call' do
          it 'sets the start date to the soonest possible start date' do
            subject

            expect(work_package.start_date).to eql(Date.today + 3.days)
            expect(work_package.due_date).to eql(Date.today + 8.days)
          end
        end
      end

      context 'when the soonest start date is before the current start date' do
        let(:soonest_start) { Date.today - 3.days }

        it_behaves_like 'service call' do
          it 'sets the start date to the soonest possible start date' do
            subject

            expect(work_package.start_date).to eql(soonest_start)
            expect(work_package.due_date).to eql(Date.today + 2.days)
          end
        end
      end

      context 'when the soonest start date is nil' do
        let(:soonest_start) { nil }

        it_behaves_like 'service call' do
          it 'sets the start date to the soonest possible start date' do
            subject

            expect(work_package.start_date).to eql(Date.today)
            expect(work_package.due_date).to eql(Date.today + 5.days)
          end
        end
      end

      context 'when the work package also has a child' do
        let(:child) do
          build_stubbed(:stubbed_work_package,
                                   start_date: child_start_date,
                                   due_date: child_due_date)
        end
        let(:child_start_date) { Date.today + 2.days }
        let(:child_due_date) { Date.today + 10.days }

        before do
          allow(work_package)
            .to receive(:children)
            .and_return([child])
        end

        context 'when the child`s start date is after soonest_start' do
          it_behaves_like 'service call' do
            it 'sets the dates to the child dates' do
              subject

              expect(work_package.start_date).to eql(Date.today + 2.days)
              expect(work_package.due_date).to eql(Date.today + 10.days)
            end
          end
        end

        context 'when the child`s start date is before soonest_start' do
          let(:soonest_start) { Date.today + 3.days }

          it_behaves_like 'service call' do
            it 'sets the dates to soonest date and to the duration of the child' do
              subject

              expect(work_package.start_date).to eql(Date.today + 3.days)
              expect(work_package.due_date).to eql(Date.today + 11.days)
            end
          end
        end
      end
    end
  end
end
