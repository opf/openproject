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

RSpec.describe "Work package filtering by hierarchy custom field", :js, with_ee: [:custom_field_hierarchies] do
  let(:project) { create(:project) }
  let(:type) { project.enabled_types.first }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:hierarchy_root) { create(:hierarchy_item) }
  let!(:hierarchy_cf) do
    create(:hierarchy_wp_custom_field, hierarchy_root:).tap do |cf|
      type.default_variant.custom_fields << cf
      project.work_package_custom_fields << cf
    end
  end
  let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
  let(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }
  let!(:luke) { service.insert_item(contract_class:, parent: hierarchy_root, label: "luke").value! }
  let!(:leia) { service.insert_item(contract_class:, parent: hierarchy_root, label: "leia").value! }

  let!(:wp_luke) do
    create(:work_package, project:, subject: "Luke's wp").tap do |wp|
      wp.custom_field_values = { hierarchy_cf.id => luke.id }
      wp.save!
    end
  end
  let!(:wp_leia) do
    create(:work_package, project:, subject: "Leia's wp").tap do |wp|
      wp.custom_field_values = { hierarchy_cf.id => leia.id }
      wp.save!
    end
  end

  let(:admin) { create(:admin) }

  current_user { admin }

  describe "filters" do
    before do
      wp_table.visit!
      wp_table.expect_work_package_listed(wp_luke, wp_leia)
    end

    context "when any" do
      it "shows the work package matching the hierarchy cf filter" do
        filters.open

        # Filtering by hierarchy (=)

        filters.add_filter_by(hierarchy_cf.name, "is (OR)", [luke.label], hierarchy_cf.attribute_name(:camel_case))

        wp_table.ensure_work_package_not_listed!(wp_leia)
        wp_table.expect_work_package_listed(wp_luke)
      end
    end

    context "when is not" do
      it "shows work packages that do not match the hierarchy cf filter" do
        filters.open

        # Filtering by hierarchy (!)

        filters.add_filter_by(hierarchy_cf.name, "is not", [luke.label], hierarchy_cf.attribute_name(:camel_case))

        wp_table.ensure_work_package_not_listed!(wp_luke)
        wp_table.expect_work_package_listed(wp_leia)
      end
    end

    context "when equals with descendants" do
      let!(:grogu) { service.insert_item(contract_class:, parent: luke, label: "Grogu").value! }
      let!(:wp_grogu) do
        create(:work_package, project:, subject: "Grogu's wp").tap do |wp|
          wp.custom_field_values = { hierarchy_cf.id => grogu.id }
          wp.save!
        end
      end

      it "shows the work packages with associated hierarchy items to the branch" do
        filters.open

        # Filtering by hierarchy (!)

        filters.add_filter_by(
          hierarchy_cf.name,
          "is any with descendants",
          [luke.label],
          hierarchy_cf.attribute_name(:camel_case)
        )

        wp_table.ensure_work_package_not_listed!(wp_leia)
        wp_table.expect_work_package_listed(wp_luke, wp_grogu)
      end
    end
  end
end
