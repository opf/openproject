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

RSpec.describe UserCustomFieldSection do
  subject(:section) { create(:user_custom_field_section) }

  describe "constants" do
    it "defines the built-in attribute keys" do
      expect(described_class::BUILT_IN_ATTRIBUTES).to eq(%w[login firstname lastname mail language department])
    end
  end

  describe "#untitled?" do
    it { expect(described_class.new(name: nil)).to be_untitled }
    it { expect(described_class.new(name: "")).to be_untitled }
    it { expect(described_class.new(name: "My section")).not_to be_untitled }
  end

  describe "#add_to_order" do
    it "appends to the end when no position given" do
      section.add_to_order("cf_1")
      section.add_to_order("cf_2")
      expect(section.reload.attribute_order).to eq(%w[cf_1 cf_2])
    end

    it "inserts at the given 1-indexed position" do
      section.update_column(:attribute_order, %w[cf_1 cf_3])
      section.add_to_order("cf_2", position: 2)
      expect(section.reload.attribute_order).to eq(%w[cf_1 cf_2 cf_3])
    end

    it "is idempotent — removes prior occurrence before inserting" do
      section.update_column(:attribute_order, %w[cf_1 cf_2 cf_3])
      section.add_to_order("cf_2", position: 1)
      expect(section.reload.attribute_order).to eq(%w[cf_2 cf_1 cf_3])
    end
  end

  describe "#remove_from_order" do
    it "removes the key" do
      section.update_column(:attribute_order, %w[cf_1 cf_2 cf_3])
      section.remove_from_order("cf_2")
      expect(section.reload.attribute_order).to eq(%w[cf_1 cf_3])
    end

    it "is a no-op when key is absent" do
      section.update_column(:attribute_order, %w[cf_1])
      expect { section.remove_from_order("cf_99") }.not_to change { section.reload.attribute_order }
    end
  end

  describe "#move_in_order" do
    before { section.update_column(:attribute_order, %w[a b c d]) }

    it "moves to highest (index 0)" do
      section.move_in_order("c", :highest)
      expect(section.reload.attribute_order).to eq(%w[c a b d])
    end

    it "moves to lowest (last index)" do
      section.move_in_order("b", :lowest)
      expect(section.reload.attribute_order).to eq(%w[a c d b])
    end

    it "moves higher (one step earlier)" do
      section.move_in_order("c", :higher)
      expect(section.reload.attribute_order).to eq(%w[a c b d])
    end

    it "moves lower (one step later)" do
      section.move_in_order("b", :lower)
      expect(section.reload.attribute_order).to eq(%w[a c b d])
    end

    it "clamps: moving highest item higher stays at index 0" do
      section.move_in_order("a", :higher)
      expect(section.reload.attribute_order).to eq(%w[a b c d])
    end

    it "clamps: moving lowest item lower stays at the end" do
      section.move_in_order("d", :lower)
      expect(section.reload.attribute_order).to eq(%w[a b c d])
    end

    it "is a no-op when key is absent" do
      expect { section.move_in_order("z", :higher) }.not_to change { section.reload.attribute_order }
    end
  end

  describe "#custom_fields_by_key" do
    let!(:cf1) { create(:user_custom_field, user_custom_field_section: section) }
    let!(:cf2) { create(:user_custom_field, user_custom_field_section: section) }

    it "returns a hash keyed by cf_<id>" do
      result = section.reload.custom_fields_by_key
      expect(result[cf1.column_name]).to eq(cf1)
      expect(result[cf2.column_name]).to eq(cf2)
    end
  end

  describe ".with_custom_fields" do
    let!(:section_a) { create(:user_custom_field_section, name: "Section A", position: 1) }
    let!(:section_b) { create(:user_custom_field_section, name: "Section B", position: 2) }
    let!(:field_a1) { create(:user_custom_field, user_custom_field_section: section_a) }
    let!(:field_a2) { create(:user_custom_field, user_custom_field_section: section_a) }
    let!(:field_b1) { create(:user_custom_field, user_custom_field_section: section_b) }

    it "returns only sections containing at least one matching field" do
      result = described_class.with_custom_fields([field_a1.id])
      expect(result).to contain_exactly(section_a)
    end

    it "excludes sections with no matching fields" do
      result = described_class.with_custom_fields([field_a1.id])
      expect(result).not_to include(section_b)
    end

    it "orders sections by position" do
      result = described_class.with_custom_fields([field_a1.id, field_b1.id])
      expect(result).to eq([section_a, section_b])
    end

    it "preloads the matching custom fields on each section" do
      result = described_class.with_custom_fields([field_a1.id, field_a2.id])
      expect(result.first.custom_fields).to contain_exactly(field_a1, field_a2)
    end
  end

  describe ".with_filled_fields_for" do
    let(:viewer) { create(:user) }
    let!(:section_a) { create(:user_custom_field_section, name: "Section A", position: 1) }
    let!(:section_b) { create(:user_custom_field_section, name: "Section B", position: 2) }
    # Creation order determines initial attribute_order within each section.
    let!(:cf_a1) { create(:user_custom_field, :string, name: "A1", user_custom_field_section: section_a) }
    let!(:cf_a2) { create(:user_custom_field, :string, name: "A2", user_custom_field_section: section_a) }
    let!(:cf_b1) { create(:user_custom_field, :string, name: "B1", user_custom_field_section: section_b) }

    before { allow(User).to receive(:current).and_return(viewer) }

    context "when user has no custom field values" do
      let(:profile) { create(:user) }

      it "returns an empty array" do
        expect(described_class.with_filled_fields_for(profile)).to eq([])
      end
    end

    context "when all values are blank" do
      let(:profile) { create(:user, custom_values: [build(:custom_value, custom_field: cf_a1, value: "")]) }

      it "returns an empty array" do
        expect(described_class.with_filled_fields_for(profile)).to eq([])
      end
    end

    context "when user has filled values in multiple sections" do
      let(:profile) do
        create(:user, custom_values: [
                 build(:custom_value, custom_field: cf_a1, value: "hello"),
                 build(:custom_value, custom_field: cf_b1, value: "world")
               ])
      end

      it "returns one [section, cfs] pair per matching section" do
        result = described_class.with_filled_fields_for(profile)
        expect(result.size).to eq(2)
      end

      it "orders pairs by section position" do
        result = described_class.with_filled_fields_for(profile)
        expect(result.map(&:first)).to eq([section_a, section_b])
      end

      it "includes only the CFs that have a filled value, not all CFs in the section" do
        result = described_class.with_filled_fields_for(profile)
        section_a_cfs = result.find { |s, _| s == section_a }.last
        expect(section_a_cfs).to eq([cf_a1])
        expect(section_a_cfs).not_to include(cf_a2)
      end
    end

    context "when a section has multiple filled CFs" do
      let(:profile) do
        create(:user, custom_values: [
                 build(:custom_value, custom_field: cf_a1, value: "first"),
                 build(:custom_value, custom_field: cf_a2, value: "second")
               ])
      end

      it "orders CFs within a section by attribute_order" do
        result = described_class.with_filled_fields_for(profile)
        expect(result.find { |s, _| s == section_a }.last).to eq([cf_a1, cf_a2])
      end

      it "respects a manually reordered attribute_order" do
        section_a.update_column(:attribute_order, [cf_a2.column_name, cf_a1.column_name])
        result = described_class.with_filled_fields_for(profile)
        expect(result.find { |s, _| s == section_a }.last).to eq([cf_a2, cf_a1])
      end
    end

    context "with admin_only CFs" do
      let!(:admin_cf) do
        create(:user_custom_field, :string, name: "Secret", user_custom_field_section: section_a, admin_only: true)
      end
      let(:profile) { create(:user, custom_values: [build(:custom_value, custom_field: admin_cf, value: "secret")]) }

      context "when viewer is not an admin" do
        it "excludes admin_only CFs from results" do
          result = described_class.with_filled_fields_for(profile)
          expect(result.flat_map(&:last)).not_to include(admin_cf)
        end

        it "excludes the section entirely when all its filled CFs are admin_only" do
          expect(described_class.with_filled_fields_for(profile)).to eq([])
        end
      end

      context "when viewer is an admin" do
        let(:viewer) { create(:admin) }

        it "includes admin_only CFs" do
          result = described_class.with_filled_fields_for(profile)
          expect(result.flat_map(&:last)).to include(admin_cf)
        end
      end
    end

    context "with visible_on_user_card" do
      let!(:card_cf) do
        create(:user_custom_field, :string, name: "On card",
                                            user_custom_field_section: section_a, visible_on_user_card: true)
      end
      let!(:no_card_cf) do
        create(:user_custom_field, :string, name: "Off card",
                                            user_custom_field_section: section_a, visible_on_user_card: false)
      end
      let(:profile) do
        create(:user, custom_values: [
                 build(:custom_value, custom_field: card_cf,    value: "card value"),
                 build(:custom_value, custom_field: no_card_cf, value: "off-card value")
               ])
      end

      it "returns all visible CFs when visible_on_user_card is not specified" do
        result = described_class.with_filled_fields_for(profile)
        all_cfs = result.flat_map(&:last)
        expect(all_cfs).to include(card_cf, no_card_cf)
      end

      it "restricts to card-flagged CFs when visible_on_user_card: true" do
        result = described_class.with_filled_fields_for(profile, visible_on_user_card: true)
        all_cfs = result.flat_map(&:last)
        expect(all_cfs).to include(card_cf)
        expect(all_cfs).not_to include(no_card_cf)
      end

      it "excludes the section when its only filled card-visible CF is filtered out" do
        profile_no_card = create(:user, custom_values: [
                                   build(:custom_value, custom_field: no_card_cf, value: "only off-card")
                                 ])
        expect(described_class.with_filled_fields_for(profile_no_card, visible_on_user_card: true)).to eq([])
      end
    end
  end
end
