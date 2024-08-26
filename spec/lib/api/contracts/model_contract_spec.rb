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

require "spec_helper"

RSpec.describe ModelContract do
  let(:model) do
    double("The model",
           child_attribute: nil,
           grand_child_attribute: nil,
           overwritten_attribute: nil,
           custom_field1: nil,
           not_allowed: nil,
           changed: [],
           valid?: true,
           new_record?: false,
           errors: ActiveModel::Errors.new(nil))
  end

  context "with child and grand_child" do
    let(:child_contract_class) do
      Class.new(ModelContract) do
        attr_accessor :child_value

        attribute :child_attribute
        attribute :overwritten_attribute do
          @child_value = 1
        end
      end
    end
    let(:child_contract) { child_contract_class.new(model, nil) }

    let(:grand_child_contract_class) do
      Class.new(child_contract_class) do
        attr_accessor :grand_child_value

        attribute :grand_child_attribute
        attribute :overwritten_attribute do
          @grand_child_value = 2
        end
      end
    end
    let(:grand_child_contract) { grand_child_contract_class.new(model, nil) }

    before do
      child_contract.child_value = 0
      grand_child_contract.child_value = 0
    end

    describe "child" do
      it "collects its own writable attributes" do
        expect(child_contract.writable_attributes).to include("child_attribute",
                                                              "overwritten_attribute")
      end

      it "collects its own attribute validations" do
        child_contract.validate
        expect(child_contract.child_value).to eq(1)
      end
    end

    describe "grand_child" do
      it "considers its ancestor writable attributes" do
        expect(grand_child_contract.writable_attributes).to include("child_attribute",
                                                                    "overwritten_attribute",
                                                                    "grand_child_attribute")
      end

      it "does not contain the same attribute twice, but also has the _id variant" do
        expect(grand_child_contract.writable_attributes.count).to eq(6)
      end

      it "executes all the validations" do
        grand_child_contract.validate
        expect(grand_child_contract.child_value).to eq(1)
        expect(grand_child_contract.grand_child_value).to eq(2)
      end
    end
  end

  describe "valid?" do
    let(:model_contract_class) do
      Class.new(ModelContract) do
        attribute :custom_field1
        attribute :not_allowed
      end
    end
    let(:model_contract) { model_contract_class.new(model, nil) }

    context "when the model extends no plugins" do
      before do
        allow(model).to receive(:changed).and_return([:custom_field1])
      end

      it "adds an error to the custom field attribute" do
        model_contract.valid?
        expect(model_contract.errors.symbols_for(:custom_field1))
          .to include(:error_readonly)
      end
    end

    context "when the model extends the acts_as_customizable plugin" do
      before do
        allow(model).to receive(:changed_with_custom_fields).and_return([:custom_field1])
      end

      it "adds an error to the custom field attribute" do
        model_contract.valid?
        expect(model_contract.errors.symbols_for(:custom_field1))
          .to include(:error_readonly)
      end
    end

    context "when the model extends the OpenProject::ChangedBySystem module" do
      before do
        allow(model).to receive(:changed_by_user).and_return([:custom_field1])
      end

      it "adds an error to the custom field attribute" do
        model_contract.valid?
        expect(model_contract.errors.symbols_for(:custom_field1))
          .to include(:error_readonly)
      end
    end

    context "when the model extends both modules" do
      before do
        allow(model).to receive(:changed_by_user).and_return([:custom_field1])
        allow(model).to receive(:changed_with_custom_fields).and_return([:no_allowed])
      end

      it "adds an error to the custom field attribute from the OpenProject::ChangedBySystem module" do
        model_contract.valid?
        expect(model_contract.errors.symbols_for(:custom_field1))
          .to include(:error_readonly)
      end
    end
  end
end
