# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

# These builders emit SQL fragments, so the specs execute them rather than matching their
# text: the shape of the generated SQL is not the contract, the resolution it produces is.
RSpec.describe TypeVariant::FormConfigurationSql do
  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  # Runs the remap fragment over project_types, keyed by each row's own variant id.
  def remap_by_own_id
    join, source_expr, excluded_expr = described_class.remap("pt.variant_id")

    rows(<<~SQL.squish)
      SELECT pt.variant_id AS own_id,
             #{source_expr} AS source_id,
             array_to_string(#{excluded_expr}, ',') AS excluded
      FROM project_types pt
      #{join}
    SQL
  end

  # Runs the driving-table fragment over the given variant ids, keyed by own variant id.
  def source_table_by_own_id(variant_ids)
    join, source_expr, excluded_expr = described_class.source_table(variant_ids)

    rows(<<~SQL.squish)
      SELECT wp_variants.own_id AS own_id,
             #{source_expr} AS source_id,
             array_to_string(#{excluded_expr}, ',') AS excluded
      FROM (SELECT 1) AS driver
      #{join}
    SQL
  end

  def rows(sql)
    ActiveRecord::Base.connection.select_all(sql).to_a.index_by { |row| row["own_id"] }
  end

  describe ".remap" do
    let!(:owner) { create(:type) }
    let!(:linked) { create(:type) }
    let!(:project) { create(:project, types: [owner, linked]) }

    let(:owner_variant) { owner.default_variant }
    let(:linked_variant) { linked.default_variant }

    it "resolves an unlinked variant to itself and excludes nothing" do
      row = remap_by_own_id[owner_variant.id]

      expect(row["source_id"]).to eq(owner_variant.id)
      expect(row["excluded"]).to eq("")
    end

    it "resolves a linked variant to its source" do
      link_configuration(linked_variant, source: owner_variant, aspect:)

      expect(remap_by_own_id[linked_variant.id]["source_id"]).to eq(owner_variant.id)
    end

    it "resolves multi-hop chains to the terminal owner" do
      middle = create(:type)
      project.project_types.create!(type: middle)
      link_configuration(middle.default_variant, source: owner_variant, aspect:)
      link_configuration(linked_variant, source: middle.default_variant, aspect:)

      resolved = remap_by_own_id

      expect(resolved[linked_variant.id]["source_id"]).to eq(owner_variant.id)
      expect(resolved[middle.default_variant.id]["source_id"]).to eq(owner_variant.id)
    end

    it "carries the exclusions accumulated along the chain" do
      middle = create(:type)
      project.project_types.create!(type: middle)
      middle.default_variant.update!(form_configuration_source: owner_variant,
                                     form_configuration_excluded_elements: %w[custom_field_1])
      linked_variant.update!(form_configuration_source: middle.default_variant,
                             form_configuration_excluded_elements: %w[custom_field_2])

      resolved = remap_by_own_id

      expect(resolved[linked_variant.id]["excluded"].split(","))
        .to contain_exactly("custom_field_1", "custom_field_2")
      expect(resolved[middle.default_variant.id]["excluded"]).to eq("custom_field_1")
      expect(resolved[owner_variant.id]["excluded"]).to eq("")
    end

    it "resolves every variant without querying to build the SQL" do
      middle = create(:type)
      link_configuration(middle.default_variant, source: owner_variant, aspect:)
      link_configuration(linked_variant, source: middle.default_variant, aspect:)

      # The chain is resolved inside the caller's query, so building the fragment
      # issues nothing at all.
      expect { described_class.remap("pt.variant_id") }.to have_a_query_limit(0)
    end

    # The feature flag opens the admin surface; resolution does not depend on it.
    it "resolves the same with the variants flag off", with_flag: { type_variants: false } do
      link_configuration(linked_variant, source: owner_variant, aspect:)

      expect(remap_by_own_id[linked_variant.id]["source_id"]).to eq(owner_variant.id)
    end
  end

  describe ".source_table" do
    let!(:owner) { create(:type) }
    let!(:linked) { create(:type) }

    let(:owner_variant) { owner.default_variant }
    let(:linked_variant) { linked.default_variant }

    it "maps each variant id to itself when unlinked" do
      other = create(:type)

      resolved = source_table_by_own_id([owner_variant.id, other.default_variant.id])

      expect(resolved[owner_variant.id]["source_id"]).to eq(owner_variant.id)
      expect(resolved[other.default_variant.id]["source_id"]).to eq(other.default_variant.id)
    end

    it "maps a linked variant's own id to its source id" do
      link_configuration(linked_variant, source: owner_variant, aspect:)

      resolved = source_table_by_own_id([linked_variant.id])

      expect(resolved[linked_variant.id]["own_id"]).to eq(linked_variant.id)
      expect(resolved[linked_variant.id]["source_id"]).to eq(owner_variant.id)
    end

    it "carries the chain's exclusions" do
      linked_variant.update!(form_configuration_source: owner_variant,
                             form_configuration_excluded_elements: %w[custom_field_1 assignee])

      expect(source_table_by_own_id([linked_variant.id])[linked_variant.id]["excluded"].split(","))
        .to contain_exactly("custom_field_1", "assignee")
    end

    it "issues no query to build the SQL" do
      link_configuration(linked_variant, source: owner_variant, aspect:)

      expect { described_class.source_table([linked_variant.id]) }
        .to have_a_query_limit(0)
    end
  end
end
