#-- encoding: UTF-8

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

describe Relations::UpdateService do
  let(:work_package1_start_date) { nil }
  let(:work_package1_due_date) { Date.today }
  let(:work_package2_start_date) { nil }
  let(:work_package2_due_date) { nil }

  let(:follows_relation) { false }
  let(:delay) { 3 }

  let(:work_package1) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             due_date: work_package1_due_date,
                             start_date: work_package1_start_date)
  end
  let(:work_package2) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             due_date: work_package2_due_date,
                             start_date: work_package2_start_date)
  end
  let(:instance) do
    described_class.new(user: user, model: relation)
  end
  let(:relation) do
    relation = FactoryBot.build_stubbed(:relation)

    allow(relation)
      .to receive(:follows?)
      .and_return(follows_relation)

    relation
  end
  let(:attributes) do
    {
      to: work_package1,
      from: work_package2,
      delay: delay
    }
  end

  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:model_valid) { true }
  let(:contract_valid) { true }
  let(:contract) { double('contract') }
  let(:symbols_for_base) { [] }

  subject do
    instance.call(attributes: attributes)
  end

  before do
    allow(relation)
      .to receive(:save)
      .and_return(model_valid)

    allow(Relations::UpdateContract)
      .to receive(:new)
      .with(relation, user, options: { changed_by_system: [] })
      .and_return(contract)
    allow(contract)
      .to receive(:validate)
      .and_return(contract_valid)
  end

  context 'when all valid and it is a follows relation' do
    let(:set_schedule_service) { double('set schedule service') }
    let(:set_schedule_work_package2_result) do
      ServiceResult.new success: true, result: work_package2, errors: work_package2.errors
    end
    let(:set_schedule_result) do
      sr = ServiceResult.new success: true, result: work_package2, errors: work_package2.errors
      sr.dependent_results << set_schedule_work_package2_result
      sr
    end

    let(:follows_relation) { true }

    before do
      expect(WorkPackages::SetScheduleService)
        .to receive(:new)
        .with(user: user, work_package: work_package1)
        .and_return(set_schedule_service)

      expect(set_schedule_service)
        .to receive(:call)
        .and_return(set_schedule_result)

      allow(work_package2)
        .to receive(:changed?)
        .and_return(true)

      expect(work_package2)
        .to receive(:save)
        .and_return(true)

      allow(set_schedule_result)
        .to receive(:success=)
    end

    it 'is successful' do
      expect(subject)
        .to be_success
    end

    it 'returns the relation' do
      expect(subject.result)
        .to eql relation
    end

    it 'has a dependent result for the from-work package' do
      expect(subject.dependent_results)
        .to match_array [set_schedule_work_package2_result]
    end
  end

  context 'when all is valid and it is not a follows relation' do
    it 'is successful' do
      expect(subject)
        .to be_success
    end

    it 'returns the relation' do
      expect(subject.result)
        .to eql relation
    end
  end

  context 'when the contract is invalid' do
    let(:contract_valid) { false }
    let(:contract_errors) { double('contract_errors') }

    before do
      allow(contract)
        .to receive(:errors)
        .and_return(contract_errors)
      allow(contract_errors)
        .to receive(:symbols_for)
        .with(:base)
        .and_return(symbols_for_base)
    end

    it 'is unsuccessful' do
      expect(subject)
        .to be_failure
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql contract_errors
    end
  end

  context 'when the model is invalid' do
    let(:model_valid) { false }
    let(:model_errors) { double('model_errors') }

    before do
      allow(relation)
        .to receive(:errors)
        .and_return(model_errors)
      allow(model_errors)
        .to receive(:symbols_for)
        .with(:base)
        .and_return(symbols_for_base)
    end

    it 'is unsuccessful' do
      expect(subject)
        .to be_failure
    end

    it "returns the model's errors" do
      expect(subject.errors)
        .to eql model_errors
    end
  end
end
