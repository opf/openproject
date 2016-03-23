#-- encoding: UTF-8
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

require 'spec_helper'

describe CreateWorkPackageService do
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:work_package) { FactoryGirl.build_stubbed(:work_package) }
  let(:project) { FactoryGirl.build_stubbed(:project_with_types) }
  let(:instance) { described_class.new(user: user) }
  let(:errors) { double('errors') }

  describe '.contract' do
    it 'uses the CreateContract contract' do
      expect(described_class.contract).to eql WorkPackages::CreateContract
    end
  end

  describe '.new' do
    it 'takes a user which is available as a getter' do
      expect(instance.user).to eql user
    end
  end

  describe '#call' do
    let(:mock_contract) do
      double(WorkPackages::CreateContract,
             new: mock_contract_instance)
    end
    let(:mock_contract_instance) do
      mock_model(WorkPackages::CreateContract)
    end
    let(:attributes) do
      { project_id: 1,
        subject: 'lorem ipsum',
        status_id: 5 }
    end

    before do
      allow(described_class)
        .to receive(:contract)
        .and_return(mock_contract)

      allow(WorkPackage)
        .to receive(:new)
        .and_return(work_package)

      allow(work_package)
        .to receive(:save)
        .and_return true
      allow(mock_contract_instance)
        .to receive(:validate)
        .and_return true
    end

    context 'if contract validates and the work package saves' do
      it 'is successful' do
        expect(instance.call(attributes: {}))
          .to be_success
      end

      it 'has no errors' do
        expect(instance.call(attributes: {}).errors)
          .to be_empty
      end

      it 'returns the work package as a result' do
        result = instance.call(attributes: {}).result

        expect(result).to be_a WorkPackage
      end

      it 'assigns the attributes provided' do
        result = instance.call(attributes: attributes).result

        expect(result.project_id).to eql(attributes[:project_id])
        expect(result.subject).to eql(attributes[:subject])
      end

      it 'sets the user to be the author' do
        result = instance.call(attributes: attributes).result

        expect(result.author).to eql(user)
      end

      it 'sets the type that is provided' do
        result = instance.call(attributes: { type_id: 1 }).result

        expect(result.type_id).to eql(1)
      end
    end

    context 'if contract does not validate' do
      before do
        allow(mock_contract_instance)
          .to receive(:validate)
          .and_return false
      end

      it 'is unsuccessful' do
        expect(instance.call(attributes: {}))
          .to_not be_success
      end

      it "returns the contract's errors" do
        allow(mock_contract_instance)
          .to receive(:errors)
          .and_return errors

        expect(instance.call(attributes: {}).errors).to eql errors
      end
    end

    context 'if work_package does not save' do
      before do
        allow(work_package)
          .to receive(:save)
          .and_return false
      end

      it 'is unsuccessful' do
        expect(instance.call(attributes: {}))
          .to_not be_success
      end

      it "returns the work_package's errors" do
        allow(work_package)
          .to receive(:errors)
          .and_return errors

        expect(instance.call(attributes: {}).errors).to eql errors
      end
    end
  end
end
