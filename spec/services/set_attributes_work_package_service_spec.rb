#-- encoding: UTF-8

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

describe SetAttributesWorkPackageService, type: :model do
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:project) do
    p = FactoryGirl.build_stubbed(:project)
    allow(p).to receive(:shared_versions).and_return([])

    p
  end
  let(:work_package) do
    wp = FactoryGirl.build_stubbed(:work_package, project: project)
    wp.type = FactoryGirl.build_stubbed(:type)
    wp.send(:clear_changes_information)

    allow(wp)
      .to receive(:valid?)
      .and_return(work_package_valid)

    wp
  end
  let(:mock_contract) do
    double(WorkPackages::UpdateContract,
           new: mock_contract_instance)
  end
  let(:mock_contract_instance) do
    mock = mock_model(WorkPackages::UpdateContract)
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
                        contract: mock_contract)
  end

  describe 'call' do
    before do
    end

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

    context 'when switching the type' do
      let(:target_type) { FactoryGirl.build_stubbed(:type) }

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

    context 'when setting a parent' do
      let(:parent) { FactoryGirl.build_stubbed(:work_package) }

      context "with the parent being restricted in it's ability to be moved" do
        let(:soonest_date) { Date.today + 3.days }

        before do
          allow(parent)
            .to receive(:soonest_start)
            .and_return(soonest_date)
        end

        it 'sets the start date to the earliest possible date' do
          instance.call(parent: parent)

          expect(work_package.start_date).to eql(Date.today + 3.days)
        end
      end

      context 'with the parent being restricted but the attributes define a later date' do
        let(:soonest_date) { Date.today + 3.days }

        before do
          allow(parent)
            .to receive(:soonest_start)
            .and_return(soonest_date)
        end

        it 'sets the dates to provided dates' do
          instance.call(parent: parent, start_date: Date.today + 4.days, due_date: Date.today + 5.days)

          expect(work_package.start_date).to eql(Date.today + 4.days)
          expect(work_package.due_date).to eql(Date.today + 5.days)
        end
      end

      context 'with the parent being restricted but the attributes define an earlier date' do
        let(:soonest_date) { Date.today + 3.days }

        before do
          allow(parent)
            .to receive(:soonest_start)
            .and_return(soonest_date)
        end

        # This would be invalid but the dates should be set nevertheless
        # so we can have a correct error handling.
        it 'sets the dates to provided dates' do
          instance.call(parent: parent, start_date: Date.today + 1.days, due_date: Date.today + 2.days)

          expect(work_package.start_date).to eql(Date.today + 1.days)
          expect(work_package.due_date).to eql(Date.today + 2.days)
        end
      end
    end
  end
end
