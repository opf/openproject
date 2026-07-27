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
RSpec.describe Type::EffectiveSourceSql do
  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

  # Runs the remap fragment over projects_types, keyed by each row's own type id.
  def remap_by_own_id
    join, source_expr, excluded_expr = described_class.form_configuration_remap("pt.type_id")

    rows(<<~SQL.squish)
      SELECT pt.type_id AS own_id,
             #{source_expr} AS source_id,
             array_to_string(#{excluded_expr}, ',') AS excluded
      FROM projects_types pt
      #{join}
    SQL
  end

  # Runs the driving-table fragment over the given type ids, keyed by own type id.
  def source_table_by_own_id(type_ids)
    join, source_expr, excluded_expr = described_class.form_configuration_source_table(type_ids)

    rows(<<~SQL.squish)
      SELECT wp_types.own_id AS own_id,
             #{source_expr} AS source_id,
             array_to_string(#{excluded_expr}, ',') AS excluded
      FROM (SELECT 1) AS driver
      #{join}
    SQL
  end

  def rows(sql)
    ActiveRecord::Base.connection.select_all(sql).to_a.index_by { |row| row["own_id"] }
  end

  describe ".form_configuration_remap", with_flag: { type_variants: true } do
    let!(:owner) { create(:type) }
    let!(:linked) { create(:type) }
    let!(:project) { create(:project, types: [owner, linked]) }

    it "resolves an unlinked type to itself and excludes nothing" do
      row = remap_by_own_id[owner.id]

      expect(row["source_id"]).to eq(owner.id)
      expect(row["excluded"]).to eq("")
    end

    it "resolves a linked type to its source" do
      linked.link!(aspect, source: owner)

      expect(remap_by_own_id[linked.id]["source_id"]).to eq(owner.id)
    end

    it "resolves multi-hop chains to the terminal owner" do
      middle = create(:type)
      project.types << middle
      middle.link!(aspect, source: owner)
      linked.link!(aspect, source: middle)

      resolved = remap_by_own_id

      expect(resolved[linked.id]["source_id"]).to eq(owner.id)
      expect(resolved[middle.id]["source_id"]).to eq(owner.id)
    end

    it "carries the exclusions accumulated along the chain" do
      middle = create(:type)
      project.types << middle
      create(:type_configuration_link, type: middle, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1])
      create(:type_configuration_link, type: linked, source: middle, aspect:,
                                       excluded_elements: %w[custom_field_2])

      resolved = remap_by_own_id

      expect(resolved[linked.id]["excluded"].split(",")).to contain_exactly("custom_field_1", "custom_field_2")
      expect(resolved[middle.id]["excluded"]).to eq("custom_field_1")
      expect(resolved[owner.id]["excluded"]).to eq("")
    end

    it "resolves every type without querying to build the SQL" do
      middle = create(:type)
      middle.link!(aspect, source: owner)
      linked.link!(aspect, source: middle)

      # The chain is resolved inside the caller's query now, so building the fragment
      # issues nothing at all.
      expect { described_class.form_configuration_remap("pt.type_id") }.to have_a_query_limit(0)
    end
  end

  describe ".form_configuration_source_table", with_flag: { type_variants: true } do
    let!(:owner) { create(:type) }
    let!(:linked) { create(:type) }

    it "maps each type id to itself when unlinked" do
      other = create(:type)

      resolved = source_table_by_own_id([owner.id, other.id])

      expect(resolved[owner.id]["source_id"]).to eq(owner.id)
      expect(resolved[other.id]["source_id"]).to eq(other.id)
    end

    it "maps a linked type's own id to its source id" do
      linked.link!(aspect, source: owner)

      resolved = source_table_by_own_id([linked.id])

      expect(resolved[linked.id]["own_id"]).to eq(linked.id)
      expect(resolved[linked.id]["source_id"]).to eq(owner.id)
    end

    it "carries the chain's exclusions" do
      create(:type_configuration_link, type: linked, source: owner, aspect:,
                                       excluded_elements: %w[custom_field_1 assignee])

      expect(source_table_by_own_id([linked.id])[linked.id]["excluded"].split(","))
        .to contain_exactly("custom_field_1", "assignee")
    end

    it "issues no query to build the SQL" do
      linked.link!(aspect, source: owner)

      expect { described_class.form_configuration_source_table([linked.id]) }
        .to have_a_query_limit(0)
    end
  end

  describe ".excluded_element_condition" do
    def excluded?(custom_field_id, elements)
      literal = elements.empty? ? "'{}'::text[]" : "ARRAY[#{elements.map { |e| "'#{e}'" }.join(', ')}]::text[]"
      condition = described_class.excluded_element_condition(custom_field_id.to_s, literal)

      ActiveRecord::Base.connection.select_value("SELECT 1 WHERE #{condition}").nil?
    end

    it "excludes a custom field listed under its attribute name" do
      expect(excluded?(7, %w[custom_field_7])).to be(true)
    end

    it "keeps a custom field that is not listed" do
      expect(excluded?(7, %w[custom_field_8 assignee])).to be(false)
    end

    it "keeps every custom field when nothing is excluded" do
      expect(excluded?(7, [])).to be(false)
    end

    it "does not confuse a prefix of another id" do
      expect(excluded?(7, %w[custom_field_77])).to be(false)
    end
  end

  describe "with the variants flag off", with_flag: { type_variants: false } do
    let!(:owner) { create(:type) }
    let!(:linked) { create(:type) }
    let!(:project) { create(:project, types: [owner, linked]) }

    before { linked.link!(aspect, source: owner) }

    it "keys joins on the own type id without remapping" do
      join, expr, excluded = described_class.form_configuration_remap("pt.type_id")

      expect(join).to eq("")
      expect(expr).to eq("pt.type_id")
      expect(excluded).to eq(described_class::EMPTY_ELEMENTS)

      expect(remap_by_own_id[linked.id]["source_id"]).to eq(linked.id)
    end

    it "keys the driving table on the own type id without remapping" do
      resolved = source_table_by_own_id([linked.id])

      expect(resolved[linked.id]["source_id"]).to eq(linked.id)
      expect(resolved[linked.id]["excluded"]).to eq("")
    end

    it "does not query configuration links" do
      allow(Type::ConfigurationLink).to receive(:where).and_call_original

      described_class.form_configuration_remap("pt.type_id")

      expect(Type::ConfigurationLink).not_to have_received(:where)
    end
  end
end
