# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

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
  let(:model_instance) { ProjectQuery.new }
  let(:contract_class) do
    allow(Queries::Projects::ProjectQueries::CreateContract)
      .to receive(:new)
            .and_return(contract_instance)

    Queries::Projects::ProjectQueries::CreateContract
  end
  let(:params) { {} }
  let!(:custom_field) do
    build_stubbed(:project_custom_field, id: 1) do |cf|
      scope = instance_double(ActiveRecord::Relation)

      allow(ProjectCustomField)
        .to receive(:visible)
              .and_return(scope)

      allow(scope)
        .to receive(:find_by)
              .with(id: cf.id.to_s)
              .and_return(cf)
    end
  end

  before do
    RequestStore.store[:custom_sortable_project_custom_fields] = "1"
    allow(model_instance).to receive(:valid?).and_return(model_valid)
  end

  subject { instance.call(params) }

  it "returns the instance as the result" do
    expect(subject.result)
      .to eql model_instance
  end

  it "is a success" do
    expect(subject)
      .to be_success
  end

  context "with params" do
    let(:params) do
      {
        name: "Foobar",
        filters: [
          {
            attribute: "id",
            operator: "=",
            values: %w[1 2 3]
          },
          {
            attribute: "active",
            operator: "!",
            values: ["t"]
          }
        ],
        orders: [
          {
            attribute: "id",
            direction: "asc"
          },
          {
            attribute: "name",
            direction: "desc"
          }
        ]
      }
    end

    it "assigns the name param" do
      subject

      expect(model_instance.name).to eq "Foobar"
    end

    it "assigns the filter param" do
      subject

      expect(model_instance.filters)
        .to(be_all { |f| f.is_a?(Queries::Projects::Filters::Base) })

      expect(model_instance.filters.map { |f| [f.name, f.operator, f.values] })
        .to eql [[:id, "=", %w[1 2 3]], [:active, "!", ["t"]]]
    end

    it "assigns the orders param" do
      subject

      expect(model_instance.orders)
        .to(be_all { |f| f.is_a?(Queries::Orders::Base) })

      expect(model_instance.orders.map { |o| [o.name, o.direction] })
        .to eql [["id", :asc], ["name", :desc]]
    end
  end

  context "without params" do
    let(:params) do
      {}
    end

    it "assigns a default orders" do
      subject

      expect(model_instance.orders)
        .to(be_all { |f| f.is_a?(Queries::Orders::Base) })

      expect(model_instance.orders.map { |o| [o.name, o.direction] })
        .to eql [%i[lft asc]]
    end

    it "assigns a default filter param" do
      subject

      expect(model_instance.filters)
        .to(be_all { |f| f.is_a?(Queries::Projects::Filters::Base) })

      expect(model_instance.filters.map { |f| [f.name, f.operator, f.values] })
        .to eql [[:active, "=", %w[t]]]
    end

    # rubocop:disable Naming/VariableNumber
    it "assigns default selects for non admin",
       with_settings: { enabled_projects_columns: %w[name created_at cf_1] } do
      subject

      expect(model_instance.selects.map(&:attribute))
        .to eql %i[favored name cf_1]
    end

    it "assigns default selects for admin",
       with_settings: { enabled_projects_columns: %w[name created_at cf_1] } do
      allow(User.current)
        .to receive(:admin?)
              .and_return(true)

      subject

      expect(model_instance.selects.map(&:attribute))
        .to eql %i[favored name created_at cf_1]
    end
    # rubocop:enable Naming/VariableNumber
  end

  context "with the query already having order and with order params" do
    let(:model_instance) do
      ProjectQuery.new.tap do |query|
        query.order(lft: :asc)
      end
    end

    let(:params) do
      {
        orders: [
          {
            attribute: "id",
            direction: "asc"
          },
          {
            attribute: "name",
            direction: "desc"
          }
        ]
      }
    end

    it "assigns the orders param" do
      subject

      expect(model_instance.orders)
        .to(be_all { |f| f.is_a?(Queries::Orders::Base) })

      expect(model_instance.orders.map { |o| [o.name, o.direction] })
        .to eql [["id", :asc], ["name", :desc]]
    end
  end

  context "with the query already having filters and with filter params" do
    let(:model_instance) do
      ProjectQuery.new.tap do |query|
        query.where("active", "=", ["t"])
      end
    end

    let(:params) do
      {
        filters: [
          {
            attribute: "id",
            operator: "=",
            values: %w[1 2 3]
          }
        ]
      }
    end

    it "assigns the filter param" do
      subject

      expect(model_instance.filters)
        .to(be_all { |f| f.is_a?(Queries::Projects::Filters::Base) })

      expect(model_instance.filters.map { |f| [f.name, f.operator, f.values] })
        .to eql [[:id, "=", %w[1 2 3]]]
    end
  end

  context "with the query already having selects and with selects params" do
    let(:model_instance) do
      ProjectQuery.new.tap do |query|
        query.select(:id, :name)
      end
    end

    let(:params) do
      {
        selects: %w[project_status created_at]
      }
    end

    it "assigns the select param" do
      subject
      expect(model_instance.selects.map(&:attribute))
        .to eql %i[project_status created_at]
    end
  end

  context "with an invalid contract" do
    let(:contract_valid) { false }

    it "returns failure" do
      expect(subject)
        .not_to be_success
    end

    it "returns the contract's errors" do
      expect(subject.errors)
        .to eql(contract_errors)
    end
  end
end
