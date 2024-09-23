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

RSpec.shared_examples "BaseServices create service" do
  let(:service_class) { described_class }
  let(:namespace) { service_class.to_s.deconstantize }
  let(:model_class) { namespace.singularize.constantize }
  let(:contract_class) { "#{namespace}::CreateContract".constantize }
  let(:contract_options) { {} }
  let(:factory) { namespace.singularize.underscore }

  let(:set_attributes_class) { "#{namespace}::SetAttributesService".constantize }

  let(:user) { build_stubbed(:user) }
  let(:instance) do
    described_class.new(user:, contract_class:)
  end
  let(:call_attributes) { { name: "Some name", identifier: "Some identifier" } }
  let(:set_attributes_success) do
    true
  end
  let(:set_attributes_errors) do
    double("set_attributes_errors")
  end
  let(:set_attributes_result) do
    ServiceResult.new result: model_instance,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:model_instance) { build_stubbed(factory) }
  let!(:set_attributes_service) do
    # Do not stub the SetAttributesService when the model is not stubbed
    next unless stub_model_instance

    service = double("set_attributes_service_instance")

    allow(set_attributes_class)
      .to(receive(:new))
      .with(user:,
            model: model_instance,
            contract_class:,
            contract_options:)
      .and_return(service)

    allow(service)
      .to(receive(:call))
      .and_return(set_attributes_result)

    service
  end

  let(:model_save_result) { true }
  let(:contract_validate_result) { true }
  let(:stub_model_instance) { true }

  before do
    allow(model_instance).to receive(:save).and_return(model_save_result)
    allow(instance).to receive(:instance).and_return(model_instance) if stub_model_instance
  end

  subject { instance.call(call_attributes) }

  describe "#user" do
    it "exposes a user which is available as a getter" do
      expect(instance.user).to eql user
    end
  end

  describe "#contract" do
    it "uses the CreateContract contract" do
      expect(instance.contract_class).to eql contract_class
    end
  end

  describe "#call" do
    context "if contract validates and the model saves" do
      it "is successful" do
        expect(subject).to be_success
      end

      it "matches the set attributes errors" do
        expect(subject.errors).to eq(set_attributes_errors)
      end

      it "returns the model as a result" do
        result = subject.result
        expect(result).to be_a model_class
      end
    end

    context "if contract does not validate" do
      let(:set_attributes_success) { false }

      it "is unsuccessful" do
        expect(subject).not_to be_success
      end
    end

    context "if model does not save" do
      let(:model_save_result) { false }
      let(:errors) { double("errors") }

      it "is unsuccessful" do
        expect(subject).not_to be_success
      end

      it "returns the model's errors" do
        allow(model_instance)
          .to(receive(:errors))
          .and_return errors

        expect(subject.errors).to eql errors
      end
    end
  end
end
