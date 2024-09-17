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

RSpec.shared_examples "BaseServices delete service" do
  subject(:service_call) { instance.call(call_attributes) }

  let(:service_class) { described_class }
  let(:namespace) { service_class.to_s.deconstantize }
  let(:model_class) { namespace.singularize.constantize }
  let(:contract_class) do
    "#{namespace}::DeleteContract".constantize
  end
  let!(:contract_instance) do
    instance = instance_double(contract_class,
                               valid?: contract_validate_result,
                               validate: contract_validate_result,
                               errors: contract_errors)

    allow(contract_class)
      .to receive(:new)
      .and_return(instance)

    instance
  end
  let(:factory) { namespace.singularize.underscore }

  let(:user) { build_stubbed(:user) }
  let(:instance) do
    described_class.new(user:, model: model_instance, contract_class:)
  end
  let(:call_attributes) { {} }
  let!(:model_instance) { build_stubbed(factory) }

  let(:model_destroy_result) { true }
  let(:contract_validate_result) { true }
  let(:contract_errors) { ActiveModel::Errors.new(instance) }

  before do
    allow(model_instance).to receive(:destroy).and_return(model_destroy_result)
  end

  describe "#contract" do
    it "uses the DestroyContract contract" do
      expect(instance.contract_class).to eql contract_class
    end
  end

  describe "#call" do
    context "when contract validates and the model is destroyed successfully" do
      it "is successful" do
        expect(subject).to be_success
      end

      it "returns the destroyed model as a result" do
        result = subject.result
        expect(result).to eql model_instance
      end
    end

    context "when contract does not validate" do
      let(:contract_validate_result) { false }

      it "is unsuccessful" do
        expect(subject).to be_failure
      end

      it "returns the contract errors" do
        expect(subject.errors)
          .to eql contract_errors
      end
    end

    context "when model cannot be destroyed" do
      let(:model_destroy_result) { false }
      let(:model_errors) { ActiveModel::Errors.new(model_instance) }

      it "is unsuccessful" do
        expect(subject)
          .to be_failure
      end

      it "returns the user's errors" do
        model_errors.add :base, "This is some error."

        allow(model_instance)
          .to(receive(:errors))
          .and_return model_errors

        expect(subject.errors).to eql model_errors
        expect(subject.errors[:base]).to include "This is some error."
      end
    end
  end
end
