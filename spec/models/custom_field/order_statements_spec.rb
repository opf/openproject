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

RSpec.describe CustomField::OrderStatements do
  # integration tests at spec/models/query/results_cf_sorting_integration_spec.rb
  context "when hierarchy", with_ee: [:custom_field_hierarchies] do
    let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
    let(:item) { custom_field.hierarchy_root }
    let(:contract_class) { CustomFields::Hierarchy::InsertHierarchyItemContract }

    subject(:custom_field) { create(:hierarchy_wp_custom_field) }

    before do
      service.insert_item(contract_class:, parent: item, label: "Test")
    end

    describe "#order_statement" do
      it { expect(subject.order_statement).to eq("cf_order_#{custom_field.id}.value") }
    end

    describe "#order_join_statement" do
      it "must be equal" do
        expect(custom_field.order_join_statement).to eq(<<-SQL.squish)
          LEFT OUTER JOIN (
            SELECT DISTINCT ON (cv.customized_id) cv.customized_id
                 , item.position_cache "value"
                 , cv.value ids
            FROM "custom_values" cv INNER JOIN "hierarchical_items" item ON item.id = cv.value::bigint
            WHERE cv.customized_type = 'WorkPackage' AND cv.custom_field_id = #{custom_field.id}
                  AND cv.value IS NOT NULL AND cv.value != '' ORDER BY cv.customized_id, cv.id
          ) cf_order_#{custom_field.id} ON cf_order_#{custom_field.id}.customized_id = "work_packages".id
        SQL
      end
    end
  end
end
