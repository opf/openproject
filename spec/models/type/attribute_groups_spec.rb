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

RSpec.describe Type do
  let(:type) { build(:type) }

  shared_let(:admin) { create(:admin) }

  before do
    # Clear up the request store cache for all_work_package_attributes
    RequestStore.clear!
  end

  describe "#attribute_groups" do
    shared_examples_for "returns default attributes" do
      it do
        expect(type.read_attribute(:attribute_groups)).to be_empty

        attribute_groups = type.attribute_groups.select { |g| g.is_a?(Type::AttributeGroup) }.map do |group|
          [group.key, group.attributes]
        end

        expect(attribute_groups).to eql type.default_attribute_groups
      end
    end

    context "with attributes provided" do
      before do
        type.attribute_groups = [["foo", []], ["bar", %w(blubs date)]]
      end

      it "removes unknown attributes from a group" do
        group = type.attribute_groups[1]

        expect(group.key).to eql "bar"
        expect(group.members).to eql ["date"]
      end

      it "keeps groups without attributes" do
        group = type.attribute_groups[0]

        expect(group.key).to eql "foo"
        expect(group.members).to eql []
      end

      it "does not have a children query" do
        expect(type.attribute_groups.detect { |group| group.key == :children }).to be_nil
      end
    end

    context "with empty attributes provided" do
      before do
        type.attribute_groups = []
      end

      it "returns an empty attribute_groups" do
        expect(type.attribute_groups).to be_empty
      end
    end

    context "with no attributes provided" do
      it_behaves_like "returns default attributes"
    end

    context "with a query group" do
      let(:type) { create(:type) }
      let(:query) { build(:global_query, user_id: 0) }

      before do
        login_as(admin)

        type.attribute_groups = [["some group", [query]]]
        type.save!
        type.reload
      end

      it "retrieves the query" do
        expect(type.attribute_groups.length).to be 1

        expect(type.attribute_groups[0].class).to eql Type::QueryGroup
        expect(type.attribute_groups[0].key).to eql "some group"
        expect(type.attribute_groups[0].query).to eql query
      end

      it "removes the former query if a new one is assigned" do
        new_query = build(:global_query, user_id: 0)
        type.attribute_groups[0].attributes = new_query
        type.save!
        type.reload

        expect(type.attribute_groups.length).to be 1

        expect(type.attribute_groups[0].class).to eql Type::QueryGroup
        expect(type.attribute_groups[0].key).to eql "some group"
        expect(type.attribute_groups[0].query).to eql new_query

        expect(Query.count).to be 1
      end
    end
  end

  describe "#default_attribute_groups" do
    subject { type.default_attribute_groups }

    it "returns an array" do
      expect(subject.any?).to be_truthy
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
        group_members.nil? || group_members.size.zero?
      end).to be_falsey
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
      type.attribute_groups = [["foo", [cf_identifier]]]
      expect(type.save).to be_truthy
      expect(type.read_attribute(:attribute_groups)).not_to be_empty
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
        type.attribute_groups = [["foo", [cf_identifier2, cf_identifier]]]
        expect(type.save).to be_truthy
        expect(type.read_attribute(:attribute_groups)).not_to be_empty

        cf_group = type.attribute_groups[0]
        expect(cf_group.members).to eq([cf_identifier2, cf_identifier])
      end
    end
  end

  describe "custom field added implicitly to type" do
    let(:custom_field) do
      create(
        :work_package_custom_field,
        field_format: "string",
        is_for_all: true
      )
    end
    let!(:type) { create(:type, custom_fields: [custom_field]) }

    it "has the custom field in the default group" do
      OpenProject::Cache.clear
      type.reload

      expect(type.custom_field_ids).to eq([custom_field.id])

      other_group = type.attribute_groups.detect { |g| g.key == :other }
      expect(other_group).to be_present
      expect(other_group.attributes).to eq([custom_field.attribute_name])

      # It is removed again when resetting it
      type.reset_attribute_groups
      expect(type.custom_field_ids).to be_empty

      other_group = type.attribute_groups.detect { |g| g.key == :other }
      expect(other_group).not_to be_present
    end
  end

  describe "#destroy" do
    let(:query) { build(:global_query, user_id: 0) }

    before do
      login_as(admin)
      type.attribute_groups = [["some name", [query]]]
      type.save!
      type.reload
      type.destroy
    end

    it "destroys all queries references by query groups" do
      expect(Query.find_by(id: query.id)).to be_nil
    end
  end
end
