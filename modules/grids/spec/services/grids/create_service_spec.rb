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

describe Grids::CreateService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:project) do
    FactoryBot.build_stubbed(:project).tap do |p|
      allow(Project)
        .to receive(:find)
        .with(p.id)
        .and_return(p)
    end
  end
  let(:contract_class) do
    double('contract_class', '<=': true)
  end
  let(:grid_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        contract_class: contract_class)
  end
  let(:scope) { "some/scope/url" }
  let(:call_attributes) { { scope: scope } }
  let(:grid_class) do
    Grids::Grid
  end
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
    grid = FactoryBot.build(grid_class.name.demodulize.underscore.to_sym)

    allow(Grids::Factory)
      .to receive(:build)
      .with(scope, user)
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
            model: grid,
            contract_class: contract_class)
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(set_attributes_result)
  end
  let!(:grid_configuration) do
    allow(Grids::Configuration)
      .to receive(:attributes_from_scope)
      .with(scope)
      .and_return(class: grid_class, project_id: project.id)
  end

  describe 'call' do
    subject { instance.call(call_attributes) }

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

    it 'creates a Grid' do
      expect(subject.result)
        .to be_a grid_class
    end
  end
end
