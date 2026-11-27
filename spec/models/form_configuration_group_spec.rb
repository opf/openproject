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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe FormConfigurationGroup do
  shared_let(:form) { create(:form_configuration) }

  def check_deferred_constraints!
    ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
  end

  describe "validations" do
    it "requires a label unless it is a default group" do
      group = described_class.new(form_configuration: form, kind: :attribute)

      expect(group).not_to be_valid
      expect(group.errors[:label]).to be_present

      group.default_key = "people"
      expect(group).to be_valid
    end

    it "requires a query for a query group and forbids one for an attribute group" do
      query_group = described_class.new(form_configuration: form, kind: :query, label: "Related")
      expect(query_group).not_to be_valid
      expect(query_group.errors[:query]).to be_present

      attribute_group = described_class.new(form_configuration: form, kind: :attribute,
                                            label: "Details", query: create(:query))
      expect(attribute_group).not_to be_valid
      expect(attribute_group.errors[:query]).to be_present
    end

    it "refuses a kind that is neither attribute nor query" do
      group = described_class.new(form_configuration: form, kind: "section", label: "Details")

      expect(group).not_to be_valid
      expect(group.errors).to be_of_kind(:kind, :inclusion)
    end

    it "keeps the query methods of its columns" do
      group = build(:form_configuration_group, form_configuration: form, label: "Details")

      expect(group.label?).to be(true)
      expect(group.default_key?).to be(false)
    end

    it "allows one group per default key and owner" do
      create(:form_configuration_group, form_configuration: form, default_key: "people")
      duplicate = build(:form_configuration_group, form_configuration: form, default_key: "people")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:default_key]).to be_present
    end

    it "allows one group per query" do
      query = create(:query)
      create(:form_configuration_group, :query, form_configuration: form, query:)
      sharing = build(:form_configuration_group, :query, form_configuration: create(:form_configuration), query:)

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
      first = create(:form_configuration_group, form_configuration: form, label: "A")
      second = create(:form_configuration_group, form_configuration: form, label: "B")
      third = create(:form_configuration_group, form_configuration: form, label: "C")

      expect(form.form_groups.pluck(:label)).to eq %w[A B C]

      described_class.transaction do
        third.insert_at(1)
        second.insert_at(3)
      end

      expect(form.form_groups.reload.pluck(:label, :position)).to eq [["C", 1], ["A", 2], ["B", 3]]

      first.move_to_top
      expect(form.form_groups.reload.pluck(:label)).to eq %w[A C B]
      check_deferred_constraints!
    end

    it "scopes positions to the owner" do
      other_form = create(:form_configuration)
      create(:form_configuration_group, form_configuration: form, label: "A")
      other = create(:form_configuration_group, form_configuration: other_form, label: "B")

      expect(other.position).to eq 1
      check_deferred_constraints!
    end
  end

  describe "destruction" do
    it "destroys the owned query of a query group" do
      query = create(:query)
      group = create(:form_configuration_group, :query, form_configuration: form, query:)

      expect { group.destroy! }.to change(Query, :count).by(-1)
    end

    it "refuses to destroy a group that still holds active members" do
      group = create(:form_configuration_group, form_configuration: form)
      create(:form_configuration_attribute, form_configuration: form, group:, position: 1, attribute_key: "subject")

      expect { group.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "is removed together with its owner" do
      group = create(:form_configuration_group, form_configuration: form)
      create(:form_configuration_attribute, form_configuration: form, group:, position: 1, attribute_key: "subject")

      form.form_groups.reset
      form.destroy!

      expect(described_class.where(id: group.id)).not_to exist
      expect(FormConfigurationAttribute.where(form_configuration_id: form.id)).not_to exist
    end
  end
end
