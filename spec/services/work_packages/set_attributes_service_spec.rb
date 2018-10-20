#-- encoding: UTF-8

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

describe WorkPackages::SetAttributesService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:project) do
    p = FactoryBot.build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    wp = FactoryBot.build_stubbed(:work_package, project: project)
    wp.type = FactoryBot.build_stubbed(:type)
    wp.send(:clear_changes_information)

    allow(wp)
      .to receive(:valid?)
      .and_return(work_package_valid)

    wp
  end
  let(:new_work_package) do
    wp = WorkPackage.new

    allow(wp)
      .to receive(:valid?)
      .and_return(work_package_valid)

    wp
  end
  let(:contract_class) { WorkPackages::UpdateContract }
  let(:mock_contract) do
    double(contract_class,
           new: mock_contract_instance)
  end
  let(:mock_contract_instance) do
    mock = mock_model(contract_class)
    allow(mock)
      .to receive(:validate)
      .and_return contract_valid

    mock
  end
  let(:contract_valid) { true }
  let(:work_package_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        work_package: work_package,
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

      context 'when the work package is invalid' do
        let(:work_package_valid) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'leaves the value unchanged' do
          subject

          expect(work_package.changed?).to be_truthy
        end

        it "exposes the work_packages's errors" do
          subject

          expect(subject.errors).to eql work_package.errors
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
      let(:default_status) { FactoryBot.build_stubbed(:default_status) }
      let(:other_status) { FactoryBot.build_stubbed(:status) }
      let(:new_statuses) { [other_status, default_status] }

      before do
        allow(work_package)
          .to receive(:new_statuses_allowed_to)
          .with(user, true)
          .and_return(new_statuses)
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
      let(:other_user) { FactoryBot.build_stubbed(:user) }

      context 'no value set before for a new work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }
        let(:work_package) { new_work_package }

        before do
          work_package.author = nil
        end

        it_behaves_like 'service call' do
          it "sets the service's author" do
            subject

            expect(work_package.author)
              .to eql user
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
        wp = FactoryBot.create(:work_package)
        wp.start_date = Date.today + 5.days
        wp.due_date = Date.today
        wp.save!(validate: false)

        wp
      end
      let(:user) { FactoryBot.build_stubbed(:admin) }
      let(:instance) do
        described_class.new(user: user,
                            work_package: invalid_wp,
                            contract_class: contract_class)
      end

      context 'with a current invalid start date' do
        let(:call_attributes) { attributes }
        let(:attributes) { { start_date: Date.today - 5.days } }
        let(:contract_valid) { true }
        let(:work_package_valid) { true }
        subject { instance.call(call_attributes) }

        it 'is successful' do
          expect(subject.success?).to be_truthy
          expect(subject.errors).to be_empty
        end
      end
    end

    context 'priority' do
      let(:default_priority) { FactoryBot.build_stubbed(:priority) }
      let(:other_priority) { FactoryBot.build_stubbed(:priority) }

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

      context 'no value set on existing work package' do
        let(:call_attributes) { {} }
        let(:attributes) { {} }

        before do
          work_package.priority = nil
        end

        it_behaves_like 'service call' do
          it 'stays nil' do
            subject

            expect(work_package.priority)
              .to be_nil
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
      let(:target_type) { FactoryBot.build_stubbed(:type) }

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
      let(:new_project) { FactoryBot.build_stubbed(:project) }
      let(:version) { FactoryBot.build_stubbed(:version) }
      let(:category) { FactoryBot.build_stubbed(:category) }
      let(:new_category) { FactoryBot.build_stubbed(:category, name: category.name) }
      let(:new_statuses) { [work_package.status] }
      let(:new_versions) { [] }
      let(:type) { work_package.type }
      let(:new_types) { [type] }
      let(:default_type) { FactoryBot.build_stubbed(:type_standard) }
      let(:other_type) { FactoryBot.build_stubbed(:type) }
      let(:yet_another_type) { FactoryBot.build_stubbed(:type) }

      let(:call_attributes) { {} }
      let(:new_project_categories) do
        categories_stub = double('categories')
        allow(new_project)
          .to receive(:categories)
          .and_return(categories_stub)

        categories_stub
      end

      before do
        allow(work_package)
          .to receive(:new_statuses_allowed_to)
          .with(user, true)
          .and_return(new_statuses)
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
        context 'fixed_version' do
          before do
            work_package.fixed_version = version
          end

          context 'not shared in new project' do
            it 'sets to nil' do
              subject

              expect(work_package.fixed_version)
                .to be_nil
            end
          end

          context 'shared in the new project' do
            let(:new_versions) { [version] }

            it 'keeps the version' do
              subject

              expect(work_package.fixed_version)
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

            it 'uses the default type' do
              subject

              expect(work_package.type)
                .to eql default_type
            end
          end

          context 'no default type exists in new project' do
            let(:new_types) { [other_type, yet_another_type] }

            it 'uses the first type' do
              subject

              expect(work_package.type)
                .to eql other_type
            end
          end

          context 'when also setting a new type via attributes' do
            let(:attributes) { { project: new_project, type: yet_another_type } }

            it 'sets the desired type' do
              subject

              expect(work_package.type)
                .to eql yet_another_type
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
  end
end
