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

RSpec.describe Exports::Formatters::HierarchyFormatter, with_ee: [:custom_field_hierarchies] do
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let(:custom_field) { create(:custom_field, field_format: "hierarchy", hierarchy_root: nil) }
  let(:root) { service.generate_root(custom_field).value! }
  let(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }
  let!(:homer) { service.insert_item(contract_class:, parent: root, label: "Homer", short: "HS").value! }
  let!(:bart) { service.insert_item(contract_class:, parent: homer, label: "Bart", short: "BS").value! }
  let!(:lisa) { service.insert_item(contract_class:, parent: homer, label: "Lisa").value! }
  let!(:zia) { service.insert_item(contract_class:, parent: lisa, label: "Zia").value! }

  let(:work_package) do
    wp = build_stubbed(:work_package)
    allow(wp).to receive(:custom_value_for).with(custom_field).and_return(custom_values)
    wp
  end
  let(:custom_values) { [] }

  subject(:formatter) { described_class.new }

  describe "#format" do
    context "with no values" do
      let(:custom_values) { [] }

      it "returns an empty string" do
        expect(formatter.format(work_package, custom_field)).to eq("")
      end
    end

    context "when custom_value_for returns nil" do
      let(:custom_values) { nil }

      it "returns an empty string" do
        expect(formatter.format(work_package, custom_field)).to eq("")
      end
    end

    context "when custom_value_for returns a single value (not wrapped in an array)" do
      let(:custom_values) { CustomValue.new(custom_field:, value: bart.id) }

      it "wraps and formats the single value" do
        expect(formatter.format(work_package, custom_field)).to eq("Homer / Bart (BS)")
      end
    end

    context "with a single value carrying a short" do
      let(:custom_values) { [CustomValue.new(custom_field:, value: bart.id)] }

      it "returns the ancestry path including the short" do
        expect(formatter.format(work_package, custom_field)).to eq("Homer / Bart (BS)")
      end
    end

    context "with a single value without a short" do
      let(:custom_values) { [CustomValue.new(custom_field:, value: lisa.id)] }

      it "returns the ancestry path without a short" do
        expect(formatter.format(work_package, custom_field)).to eq("Homer / Lisa")
      end
    end

    context "with a root-level value" do
      let(:custom_values) { [CustomValue.new(custom_field:, value: homer.id)] }

      it "returns just the item including its short" do
        expect(formatter.format(work_package, custom_field)).to eq("Homer (HS)")
      end
    end

    context "with multiple values" do
      let(:custom_values) do
        [
          CustomValue.new(custom_field:, value: homer.id),
          CustomValue.new(custom_field:, value: bart.id),
          CustomValue.new(custom_field:, value: lisa.id),
          CustomValue.new(custom_field:, value: zia.id)
        ]
      end

      it "returns the values joined by a comma" do
        expect(formatter.format(work_package, custom_field))
          .to eq("Homer (HS), Homer / Bart (BS), Homer / Lisa, Homer / Lisa / Zia")
      end
    end

    context "with a blank value (empty hierarchy field, regression for OP-19798)" do
      let(:custom_values) { [CustomValue.new(custom_field:, value: nil)] }

      it "returns an empty string rather than a 'not found' marker" do
        expect(formatter.format(work_package, custom_field)).to eq("")
      end
    end

    context "with a value referencing a deleted/unknown item" do
      let(:custom_values) { [CustomValue.new(custom_field:, value: "999999")] }

      it "returns the value followed by the 'not found' label" do
        expect(formatter.format(work_package, custom_field))
          .to eq("999999 #{I18n.t(:label_not_found)}")
      end
    end

    context "with a mix of blank, present and unknown values" do
      let(:custom_values) do
        [
          CustomValue.new(custom_field:, value: bart.id),
          CustomValue.new(custom_field:, value: nil),
          CustomValue.new(custom_field:, value: "999999")
        ]
      end

      it "renders blanks as empty segments while keeping present and unknown values" do
        expect(formatter.format(work_package, custom_field))
          .to eq("Homer / Bart (BS), , 999999 #{I18n.t(:label_not_found)}")
      end
    end
  end

  describe "#format_hierarchy_item_for_export" do
    context "with a blank value" do
      it "returns nil (regression for OP-19798)" do
        item_value = CustomValue.new(custom_field:, value: nil)
        expect(formatter.format_hierarchy_item_for_export(item_value)).to be_nil
      end
    end

    context "with a value referencing an existing item" do
      it "returns the item's ancestry path with shorts and weights" do
        item_value = CustomValue.new(custom_field:, value: zia.id)
        expect(formatter.format_hierarchy_item_for_export(item_value)).to eq("Homer / Lisa / Zia")
      end
    end

    context "with a value referencing an unknown item" do
      it "returns the value and the 'not found' label" do
        item_value = CustomValue.new(custom_field:, value: "999999")
        expect(formatter.format_hierarchy_item_for_export(item_value))
          .to eq("999999 #{I18n.t(:label_not_found)}")
      end
    end
  end
end
