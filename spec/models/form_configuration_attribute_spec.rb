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

RSpec.describe FormConfigurationAttribute do
  shared_let(:variant) { create(:type).default_variant }
  shared_let(:custom_field) { create(:wp_custom_field) }
  let(:group) { create(:form_configuration_group, type_variant: variant, label: "Details") }

  def check_deferred_constraints!
    ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
  end

  describe ".reference_for" do
    it "maps custom field keys to the foreign key and everything else to the attribute key" do
      expect(described_class.reference_for("custom_field_#{custom_field.id}"))
        .to eq(custom_field_id: custom_field.id, attribute_key: nil)
      expect(described_class.reference_for("date")).to eq(custom_field_id: nil, attribute_key: "date")
    end

    it "treats keys that only contain a custom field key as attribute keys" do
      expect(described_class.reference_for("custom_field_12_old"))
        .to eq(custom_field_id: nil, attribute_key: "custom_field_12_old")
      expect(described_class.reference_for("x_custom_field_3"))
        .to eq(custom_field_id: nil, attribute_key: "x_custom_field_3")
    end
  end

  describe "#key" do
    it "rebuilds the catalog key" do
      expect(build(:form_configuration_attribute, custom_field:, attribute_key: nil).key)
        .to eq "custom_field_#{custom_field.id}"
      expect(build(:form_configuration_attribute, attribute_key: "date").key).to eq "date"
    end
  end

  describe "validations" do
    def insert_in_savepoint(**reference)
      described_class.transaction(requires_new: true) do
        described_class.insert_all!([{ type_variant_id: variant.id, **reference }])
      end
    end

    it "requires exactly one reference" do
      neither = described_class.new(type_variant: variant)
      both = described_class.new(type_variant: variant, custom_field:, attribute_key: "date")

      expect(neither).not_to be_valid
      expect(neither.errors[:attribute_key]).to be_present
      expect(both).not_to be_valid
      expect(both.errors[:attribute_key]).to be_present
    end

    it "requires group and position together" do
      group_only = described_class.new(type_variant: variant, attribute_key: "date", group:)
      position_only = described_class.new(type_variant: variant, attribute_key: "date", position: 1)

      expect(group_only).not_to be_valid
      expect(group_only.errors[:position]).to be_present
      expect(position_only).not_to be_valid
      expect(position_only.errors[:group]).to be_present
    end

    it "rejects a group of another owner and a query group" do
      foreign_group = create(:form_configuration_group, type_variant: create(:type).default_variant)
      query_group = create(:form_configuration_group, :query, type_variant: variant, query: create(:query))
      in_foreign_group = described_class.new(type_variant: variant, attribute_key: "date", group: foreign_group,
                                             position: 1)
      in_query_group = described_class.new(type_variant: variant, attribute_key: "date", group: query_group,
                                           position: 1)

      expect(in_foreign_group).not_to be_valid
      expect(in_foreign_group.errors[:group]).to be_present
      expect(in_query_group).not_to be_valid
      expect(in_query_group.errors[:group]).to be_present
    end

    it "keeps one membership per attribute and owner at the database level" do
      create(:form_configuration_attribute, type_variant: variant, attribute_key: "date")
      create(:form_configuration_attribute, type_variant: variant, custom_field:)

      expect { insert_in_savepoint(attribute_key: "date", custom_field_id: nil) }
        .to raise_error(ActiveRecord::RecordNotUnique)
      expect { insert_in_savepoint(attribute_key: nil, custom_field_id: custom_field.id) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "is removed when its custom field is deleted" do
      membership = create(:form_configuration_attribute, type_variant: variant, custom_field:)

      custom_field.destroy!

      expect(described_class.where(id: membership.id)).not_to exist
    end
  end

  describe "placement" do
    let!(:subject_row) do
      create(:form_configuration_attribute, type_variant: variant, group:, position: 1, attribute_key: "subject")
    end
    let!(:date_row) do
      create(:form_configuration_attribute, type_variant: variant, group:, position: 2, attribute_key: "date")
    end
    let!(:inactive_row) { create(:form_configuration_attribute, type_variant: variant, attribute_key: "priority") }

    it "is created inactive without a position when no group is given" do
      expect(inactive_row).not_to be_active
      expect(inactive_row.position).to be_nil
      expect(described_class.inactive).to contain_exactly(inactive_row)
      check_deferred_constraints!
    end

    it "scopes active memberships to the placed rows" do
      expect(described_class.active).to contain_exactly(subject_row, date_row)
      check_deferred_constraints!
    end

    it "activates into a group at the requested position and shifts the neighbours" do
      id = inactive_row.id
      inactive_row.place!(group:, position: 1)

      expect(group.members.reload.pluck(:attribute_key, :position))
        .to eq [["priority", 1], ["subject", 2], ["date", 3]]
      expect(described_class.find(id)).to have_attributes(form_configuration_group_id: group.id, position: 1)
      check_deferred_constraints!
    end

    it "moves within the group with place! and keeps its id" do
      id = date_row.id
      date_row.place!(group:, position: 1)

      expect(group.members.reload.pluck(:attribute_key, :position)).to eq [["date", 1], ["subject", 2]]
      expect(described_class.find(id)).to have_attributes(form_configuration_group_id: group.id, position: 1)
      check_deferred_constraints!
    end

    it "moves between groups, compacting the source and shifting the target" do
      other_group = create(:form_configuration_group, type_variant: variant, label: "Other")
      create(:form_configuration_attribute, type_variant: variant, group: other_group, position: 1,
                                            attribute_key: "assignee")

      subject_row.place!(group: other_group, position: 1)

      expect(group.members.reload.pluck(:attribute_key, :position)).to eq [["date", 1]]
      expect(other_group.members.reload.pluck(:attribute_key, :position)).to eq [["subject", 1], ["assignee", 2]]
      check_deferred_constraints!
    end

    it "deactivates, compacting the group it left, and leaves an empty group intact" do
      subject_row.deactivate!
      date_row.deactivate!

      expect(subject_row.reload).not_to be_active
      expect(subject_row.position).to be_nil
      expect(group.reload.members).to be_empty
      expect(variant.form_groups).to include(group)
      check_deferred_constraints!
    end

    it "leaves an inactive record untouched when deactivated" do
      expect { inactive_row.deactivate! }.not_to raise_error

      expect(inactive_row.reload).to have_attributes(form_configuration_group_id: nil, position: nil)
      expect(inactive_row.errors).to be_empty
      check_deferred_constraints!
    end

    it "compacts from the database position, not from a stale loaded instance" do
      priority = inactive_row
      priority.place!(group:, position: 3)
      assignee = create(:form_configuration_attribute, type_variant: variant, group:, position: 4,
                                                       attribute_key: "assignee")
      loaded_date = described_class.find(date_row.id)

      subject_row.deactivate!
      loaded_date.deactivate!

      expect(group.members.reload.pluck(:attribute_key, :position)).to eq [["priority", 1], ["assignee", 2]]
      expect(assignee.reload.position).to eq 2
      check_deferred_constraints!
    end

    it "refuses to place a record that carries unsaved changes" do
      inactive_row.attribute_key = "changed"

      expect { inactive_row.place!(group:, position: 1) }.to raise_error(RuntimeError, /unpersisted changes/)
      check_deferred_constraints!
    end

    it "reorders with move_after_anchor within the group" do
      date_row.move_after_anchor(nil, scope: group.members)
      expect(group.members.reload.pluck(:attribute_key)).to eq %w[date subject]

      date_row.move_after_anchor(subject_row.id.to_s, scope: group.members)
      expect(group.members.reload.pluck(:attribute_key)).to eq %w[subject date]
      check_deferred_constraints!
    end
  end
end
