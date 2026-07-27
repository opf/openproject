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

RSpec.describe Type::EffectiveSourceSql do
  let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

  describe ".form_configuration_remap", with_flag: { type_variants: true } do
    it "returns the identity expression when there are no links" do
      join, expr = described_class.form_configuration_remap("pt.type_id")

      expect(join).to eq("")
      expect(expr).to eq("pt.type_id")
    end

    it "emits a VALUES join and COALESCE expression when links exist" do
      source = create(:type)
      linked = create(:type)
      linked.link!(aspect, source:)

      join, expr = described_class.form_configuration_remap("pt.type_id")

      expect(join).to include("VALUES (#{linked.id}, #{source.id})")
      expect(join).to include("ON effective.type_id = pt.type_id")
      expect(expr).to eq("COALESCE(effective.source_id, pt.type_id)")
    end

    it "resolves every linked type without a query per type" do
      owner = create(:type)
      chain = create_list(:type, 4)
      chain.each_with_index do |type, index|
        type.link!(aspect, source: index.zero? ? owner : chain[index - 1])
      end

      # One query for the linked type ids, one for the scope resolving all of them. The
      # count must not grow with the length of the chain.
      expect { described_class.form_configuration_remap("pt.type_id") }.to have_a_query_limit(2)
    end

    it "resolves multi-hop chains to the terminal owner" do
      owner = create(:type)
      middle = create(:type)
      linked = create(:type)
      middle.link!(aspect, source: owner)
      linked.link!(aspect, source: middle)

      join, = described_class.form_configuration_remap("pt.type_id")

      expect(join).to include("(#{linked.id}, #{owner.id})")
      expect(join).to include("(#{middle.id}, #{owner.id})")
    end
  end

  describe ".form_configuration_source_table", with_flag: { type_variants: true } do
    it "maps each type id to itself when unlinked" do
      first = create(:type)
      second = create(:type)

      join = described_class.form_configuration_source_table([first.id, second.id])

      expect(join).to include("VALUES (#{first.id}, #{first.id}), (#{second.id}, #{second.id})")
      expect(join).to include("AS wp_types(own_id, source_id) ON TRUE")
    end

    it "maps a linked type's own id to its source id" do
      source = create(:type)
      linked = create(:type)
      linked.link!(aspect, source:)

      join = described_class.form_configuration_source_table([linked.id])

      expect(join).to include("(#{linked.id}, #{source.id})")
    end
  end

  describe "with the variants flag off", with_flag: { type_variants: false } do
    it "keys joins on the own type id without remapping" do
      source = create(:type)
      linked = create(:type)
      linked.link!(aspect, source:)

      join, expr = described_class.form_configuration_remap("pt.type_id")
      expect(join).to eq("")
      expect(expr).to eq("pt.type_id")

      source_join = described_class.form_configuration_source_table([linked.id])
      expect(source_join).to include("(#{linked.id}, #{linked.id})")
    end

    it "does not query configuration links" do
      source = create(:type)
      linked = create(:type)
      linked.link!(aspect, source:)

      allow(Type::ConfigurationLink).to receive(:where).and_call_original

      described_class.form_configuration_remap("pt.type_id")

      expect(Type::ConfigurationLink).not_to have_received(:where)
    end
  end
end
