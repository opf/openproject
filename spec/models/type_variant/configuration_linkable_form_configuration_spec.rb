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

# End-to-end resolution of a form configuration down a chain of links: the groups come from
# the type owning the aspect, narrowed by the exclusions accumulated on every link between
# it and the type being read.
RSpec.describe TypeVariant::ConfigurationLinkable, "form configuration exclusions" do
  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  let(:field_a) { create(:integer_wp_custom_field) }
  let(:field_b) { create(:integer_wp_custom_field) }
  let(:field_c) { create(:integer_wp_custom_field) }
  let(:field_d) { create(:integer_wp_custom_field) }

  # owner ← middle ← leaf, each link dropping a little more of the owner's configuration.
  let(:owner) do
    create(:type).default_variant.tap do |variant|
      variant.attribute_groups = [
        ["details", [field_a.attribute_name, field_b.attribute_name]],
        ["people", %W[assignee #{field_c.attribute_name}]],
        ["solo", [field_d.attribute_name]]
      ]
      variant.custom_field_ids = [field_a.id, field_b.id, field_c.id, field_d.id]
      variant.save!
    end
  end

  let(:middle) { create(:type).default_variant }
  let(:leaf) { create(:type).default_variant }

  before do
    middle.update!(form_configuration_source: owner,
                   form_configuration_excluded_elements: [field_a.attribute_name])
    leaf.update!(form_configuration_source: middle,
                 form_configuration_excluded_elements: ["assignee", field_d.attribute_name])
  end

  def groups_of(variant)
    variant.attribute_groups.to_h { |group| [group.key, group.attributes] }
  end

  it "leaves the owning variant's own configuration untouched" do
    expect(groups_of(owner)).to eq(
      "details" => [field_a.attribute_name, field_b.attribute_name],
      "people" => ["assignee", field_c.attribute_name],
      "solo" => [field_d.attribute_name]
    )
    expect(owner.custom_fields).to contain_exactly(field_a, field_b, field_c, field_d)
  end

  it "applies one link's exclusions to the intermediate variant" do
    expect(groups_of(middle)).to eq(
      "details" => [field_b.attribute_name],
      "people" => ["assignee", field_c.attribute_name],
      "solo" => [field_d.attribute_name]
    )
    expect(middle.custom_fields).to contain_exactly(field_b, field_c, field_d)
  end

  it "applies the whole chain's exclusions to the leaf and drops the emptied group" do
    expect(groups_of(leaf)).to eq(
      "details" => [field_b.attribute_name],
      "people" => [field_c.attribute_name]
    )
    expect(groups_of(leaf).keys).not_to include("solo")
    expect(leaf.custom_fields).to contain_exactly(field_b, field_c)
  end

  it "excludes a non-custom-field attribute without touching the custom fields" do
    expect(groups_of(leaf)["people"]).not_to include("assignee")
    expect(leaf.custom_fields).to include(field_c)
  end

  it "keeps a group whose remaining attributes are unchanged identical to the owner's" do
    expect(groups_of(middle)["people"]).to eq(groups_of(owner)["people"])
  end

  it "does not corrupt the owner's memoized groups when narrowing them" do
    groups_of(leaf)

    expect(groups_of(owner)["details"])
      .to eq([field_a.attribute_name, field_b.attribute_name])
    expect(groups_of(owner).keys).to include("solo")
  end

  it "resolves the same configuration when the variant came from the preloading scope" do
    preloaded = TypeVariant.with_effective_source(aspect).find(leaf.id)

    expect(groups_of(preloaded)).to eq(groups_of(leaf))
    expect(preloaded.effective_source_for(aspect)).to eq(owner)
    expect(preloaded.effective_excluded_elements(aspect))
      .to contain_exactly(field_a.attribute_name, field_d.attribute_name, "assignee")
  end

  it "reads its own configuration once switched to Independent" do
    leaf.attribute_groups = [["own", %w[assignee]]]
    leaf.save!
    leaf.update!(form_configuration_source: nil, form_configuration_excluded_elements: [])

    expect(groups_of(leaf.reload)).to eq("own" => ["assignee"])
  end

  context "with a query group in the owner's configuration" do
    let(:query) { create(:query) }

    def query_group_of(variant)
      variant.attribute_groups.detect { |group| group.group_type == :query }
    end

    before do
      owner.attribute_groups = [
        ["details", [field_a.attribute_name, field_b.attribute_name]],
        ["Related work packages", [query]]
      ]
      owner.save!
    end

    it "passes the query group through when it is not excluded" do
      expect(query_group_of(leaf)).to be_present
      expect(query_group_of(leaf).query).to eq(query)
      expect(groups_of(leaf)["details"]).to eq([field_b.attribute_name])
    end

    it "drops the whole section when the query is excluded on the variant's own link" do
      leaf.update!(form_configuration_excluded_elements: ["query_#{query.id}"])

      expect(query_group_of(leaf)).to be_nil
      expect(leaf.attribute_groups.map(&:key)).not_to include("Related work packages")
    end

    it "drops it for the leaf when an ancestor's link excludes the query" do
      middle.update!(form_configuration_excluded_elements: [field_a.attribute_name, "query_#{query.id}"])

      expect(query_group_of(middle)).to be_nil
      expect(query_group_of(leaf)).to be_nil
    end

    it "leaves the owning variant's query group in place" do
      leaf.update!(form_configuration_excluded_elements: ["query_#{query.id}"])

      expect(query_group_of(owner)).to be_present
      expect(query_group_of(owner).query).to eq(query)
    end
  end

  context "with the flag off", with_flag: { type_variants: false } do
    it "resolves links and exclusions the same" do
      expect(groups_of(leaf)).to eq(
        "details" => [field_b.attribute_name],
        "people" => [field_c.attribute_name]
      )
    end
  end
end
