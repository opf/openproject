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

RSpec.describe CustomValue::WeightedItemListStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) { instance_double(CustomValue, value:, custom_field:, customized:) }
  let(:customized) { instance_double(Project) }
  let(:custom_field) { build(:custom_field, hierarchy_root:) }
  let(:hierarchy_item) { build_stubbed(:hierarchy_item, weight: 42) }
  let(:hierarchy_root) { build_stubbed(:hierarchy_item) }

  before do
    allow(CustomField::Hierarchy::Item).to receive(:find_by)
  end

  describe "#parse_value/#typed_value" do
    subject { instance }

    context "with a hierarchy item" do
      let(:value) { hierarchy_item }

      it "returns the hierarchy item and sets it for later retrieval" do
        expect(subject.parse_value(value)).to eql hierarchy_item.id.to_s

        expect(subject.typed_value).to eq 42

        expect(CustomField::Hierarchy::Item).not_to have_received(:find_by)
      end

      context "without weight set" do
        let(:hierarchy_item) { build_stubbed(:hierarchy_item) }

        it "returns nil for typed value" do
          expect(subject.parse_value(value)).to eql hierarchy_item.id.to_s

          expect(subject.typed_value).to be_nil

          expect(CustomField::Hierarchy::Item).not_to have_received(:find_by)
        end
      end
    end

    context "with an id string" do
      let(:value) { hierarchy_item.id.to_s }

      it "returns the string and has to later find the hierarchy item" do
        allow(CustomField::Hierarchy::Item)
          .to receive(:find_by)
          .with(id: hierarchy_item.id.to_s)
          .and_return(hierarchy_item)

        expect(subject.parse_value(value)).to eql value

        expect(subject.typed_value).to eq 42
      end

      context "without weight set" do
        let(:hierarchy_item) { build_stubbed(:hierarchy_item) }

        it "returns nil for typed value" do
          allow(CustomField::Hierarchy::Item)
            .to receive(:find_by)
            .with(id: hierarchy_item.id.to_s)
            .and_return(hierarchy_item)

          expect(subject.parse_value(value)).to eql value

          expect(subject.typed_value).to be_nil
        end
      end
    end

    context "with an id string of missing item" do
      let(:value) { hierarchy_item.id.to_s }

      it "returns the string and typed_value is nil (missing item)" do
        expect(subject.parse_value(value)).to eql value
        expect(subject.typed_value).to be_nil
      end
    end

    context "when value is blank" do
      let(:value) { "" }

      it "is nil and does not look for the hierarchy_item" do
        expect(subject.parse_value(value)).to be_nil

        expect(subject.typed_value).to be_nil

        expect(CustomField::Hierarchy::Item).not_to have_received(:find_by)
      end
    end

    context "when value is nil" do
      let(:value) { nil }

      it "is nil and does not look for the hierarchy item" do
        expect(subject.parse_value(value)).to be_nil

        expect(subject.typed_value).to be_nil

        expect(CustomField::Hierarchy::Item).not_to have_received(:find_by)
      end
    end
  end

  describe "#formatted_value" do
    subject { instance.formatted_value }

    context "with an id string" do
      let(:value) { hierarchy_item.id.to_s }

      before do
        hierarchy_item.label = "Foo Bar Baz"

        allow(CustomField::Hierarchy::Item)
          .to receive(:find_by)
          .with(id: hierarchy_item.id.to_s)
          .and_return(hierarchy_item)
      end

      it "is the hierarchy item label" do
        expect(subject).to eql "Foo Bar Baz (42)"
      end

      context "when item has short value" do
        before do
          hierarchy_item.short = "foo"
        end

        it "is the hierarchy item label and short" do
          expect(subject).to eql "Foo Bar Baz (foo)"
        end
      end
    end

    context "with an id string of missing item" do
      let(:value) { hierarchy_item.id.to_s }

      it "is the hierarchy item to_s (with db access)" do
        expect(subject).to eql "#{hierarchy_item.id} not found"
      end
    end

    context "when value is blank" do
      let(:value) { "" }

      it "is empty and does not look for the hierarchy item" do
        expect(subject).to eql ""

        expect(CustomField::Hierarchy::Item).not_to have_received(:find_by)
      end
    end

    context "when value is nil" do
      let(:value) { nil }

      it "is empty and does not look for the hierarchy item" do
        expect(subject).to eql ""

        expect(CustomField::Hierarchy::Item).not_to have_received(:find_by)
      end
    end
  end

  describe "#validate_type_of_value" do
    subject { instance.validate_type_of_value }

    let(:value) { hierarchy_item.id.to_s }

    context "when value is an id of missing item" do
      it "rejects" do
        expect(subject).to be :invalid
      end
    end

    context "when value is an id of existing item" do
      before do
        allow(CustomField::Hierarchy::Item)
          .to receive(:find_by)
          .with(id: hierarchy_item.id.to_s)
          .and_return(hierarchy_item)

        hierarchical_item_service = instance_double(CustomFields::Hierarchy::HierarchicalItemService)
        service_result = (is_descendant ? Dry::Monads::Success : Dry::Monads::Failure).new(nil)

        allow(CustomFields::Hierarchy::HierarchicalItemService)
          .to receive(:new)
          .and_return(hierarchical_item_service)

        allow(hierarchical_item_service)
          .to receive(:descendant_of?)
          .with(item: hierarchy_item, parent: hierarchy_root)
          .and_return(service_result)
      end

      context "when item is not a descendant of custom_field hierarchy root" do
        let(:is_descendant) { false }

        it "rejects" do
          expect(subject).to be :inclusion
        end
      end

      context "when item is a descendant of custom_field hierarchy root" do
        let(:is_descendant) { true }

        it "accepts" do
          expect(subject).to be_nil
        end
      end
    end
  end
end
