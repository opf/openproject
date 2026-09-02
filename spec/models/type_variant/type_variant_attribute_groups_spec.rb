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

RSpec.describe TypeVariant do
  let(:variant) { create(:type).default_variant }

  shared_let(:admin) { create(:admin) }

  before do
    # Clear up the request store cache for all_work_package_attributes
    RequestStore.clear!
  end

  describe "#attribute_groups" do
    shared_examples_for "returns default attributes" do
      it do
        expect(variant.read_attribute(:attribute_groups)).to be_empty

        attribute_groups = variant.attribute_groups.grep(Type::AttributeGroup).map do |group|
          [group.key, group.attributes]
        end

        expect(attribute_groups).to eql variant.default_attribute_groups
      end
    end

    context "with attributes provided" do
      before do
        variant.attribute_groups = [["foo", []], ["bar", %w(blubs date)]]
      end

      it "removes unknown attributes from a group" do
        group = variant.attribute_groups[1]

        expect(group.key).to eql "bar"
        expect(group.members).to eql ["date"]
      end

      it "keeps groups without attributes" do
        group = variant.attribute_groups[0]

        expect(group.key).to eql "foo"
        expect(group.members).to eql []
      end

      it "does not have a children query" do
        expect(variant.attribute_groups.detect { |group| group.key == :children }).to be_nil
      end
    end

    context "with empty attributes provided" do
      before do
        variant.attribute_groups = []
      end

      it "returns an empty attribute_groups" do
        expect(variant.attribute_groups).to be_empty
      end
    end

    context "with no attributes provided" do
      it_behaves_like "returns default attributes"
    end

    context "with a query group" do
      let(:variant) { create(:type).default_variant }
      let(:query) { build(:global_query, user_id: 0) }

      before do
        login_as(admin)

        variant.attribute_groups = [["some group", [query]]]
        variant.save!
        variant.reload
      end

      it "retrieves the query" do
        expect(variant.attribute_groups.length).to be 1

        expect(variant.attribute_groups[0].class).to eql Type::QueryGroup
        expect(variant.attribute_groups[0].key).to eql "some group"
        expect(variant.attribute_groups[0].query).to eql query
      end

      it "removes the former query if a new one is assigned" do
        new_query = build(:global_query, user_id: 0)
        variant.attribute_groups[0].attributes = new_query
        variant.save!
        variant.reload

        expect(variant.attribute_groups.length).to be 1

        expect(variant.attribute_groups[0].class).to eql Type::QueryGroup
        expect(variant.attribute_groups[0].key).to eql "some group"
        expect(variant.attribute_groups[0].query).to eql new_query

        expect(Query.count).to be 1
      end
    end
  end

  describe "#default_attribute_groups" do
    subject { variant.default_attribute_groups }

    it "returns an array" do
      expect(subject).to be_any
    end

    it "each attribute group is an array" do
      expect(subject.detect { |g| g.class != Array }).to be_falsey
    end

    it "each attribute group's 1st element is a String (the group name) or symbol (for i18n)" do
      expect(subject.detect { |g| g.first.class != String && g.first.class != Symbol }).to be_falsey
    end

    it "each attribute group's 2nd element is an Array (the group members)" do
      expect(subject.detect { |g| g.second.class != Array }).to be_falsey
    end

    it "does not return empty groups" do
      # For instance, the `type` factory instance does not have custom fields.
      # Thus the `other` group shall not be returned.
      expect(subject.detect do |attribute_group|
        group_members = attribute_group[1]
        group_members.blank?
      end).to be_falsey
    end
  end

  describe "target versions in the form configuration" do
    context "when the multiple versions feature is inactive",
            with_settings: { work_package_multiple_versions: false } do
      it "offers the deprecated version in the default configuration" do
        members = variant.default_attribute_groups.to_h

        expect(members[:details]).to include("version")
        expect(members[:details]).not_to include("target_versions")
      end

      it "renders a persisted target_versions key as the deprecated version" do
        variant[:attribute_groups] = [["details", %w[category target_versions]]]
        variant.unset_attribute_groups_objects

        details = variant.attribute_groups.detect { |group| group.key == "details" }

        expect(details.attributes).to include("version")
        expect(details.attributes).not_to include("target_versions")
      end
    end

    context "when the multiple versions feature is active",
            with_settings: { work_package_multiple_versions: true } do
      it "offers target_versions in the default configuration" do
        members = variant.default_attribute_groups.to_h

        expect(members[:details]).to include("target_versions")
        expect(members[:details]).not_to include("version")
      end

      it "renders a persisted legacy version key as target_versions" do
        variant[:attribute_groups] = [["details", %w[category version]]]
        variant.unset_attribute_groups_objects

        details = variant.attribute_groups.detect { |group| group.key == "details" }

        expect(details.attributes).to include("target_versions")
        expect(details.attributes).not_to include("version")
      end

      it "keeps the display name of a renamed group while normalizing it" do
        variant[:attribute_groups] = [["details", %w[category version], "Custom Details"]]
        variant.unset_attribute_groups_objects

        details = variant.attribute_groups.detect { |group| group.key == "details" }

        expect(details.attributes).to include("target_versions")
        expect(details.display_name).to eq("Custom Details")
      end
    end

    it "leaves query group members untouched" do
      query_member = :"#{Type::QueryGroup::MEMBER_PREFIX}1"
      variant[:attribute_groups] = [["Related", [query_member]]]

      expect(variant.send(:custom_attribute_groups)).to eq([["Related", [query_member]]])
    end
  end

  describe "observed_in_versions in the form configuration" do
    it "is schema-addable but kept out of the default configuration" do
      expect(variant.work_package_attributes.keys).to include("observed_in_versions")

      members = variant.default_attribute_groups.to_h.values.flatten
      expect(members).not_to include("observed_in_versions")
    end

    it "can still be added to a group manually" do
      variant[:attribute_groups] = [["details", %w[category observed_in_versions]]]
      variant.unset_attribute_groups_objects

      details = variant.attribute_groups.detect { |group| group.key == "details" }

      expect(details.attributes).to include("observed_in_versions")
    end
  end

  describe "custom fields" do
    let!(:custom_field) do
      create(
        :work_package_custom_field,
        field_format: "string"
      )
    end
    let(:cf_identifier) do
      custom_field.attribute_name
    end

    it "can be put into attribute groups" do
      # Enforce fresh lookup of groups
      OpenProject::Cache.clear

      # Can be enabled
      variant.attribute_groups = [["foo", [cf_identifier]]]
      expect(variant.save).to be_truthy
      expect(variant.read_attribute(:attribute_groups)).not_to be_empty
    end

    context "with multiple CFs" do
      let!(:custom_field2) do
        create(
          :work_package_custom_field,
          field_format: "string"
        )
      end
      let(:cf_identifier2) do
        custom_field2.attribute_name
      end

      it "they are kept in their respective positions in the group (Regression test #27940)" do
        # Enforce fresh lookup of groups
        OpenProject::Cache.clear

        # Can be enabled
        variant.attribute_groups = [["foo", [cf_identifier2, cf_identifier]]]
        expect(variant.save).to be_truthy
        expect(variant.read_attribute(:attribute_groups)).not_to be_empty

        cf_group = variant.attribute_groups[0]
        expect(cf_group.members).to eq([cf_identifier2, cf_identifier])
      end
    end
  end

  describe "custom field added implicitly to variant" do
    let(:custom_field) do
      create(
        :work_package_custom_field,
        field_format: "string",
        is_for_all: true
      )
    end
    let!(:variant) { create(:type).default_variant.tap { it.update!(custom_fields: [custom_field]) } }

    it "has the custom field in the default group" do
      OpenProject::Cache.clear
      variant.reload

      expect(variant.custom_field_ids).to eq([custom_field.id])

      other_group = variant.attribute_groups.detect { |g| g.key == :other }
      expect(other_group).to be_present
      expect(other_group.attributes).to eq(%w[position] + [custom_field.attribute_name])

      # It is removed again when resetting it
      variant.reset_attribute_groups
      expect(variant.custom_field_ids).to be_empty

      other_group = variant.attribute_groups.detect { |g| g.key == :other }
      expect(other_group).to be_present
      expect(other_group.attributes).to eq(%w[position])
    end
  end

  describe "#destroy" do
    let(:query) { build(:global_query, user_id: 0) }

    before do
      login_as(admin)
      variant.attribute_groups = [["some name", [query]]]
      variant.save!
      variant.reload
      variant.destroy
    end

    it "destroys all queries references by query groups" do
      expect(Query.find_by(id: query.id)).to be_nil
    end
  end
end
