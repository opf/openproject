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

describe Grids::CreateService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    double('contract_class')
  end
  let(:grid_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        contract_class: contract_class)
  end
  let(:call_attributes) { { page: OpenProject::StaticRouting::StaticUrlHelpers.new.my_page_path } }
  let(:grid_class) { Grids::MyPage }
  let(:set_attributes_success) do
    true
  end
  let(:set_attributes_errors) do
    double('set_attributes_errors')
  end
  let(:set_attributes_result) do
    ServiceResult.new result: grid,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:grid) do
    grid = FactoryBot.build_stubbed(grid_class.name.demodulize.underscore.to_sym)

    allow(grid_class)
      .to receive(:new_default)
      .with(user)
      .and_return(grid)

    allow(grid)
      .to receive(:save)
      .and_return(grid_valid)

    grid
  end
  let!(:set_attributes_service) do
    service = double('set_attributes_service_instance')

    allow(Grids::SetAttributesService)
      .to receive(:new)
      .with(user: user,
            grid: grid,
            contract_class: contract_class)
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(set_attributes_result)
  end

  describe 'call' do
    shared_examples_for 'service call' do
      subject { instance.call(attributes: call_attributes) }

      it 'is successful' do
        expect(subject.success?).to be_truthy
      end

      it 'returns the result of the SetAttributesService' do
        expect(subject)
          .to eql set_attributes_result
      end

      it 'persists the grid' do
        expect(grid)
          .to receive(:save)
          .and_return(grid_valid)

        subject
      end

      context 'when the SetAttributeService is unsuccessful' do
        let(:set_attributes_success) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it 'returns the result of the SetAttributesService' do
          expect(subject)
            .to eql set_attributes_result
        end

        it 'does not persist the changes' do
          expect(grid)
            .to_not receive(:save)

          subject
        end

        it "exposes the contract's errors" do
          subject

          expect(subject.errors).to eql set_attributes_errors
        end
      end

      context 'when the grid is invalid' do
        let(:grid_valid) { false }

        it 'is unsuccessful' do
          expect(subject.success?).to be_falsey
        end

        it "exposes the grid's errors" do
          subject

          expect(subject.errors).to eql grid.errors
        end
      end
    end

    context 'without parameters' do
      let(:call_attributes) { {} }
      let(:grid_class) { Grids::Grid }

      it_behaves_like 'service call' do
        it 'creates a Grid' do
          expect(subject.result)
            .to be_a grid_class
        end
      end
    end

    context 'with my page grid parameters' do
      let(:call_attributes) { { page: OpenProject::StaticRouting::StaticUrlHelpers.new.my_page_path } }

      it_behaves_like 'service call' do
        it 'creates a Grids::MyPage' do
          expect(subject.result)
            .to be_a Grids::MyPage
        end
      end
    end
  end
end
