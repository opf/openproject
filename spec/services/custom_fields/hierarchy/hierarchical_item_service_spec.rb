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

require "rails_helper"

RSpec.describe CustomFields::Hierarchy::HierarchicalItemService do
  let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }
  let(:invalid_custom_field) { create(:custom_field, field_format: "text", hierarchy_root: nil) }

  describe "#initialize" do
    context "with valid custom field" do
      it "initializes successfully" do
        expect { described_class.new(custom_field) }.not_to raise_error
      end
    end

    context "with invalid custom field" do
      it "raises an ArgumentError" do
        expect { described_class.new(invalid_custom_field) }.to raise_error(ArgumentError, /Invalid custom field/)
      end
    end
  end

  describe "#generate_root" do
    let(:service) { described_class.new(custom_field) }

    context "with valid hierarchy root" do
      it "creates a root item successfully" do
        expect(service.generate_root).to be_success
      end
    end

    context "with persistence of hierarchy root fails" do
      it "fails to create a root item" do
        allow(CustomField::Hierarchy::Item)
          .to receive(:create)
                .and_return(instance_double(CustomField::Hierarchy::Item, persisted?: false, errors: "some errors"))

        result = service.generate_root
        expect(result).to be_failure
      end
    end
  end

  describe "#insert_item" do
    let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: parent) }
    let(:service) { described_class.new(custom_field) }

    let(:parent) { create(:hierarchy_item) }
    let(:label) { "Child Item" }
    let(:short) { "Short Description" }

    context "with valid parameters" do
      it "inserts an item successfully without short" do
        result = service.insert_item(parent:, label:)
        expect(result).to be_success
      end

      it "inserts an item successfully with short" do
        result = service.insert_item(parent:, label:, short:)
        expect(result).to be_success
      end
    end

    context "with invalid item" do
      it "fails to insert an item" do
        allow(CustomField::Hierarchy::Item)
          .to receive(:create).and_return(instance_double(CustomField::Hierarchy::Item,
                                                          persisted?: false, errors: "some errors"))

        result = service.insert_item(parent:, label:, short:)
        expect(result).to be_failure
      end
    end
  end
end
