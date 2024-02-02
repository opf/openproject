# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe Queries::Projects::ProjectQueries::SetAttributesService, type: :model do
  let(:current_user) { build_stubbed(:user) }

  let(:contract_instance) do
    contract = instance_double(Queries::Projects::ProjectQueries::CreateContract)
    allow(contract)
      .to receive_messages(validate: contract_valid, errors: contract_errors)
    contract
  end

  let(:contract_errors) { instance_double(ActiveModel::Errors) }
  let(:contract_valid) { true }
  let(:model_valid) { true }

  let(:instance) do
    described_class.new(user: current_user,
                        model: model_instance,
                        contract_class:,
                        contract_options: {})
  end
  let(:model_instance) { Queries::Projects::ProjectQuery.new }
  let(:contract_class) do
    allow(Queries::Projects::ProjectQueries::CreateContract)
      .to receive(:new)
            .and_return(contract_instance)

    Queries::Projects::ProjectQueries::CreateContract
  end

  let(:params) { {} }

  before do
    allow(model_instance)
      .to receive(:valid?)
            .and_return(model_valid)
  end

  subject { instance.call(params) }

  it 'returns the instance as the result' do
    expect(subject.result)
      .to eql model_instance
  end

  it 'is a success' do
    expect(subject)
      .to be_success
  end

  context 'with params' do
    let(:params) do
      {
        name: 'Foobar',
        filters: [
          {
            attribute: 'id',
            operator: '=',
            values: %w[1 2 3]
          },
          {
            attribute: 'active',
            operator: '!',
            values: ['t']
          }
        ],
        orders: [
          {
            attribute: 'id',
            direction: 'asc'
          },
          {
            attribute: 'name',
            direction: 'desc'
          }
        ]
      }
    end

    it 'assigns the name param' do
      subject

      expect(model_instance.name).to eq 'Foobar'
    end

    it 'assigns the filter param' do
      subject

      expect(model_instance.filters)
        .to(be_all { |f| f.is_a?(Queries::Projects::Filters::ProjectFilter) })

      expect(model_instance.filters.map { |f| [f.name, f.operator, f.values] })
        .to eql [[:id, '=', %w[1 2 3]], [:active, '!', ['t']]]
    end

    it 'assigns the orders param' do
      subject

      expect(model_instance.orders)
        .to(be_all { |f| f.is_a?(Queries::Orders::Base) })

      expect(model_instance.orders.map { |o| [o.name, o.direction] })
        .to eql [["id", :asc], ["name", :desc]]
    end
  end

  context 'without params' do
    let(:params) do
      {}
    end

    it 'assigns a default orders' do
      subject

      expect(model_instance.orders)
        .to(be_all { |f| f.is_a?(Queries::Orders::Base) })

      expect(model_instance.orders.map { |o| [o.name, o.direction] })
        .to eql [%i[lft asc]]
    end

    it 'assigns a default filter param' do
      subject

      expect(model_instance.filters)
        .to(be_all { |f| f.is_a?(Queries::Projects::Filters::ProjectFilter) })

      expect(model_instance.filters.map { |f| [f.name, f.operator, f.values] })
        .to eql [[:active, '=', %w[t]]]
    end

    it 'assigns default columns' do
      subject

      expect(model_instance.columns)
        .to eql Setting.enabled_projects_columns
    end
  end

  context 'with the query already having order and with order params' do
    let(:model_instance) do
      Queries::Projects::ProjectQuery.new.tap do |query|
        query.order(lft: :asc)
      end
    end

    let(:params) do
      {
        orders: [
          {
            attribute: 'id',
            direction: 'asc'
          },
          {
            attribute: 'name',
            direction: 'desc'
          }
        ]
      }
    end

    it 'assigns the orders param' do
      subject

      expect(model_instance.orders)
        .to(be_all { |f| f.is_a?(Queries::Orders::Base) })

      expect(model_instance.orders.map { |o| [o.name, o.direction] })
        .to eql [["id", :asc], ["name", :desc]]
    end
  end

  context 'with the query already having filters and with filter params' do
    let(:model_instance) do
      Queries::Projects::ProjectQuery.new.tap do |query|
        query.where("active", '=', ['t'])
      end
    end

    let(:params) do
      {
        filters: [
          {
            attribute: 'id',
            operator: '=',
            values: %w[1 2 3]
          }
        ]
      }
    end

    it 'assigns the filter param' do
      subject

      expect(model_instance.filters)
        .to(be_all { |f| f.is_a?(Queries::Projects::Filters::ProjectFilter) })

      expect(model_instance.filters.map { |f| [f.name, f.operator, f.values] })
        .to eql [[:id, '=', %w[1 2 3]]]
    end
  end

  context 'with the query already having columns and with column params' do
    let(:model_instance) do
      Queries::Projects::ProjectQuery.new.tap do |query|
        query.columns = %w[id name]
      end
    end

    let(:params) do
      {
        columns: %w[project_status created_at]
      }
    end

    it 'assigns the columns param' do
      subject
      expect(model_instance.columns)
        .to eql %w[project_status created_at]
    end
  end

  context 'with an invalid contract' do
    let(:contract_valid) { false }

    it 'returns failure' do
      expect(subject)
        .not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
