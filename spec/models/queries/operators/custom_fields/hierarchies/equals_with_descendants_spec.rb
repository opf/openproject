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

RSpec.describe Queries::Operators::CustomFields::Hierarchies::EqualsWithDescendants, with_ee: [:custom_field_hierarchies] do
  subject(:sql) { described_class.sql_for_field(values, db_table, db_field) }

  let(:custom_field) { create(:hierarchy_wp_custom_field) }
  let!(:root) { custom_field.hierarchy_root }
  let(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }
  let!(:germany) { service.insert_item(contract_class:, parent: root, label: "Germany", short: "DE").value! }
  let!(:berlin) { service.insert_item(contract_class:, parent: germany, label: "Berlin").value! }
  let!(:munich) { service.insert_item(contract_class:, parent: germany, label: "Munich").value! }
  let!(:portugal) { service.insert_item(contract_class:, parent: root, label: "Portugal", short: "PT").value! }
  let!(:lisbon) { service.insert_item(contract_class:, parent: portugal, label: "Lisboa").value! }
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }

  let(:db_table) { "custom_values" }
  let(:db_field) { "value" }

  context "when generating for a branch" do
    let(:values) { [germany.id] }

    it "generates the expected SQL" do
      expect(sql).to eq("custom_values.value IN ('#{germany.id}','#{berlin.id}','#{munich.id}')")
    end
  end

  context "when generating for a leaf" do
    let(:values) { [lisbon.id] }

    it "generates the expected SQL" do
      expect(sql).to eq("custom_values.value IN ('#{lisbon.id}')")
    end
  end
end
