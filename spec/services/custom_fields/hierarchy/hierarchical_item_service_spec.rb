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

require "dry/monads/all"

require "rails_helper"

RSpec.describe CustomFields::Hierarchy::HierarchicalItemService do
  let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }
  let(:invalid_custom_field) { create(:custom_field, field_format: "text", hierarchy_root: nil) }

  subject { described_class.new(custom_field) }

  describe "#initialize" do
    context "with valid custom field" do
      it "initializes successfully" do
        expect { subject }.not_to raise_error
      end
    end

    context "with invalid custom field" do
      it "raises an ArgumentError" do
        expect { described_class.new(invalid_custom_field) }.to raise_error(ArgumentError, /Invalid custom field/)
      end
    end
  end

  describe "#generate_root" do
    context "with valid hierarchy root" do
      it "creates a root item successfully" do
        expect(subject.generate_root).to be_success
      end
    end

    context "with persistence of hierarchy root fails" do
      it "fails to create a root item" do
        allow(CustomField::Hierarchy::Item)
          .to receive(:create)
                .and_return(instance_double(CustomField::Hierarchy::Item, persisted?: false, errors: "some errors"))

        result = subject.generate_root
        expect(result).to be_failure
      end
    end
  end

  describe "#insert_item" do
    let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: parent) }

    let(:parent) { create(:hierarchy_item) }
    let(:label) { "Child Item" }
    let(:short) { "Short Description" }

    context "with valid parameters" do
      it "inserts an item successfully without short" do
        result = subject.insert_item(parent:, label:)
        expect(result).to be_success
      end

      it "inserts an item successfully with short" do
        result = subject.insert_item(parent:, label:, short:)
        expect(result).to be_success
      end
    end

    context "with invalid item" do
      it "fails to insert an item" do
        # rubocop:disable RSpec/VerifiedDoubles
        children = double(create: instance_double(CustomField::Hierarchy::Item, persisted?: false, errors: "some errors"))
        # rubocop:enable RSpec/VerifiedDoubles

        allow(parent).to receive(:children).and_return(children)

        result = subject.insert_item(parent:, label:, short:)
        expect(result).to be_failure
      end
    end
  end

  describe "#update_item" do
    let(:items) do
      Dry::Monads::Do.() do
        root = Dry::Monads::Do.bind subject.generate_root
        luke = Dry::Monads::Do.bind subject.insert_item(parent: root, label: "luke")
        leia = Dry::Monads::Do.bind subject.insert_item(parent: root, label: "leia")

        Dry::Monads::Success({ root:, luke:, leia: })
      end
    end

    context "with valid parameters" do
      it "updates the item with new attributes" do
        result = subject.update_item(item: items.value![:luke], label: "Luke Skywalker", short: "LS")
        expect(result).to be_success
      end
    end

    context "with invalid parameters" do
      it "refuses to update the item with new attributes" do
        result = subject.update_item(item: items.value![:luke], label: "leia", short: "LS")
        expect(result).to be_failure
      end
    end
  end

  describe "#delete_branch" do
    let(:items) do
      Dry::Monads::Do.() do
        root = Dry::Monads::Do.bind subject.generate_root
        luke = Dry::Monads::Do.bind subject.insert_item(parent: root, label: "luke")
        leia = Dry::Monads::Do.bind subject.insert_item(parent: luke, label: "leia")

        Dry::Monads::Success({ root:, luke:, leia: })
      end
    end

    before do
      items
    end

    context "with valid item to destroy" do
      it "deletes the entire branch" do
        result = subject.delete_branch(item: items.value![:luke])
        expect(result).to be_success
        expect(items.value![:luke]).to be_frozen
        expect(CustomField::Hierarchy::Item.all).to be_one
        expect(items.value![:root].reload.children).to be_empty
      end
    end

    context "with root item" do
      it "refuses to delete the item" do
        result = subject.delete_branch(item: items.value![:root])
        expect(result).to be_failure
      end
    end
  end
end
