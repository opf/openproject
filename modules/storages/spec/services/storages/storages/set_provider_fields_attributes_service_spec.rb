# frozen_string_literal: true

#-- copyright
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
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Storages::Storages::SetProviderFieldsAttributesService, type: :model do
  let(:current_user) { build_stubbed(:admin) }
  let(:storage) { build(:nextcloud_storage, :as_automatically_managed) }
  let(:contract_class) { stub_valid_contract(Storages::Storages::BaseContract) }

  subject(:provider_fields_attributes_service) do
    described_class.new(user: current_user, model: storage, contract_class:).call
  end

  before { allow(storage).to receive(:valid?).and_return(true) }

  context "when automatically_managed is not set" do
    let(:storage) { build(:nextcloud_storage, provider_fields: {}) }

    it "sets automatically_managed to true" do
      expect { provider_fields_attributes_service }
        .to change(storage, :provider_fields).from({}).to({ "automatically_managed" => true })

      aggregate_failures "returns the storage model object as the result" do
        expect(provider_fields_attributes_service.result).to eq(storage)
      end

      aggregate_failures "is valid contract" do
        expect(provider_fields_attributes_service).to be_a_success
      end
    end
  end

  context "when automatically_managed is already set as true" do
    let(:storage) { build(:nextcloud_storage, :as_automatically_managed) }

    it "retains the set value, does not change the object" do
      expect { provider_fields_attributes_service }.not_to change(storage, :provider_fields)
      expect(provider_fields_attributes_service.result.automatically_managed).to be(true)

      aggregate_failures "returns the storage model object as the result" do
        expect(provider_fields_attributes_service.result).to eq(storage)
      end

      aggregate_failures "is valid contract" do
        expect(provider_fields_attributes_service).to be_a_success
      end
    end
  end

  context "when automatically_managed is set as false" do
    let(:storage) { build(:nextcloud_storage, :as_not_automatically_managed) }

    it "retains the set value, does not change the object" do
      expect { provider_fields_attributes_service }.not_to change(storage, :provider_fields)
      expect(provider_fields_attributes_service.result.automatically_managed).to be(false)

      aggregate_failures "returns the storage model object as the result" do
        expect(provider_fields_attributes_service.result).to eq(storage)
      end

      aggregate_failures "is valid contract" do
        expect(provider_fields_attributes_service).to be_a_success
      end
    end
  end

  def stub_valid_contract(contract_class)
    contract_errors = instance_double(ActiveModel::Errors, "contract_errors")
    contract_valid = true
    contract_instance = stub_contract_instance(contract_class, contract_valid, contract_errors)
    allow(contract_class).to receive(:new).and_return(contract_instance)

    contract_class
  end

  def stub_contract_instance(contract_class, contract_valid, contract_errors)
    contract_instance = instance_double(contract_class, "contract_instance")
    allow(contract_instance).to receive_messages(validate: contract_valid, errors: contract_errors)
    contract_instance
  end
end
