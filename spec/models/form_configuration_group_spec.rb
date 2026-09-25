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

RSpec.describe FormConfigurationGroup do
  shared_let(:variant) { create(:type).default_variant }

  def check_deferred_constraints!
    ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
  end

  describe "validations" do
    it "requires a label unless it is a default group" do
      group = described_class.new(type_variant: variant, kind: described_class::ATTRIBUTE)

      expect(group).not_to be_valid
      expect(group.errors[:label]).to be_present

      group.default_key = "people"
      expect(group).to be_valid
    end

    it "requires a query for a query group and forbids one for an attribute group" do
      query_group = described_class.new(type_variant: variant, kind: described_class::QUERY, label: "Related")
      expect(query_group).not_to be_valid
      expect(query_group.errors[:query]).to be_present

      attribute_group = described_class.new(type_variant: variant, kind: described_class::ATTRIBUTE,
                                            label: "Details", query: create(:query))
      expect(attribute_group).not_to be_valid
      expect(attribute_group.errors[:query]).to be_present
    end

    it "allows one group per default key and owner" do
      create(:form_configuration_group, type_variant: variant, default_key: "people")
      duplicate = build(:form_configuration_group, type_variant: variant, default_key: "people")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:default_key]).to be_present
    end

    it "allows one group per query" do
      query = create(:query)
      create(:form_configuration_group, :query, type_variant: variant, query:)
      sharing = build(:form_configuration_group, :query, type_variant: create(:type).default_variant, query:)

      expect(sharing).not_to be_valid
      expect(sharing.errors[:query_id]).to be_present
    end
  end

  describe "#translated_label" do
    it "prefers the label, then the default key translation, then the default key itself" do
      expect(build(:form_configuration_group, label: "Sprint", default_key: "people").translated_label).to eq "Sprint"
      expect(build(:form_configuration_group, label: nil, default_key: "people").translated_label)
        .to eq I18n.t(:label_people)
      expect(build(:form_configuration_group, label: nil, default_key: "unknown_plugin_group").translated_label)
        .to eq "unknown_plugin_group"
    end
  end

  describe "ordering" do
    it "appends new groups at the bottom of the owner's list and moves with insert_at inside a transaction" do
      first = create(:form_configuration_group, type_variant: variant, label: "A")
      second = create(:form_configuration_group, type_variant: variant, label: "B")
      third = create(:form_configuration_group, type_variant: variant, label: "C")

      expect(variant.form_groups.pluck(:label)).to eq %w[A B C]

      described_class.transaction do
        third.insert_at(1)
        second.insert_at(3)
      end

      expect(variant.form_groups.reload.pluck(:label, :position)).to eq [["C", 1], ["A", 2], ["B", 3]]

      first.move_to_top
      expect(variant.form_groups.reload.pluck(:label)).to eq %w[A C B]
      check_deferred_constraints!
    end

    it "scopes positions to the owner" do
      other_variant = create(:type).default_variant
      create(:form_configuration_group, type_variant: variant, label: "A")
      other = create(:form_configuration_group, type_variant: other_variant, label: "B")

      expect(other.position).to eq 1
      check_deferred_constraints!
    end
  end

  describe "destruction" do
    it "destroys the owned query of a query group" do
      query = create(:query)
      group = create(:form_configuration_group, :query, type_variant: variant, query:)

      expect { group.destroy! }.to change(Query, :count).by(-1)
    end

    it "refuses to destroy a group that still holds active members" do
      group = create(:form_configuration_group, type_variant: variant)
      create(:form_configuration_attribute, type_variant: variant, group:, position: 1, attribute_key: "subject")

      expect { group.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "is removed together with its owner" do
      group = create(:form_configuration_group, type_variant: variant)
      create(:form_configuration_attribute, type_variant: variant, group:, position: 1, attribute_key: "subject")

      variant.type.destroy!

      expect(described_class.where(id: group.id)).not_to exist
      expect(FormConfigurationAttribute.where(type_variant_id: variant.id)).not_to exist
    end
  end
end
