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

RSpec.describe Exports::Formatters::CustomField, with_ee: [:custom_field_hierarchies] do
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let(:custom_field) { create(:custom_field, field_format: "hierarchy") }
  let(:root) { custom_field.hierarchy_root }
  let(:contract_class) { CustomFields::Hierarchy::InsertHierarchyItemContract }
  let!(:homer) { service.insert_item(contract_class:, parent: root, label: "Homer", short: "HS").value! }
  let!(:bart) { service.insert_item(contract_class:, parent: homer, label: "Bart", short: "BS").value! }
  let!(:lisa) { service.insert_item(contract_class:, parent: homer, label: "Lisa").value! }
  let!(:zia) { service.insert_item(contract_class:, parent: lisa, label: "Zia").value! }
  let(:work_package) do
    cf = build_stubbed(:work_package)
    allow(cf)
      .to receive(:custom_value_for)
            .and_return(custom_values)
    cf
  end
  let!(:custom_values) { [] }

  subject { described_class.new("cf_hierarchy") }

  describe "#format_for_export" do
    describe "with empty values" do
      it "returns empty string" do
        expect(subject.format_for_export(work_package, custom_field)).to eq("")
      end
    end

    describe "with a single label with short" do
      let(:custom_values) do
        [CustomValue.new(custom_field:, value: bart.id)]
      end

      it "returns the ancestors, label and short" do
        expect(subject.format_for_export(work_package, custom_field)).to eq("Homer / Bart (BS)")
      end
    end

    describe "with a single label only" do
      let(:custom_values) do
        [CustomValue.new(custom_field:, value: lisa.id)]
      end

      it "returns the ancestors and label" do
        expect(subject.format_for_export(work_package, custom_field)).to eq("Homer / Lisa")
      end
    end

    describe "with multiple values" do
      let(:custom_values) do
        [
          CustomValue.new(custom_field:, value: homer.id),
          CustomValue.new(custom_field:, value: bart.id),
          CustomValue.new(custom_field:, value: lisa.id),
          CustomValue.new(custom_field:, value: zia.id)
        ]
      end

      it "returns multiple comma-separated values" do
        expect(subject.format_for_export(work_package, custom_field))
          .to eq("Homer (HS), Homer / Bart (BS), Homer / Lisa, Homer / Lisa / Zia")
      end
    end
  end
end
