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

RSpec.describe CustomFields::Hierarchy::HierarchicalItemService do
  let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }
  let(:invalid_custom_field) { create(:custom_field, field_format: "text", hierarchy_root: nil) }

  let!(:root) { service.generate_root(custom_field).value! }
  let!(:luke) { service.insert_item(parent: root, label: "luke").value! }
  let!(:leia) { service.insert_item(parent: luke, label: "leia").value! }

  subject(:service) { described_class.new }

  describe "#generate_root" do
    context "with valid hierarchy root" do
      it "creates a root item successfully" do
        expect(service.generate_root(custom_field)).to be_success
      end
    end

    it "requires a custom field of type hierarchy" do
      result = service.generate_root(invalid_custom_field).failure

      expect(result.errors[:custom_field]).to eq(["must have field format 'hierarchy'"])
    end

    context "with persistence of hierarchy root fails" do
      it "fails to create a root item" do
        allow(CustomField::Hierarchy::Item)
          .to receive(:create)
                .and_return(instance_double(CustomField::Hierarchy::Item, new_record?: true, errors: "some errors"))

        result = service.generate_root(custom_field)
        expect(result).to be_failure
      end
    end
  end

  describe "#insert_item" do
    let(:label) { "Child Item" }
    let(:short) { "Short Description" }

    context "with valid parameters" do
      it "inserts an item successfully without short" do
        result = service.insert_item(parent: luke, label:)
        expect(result).to be_success
        expect(luke.reload.children.count).to eq(2)
      end

      it "inserts an item successfully with short" do
        result = service.insert_item(parent: root, label:, short:)
        expect(result).to be_success
      end
    end

    context "with invalid item" do
      it "fails to insert an item" do
        child = instance_double(CustomField::Hierarchy::Item, new_record?: true, errors: "some errors")
        allow(root.children).to receive(:create).and_return(child)

        result = service.insert_item(parent: root, label:, short:)
        expect(result).to be_failure
      end
    end
  end

  describe "#update_item" do
    context "with valid parameters" do
      it "updates the item with new attributes" do
        result = service.update_item(item: luke, label: "Luke Skywalker", short: "LS")
        expect(result).to be_success
      end
    end

    context "with invalid parameters" do
      let!(:leia) { service.insert_item(parent: root, label: "leia").value! }

      it "refuses to update the item with new attributes" do
        result = service.update_item(item: luke, label: "leia", short: "LS")
        expect(result).to be_failure

        errors = result.failure.errors
        expect(errors.to_h).to eq({ label: ["must be unique at the same hierarchical level"] })
      end
    end
  end

  describe "#delete_branch" do
    context "with valid item to destroy" do
      it "deletes the entire branch" do
        result = service.delete_branch(item: luke)
        expect(result).to be_success
        expect(luke).to be_frozen
        expect(CustomField::Hierarchy::Item.count).to eq(1)
        expect(root.reload.children).to be_empty
      end
    end

    context "with root item" do
      it "refuses to delete the item" do
        result = service.delete_branch(item: root)
        expect(result).to be_failure
      end
    end
  end

  describe "#get_branch" do
    context "with a non-root node" do
      it "returns all the ancestors to that item" do
        result = service.get_branch(item: leia)
        expect(result).to be_success

        ancestors = result.value!
        expect(ancestors.size).to eq(2)
        expect(ancestors).to contain_exactly(root, luke)
        expect(ancestors.last).to eq(luke)
      end
    end

    context "with a root node" do
      it "returns a empty list" do
        result = service.get_branch(item: root)
        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end
  end

  describe "#move_item" do
    let(:lando) { service.insert_item(parent: root, label: "lando").value! }

    it "move the node to the new parent" do
      expect { service.move_item(item: leia, new_parent: lando) }.to change { leia.reload.ancestors.first }.to(lando)
    end

    it "all child nodes follow" do
      service.move_item(item: luke, new_parent: lando)

      expect(luke.reload.ancestors).to contain_exactly(root, lando)
      expect(leia.reload.ancestors).to contain_exactly(root, lando, luke)
    end
  end

  describe "reorder_item" do
    let!(:lando) { service.insert_item(parent: root, label: "lando").value! }
    let!(:chewbacca) { service.insert_item(parent: root, label: "AWOOO").value! }

    it "moves the note to the requested position" do
      service.reorder_item(item: chewbacca, new_sort_order: 1)

      expect(luke.reload.sort_order).to eq(0)
      expect(chewbacca.reload.sort_order).to eq(1)
      expect(lando.reload.sort_order).to eq(2)
    end
  end
end
