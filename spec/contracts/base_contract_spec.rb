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

RSpec.describe BaseContract do
  let(:model) { WorkPackage.new }
  let(:current_errors) { model.errors }
  let(:user) { build(:user) }

  describe ".writable_attributes" do
    it "returns attributes with `writable: true`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: true
      end
      expect(contract_class.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "does not return attributes with `writable: false`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: false
      end
      expect(contract_class.writable_attributes).to be_empty
    end

    it "returns attributes with `writable: nil`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: nil
      end
      expect(contract_class.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "returns attributes without `:writable` parameter (same as `writable: nil`)" do
      contract_class = Class.new(BaseContract) do
        attribute :name
      end
      expect(contract_class.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "returns attributes with `writable: -> { true }`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: -> { true }
      end
      expect(contract_class.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "returns attributes with `writable: -> { false }`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: -> { false }
      end
      expect(contract_class.writable_attributes).to contain_exactly("name", "name_id")
    end
  end

  describe "#writable_attributes" do
    it "returns attributes with `writable: true`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: true
      end
      contract = contract_class.new(model, user)
      expect(contract.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "does not return attributes with `writable: false`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: false
      end
      contract = contract_class.new(model, user)
      expect(contract.writable_attributes).to be_empty
    end

    it "returns attributes with `writable: nil`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: nil
      end
      contract = contract_class.new(model, user)
      expect(contract.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "returns attributes without `:writable` parameter (same as `writable: nil`)" do
      contract_class = Class.new(BaseContract) do
        attribute :name
      end
      contract = contract_class.new(model, user)
      expect(contract.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "returns attributes with `writable: -> { true }`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: -> { true }
      end
      contract = contract_class.new(model, user)
      expect(contract.writable_attributes).to contain_exactly("name", "name_id")
    end

    it "does not return attributes with `writable: -> { false }`" do
      contract_class = Class.new(BaseContract) do
        attribute :name, writable: -> { false }
      end
      contract = contract_class.new(model, user)
      expect(contract.writable_attributes).to be_empty
    end

    shared_examples "the parent writable parameter is overridden by the child writable parameter" do
      it "returns it when redefined with `writable: nil` in the child class" do
        child_contract_class = Class.new(parent_contract_class) do
          attribute :name, writable: nil
        end
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it "returns it when redefined without `:writable` parameter (same as `writable: nil`)" do
        child_contract_class = Class.new(parent_contract_class) do
          attribute :name
        end
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it "returns it when redefined as `writable: true` in the child class" do
        child_contract_class = Class.new(parent_contract_class) do
          attribute :name, writable: true
        end
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it "does not return it when redefined as `writable: false` in the child class" do
        child_contract_class = Class.new(parent_contract_class) do
          attribute :name, writable: false
        end
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to be_empty
      end

      it "returns it when redefined as `writable: -> { true }`" do
        child_contract_class = Class.new(parent_contract_class) do
          attribute :name, writable: -> { true }
        end
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it "does not return it when redefined as `writable: -> { false }`" do
        child_contract_class = Class.new(parent_contract_class) do
          attribute :name, writable: -> { false }
        end
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to be_empty
      end
    end

    context "when the attribute is defined as `writable: true` in the parent" do
      let(:parent_contract_class) do
        Class.new(BaseContract) do
          attribute :name, writable: true
        end
      end

      it "returns it when not redefined in the child class" do
        child_contract_class = Class.new(parent_contract_class)
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it_behaves_like "the parent writable parameter is overridden by the child writable parameter"
    end

    context "when the attribute is defined as `writable: false` in the parent" do
      let(:parent_contract_class) do
        Class.new(BaseContract) do
          attribute :name, writable: false
        end
      end

      it "does not return it when not redefined in the child class" do
        child_contract_class = Class.new(parent_contract_class)
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to be_empty
      end

      it_behaves_like "the parent writable parameter is overridden by the child writable parameter"
    end

    context "when the attribute has not defined `:writable` in the parent" do
      let(:parent_contract_class) do
        Class.new(BaseContract) do
          attribute :name
        end
      end

      it "returns it when not redefined in the child class" do
        child_contract_class = Class.new(parent_contract_class)
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it_behaves_like "the parent writable parameter is overridden by the child writable parameter"
    end

    context "when the attribute is defined as `writable: -> { true }` in the parent" do
      let(:parent_contract_class) do
        Class.new(BaseContract) do
          attribute :name, writable: -> { true }
        end
      end

      it "returns it when not redefined in the child class" do
        child_contract_class = Class.new(parent_contract_class)
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to contain_exactly("name", "name_id")
      end

      it_behaves_like "the parent writable parameter is overridden by the child writable parameter"
    end

    context "when the attribute is defined as `writable: -> { false }` in the parent" do
      let(:parent_contract_class) do
        Class.new(BaseContract) do
          attribute :name, writable: -> { false }
        end
      end

      it "does not return it when not redefined in the child class" do
        child_contract_class = Class.new(parent_contract_class)
        contract = child_contract_class.new(model, user)
        expect(contract.writable_attributes).to be_empty
      end

      it_behaves_like "the parent writable parameter is overridden by the child writable parameter"
    end

    describe "adding available_custom_fields" do
      let(:contract_class) do
        Class.new(BaseContract) do
          attribute :name, writable: true
        end
      end
      let(:contract) { contract_class.new(model, user) }
      let(:custom_field_a) { build_stubbed(:custom_field) }
      let(:custom_field_b) { build_stubbed(:custom_field) }

      before do
        allow(model).to receive(:available_custom_fields).and_return([custom_field_a, custom_field_b])
      end

      it "includes custom field attribute names" do
        expect(contract.writable_attributes).to contain_exactly(
          "name",
          "name_id",
          custom_field_a.attribute_name,
          custom_field_b.attribute_name
        )
      end

      it "includes comment attribute names when custom field has comments" do
        custom_field_a.has_comment = true

        expect(contract.writable_attributes).to contain_exactly(
          "name",
          "name_id",
          custom_field_a.attribute_name,
          custom_field_b.attribute_name,
          custom_field_a.comment_attribute_name
        )
      end
    end
  end

  describe "#validate_and_merge_errors" do
    subject { current_contract.send(:validate_and_merge_errors, other_contract) }

    let(:current_contract) { described_class.new(model, user) }
    let(:other_contract) { double("contract", errors: other_errors) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      current_errors.add(:base, :invalid)
      allow(other_contract).to receive(:validate) do
        other_contract.errors.add(:base, :blank)
      end
    end

    context "when the other contract has an own #errors instance" do
      let(:other_errors) { ActiveModel::Errors.new(nil) }

      it "merges errors of current contract and other contract" do
        subject
        expect(current_contract.errors.details[:base].map { |d| d[:error] }).to eq(%i[invalid blank])
      end
    end

    context "when the other contract shares errors instance with current contract" do
      let(:other_errors) { current_errors }

      it "merges errors of current contract and other contract (without duplicates)" do
        subject
        expect(current_contract.errors.details[:base].map { |d| d[:error] }).to eq(%i[invalid blank])
      end
    end
  end
end
