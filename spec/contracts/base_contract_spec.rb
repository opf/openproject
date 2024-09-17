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
  let(:model) { double(name: "name") } # rubocop:disable RSpec/VerifiedDoubles
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
  end
end
