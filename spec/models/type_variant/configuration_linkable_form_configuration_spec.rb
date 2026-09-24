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

# End-to-end resolution of a form configuration: A named variant inherits its base's groups,
# narrowed by the variant's own excluded elements.
RSpec.describe TypeVariant::ConfigurationLinkable, "form configuration exclusions" do
  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  let(:field_a) { create(:integer_wp_custom_field) }
  let(:field_b) { create(:integer_wp_custom_field) }
  let(:field_c) { create(:integer_wp_custom_field) }
  let(:field_d) { create(:integer_wp_custom_field) }

  let(:type_record) { create(:type) }
  # The base owns the form, the named variant inherits it and drops fields via its own exclusions.
  let(:base) do
    type_record.default_variant.tap do |variant|
      variant.attribute_groups = [
        ["details", [field_a.attribute_name, field_b.attribute_name]],
        ["people", %W[assignee #{field_c.attribute_name}]],
        ["solo", [field_d.attribute_name]]
      ]
      variant.custom_field_ids = [field_a.id, field_b.id, field_c.id, field_d.id]
      variant.save!
    end
  end
  let(:variant) { create(:type_variant, type: type_record) }

  before do
    base
    variant.link!(aspect)
  end

  def groups_of(record)
    record.attribute_groups.to_h { |group| [group.key, group.attributes] }
  end

  it "leaves the base's own configuration untouched" do
    variant.update!(form_configuration_excluded_elements: [field_a.attribute_name])

    expect(groups_of(base)).to eq(
      "details" => [field_a.attribute_name, field_b.attribute_name],
      "people" => ["assignee", field_c.attribute_name],
      "solo" => [field_d.attribute_name]
    )
    expect(base.custom_fields).to contain_exactly(field_a, field_b, field_c, field_d)
  end

  it "applies the variant's exclusions to what it inherits and drops an emptied group" do
    variant.update!(form_configuration_excluded_elements:
      [field_a.attribute_name, "assignee", field_d.attribute_name])

    expect(groups_of(variant)).to eq(
      "details" => [field_b.attribute_name],
      "people" => [field_c.attribute_name]
    )
    expect(groups_of(variant).keys).not_to include("solo")
    expect(variant.custom_fields).to contain_exactly(field_b, field_c)
  end

  it "excludes a non-custom-field attribute without touching the custom fields" do
    variant.update!(form_configuration_excluded_elements: ["assignee"])

    expect(groups_of(variant)["people"]).not_to include("assignee")
    expect(variant.custom_fields).to include(field_c)
  end

  it "keeps a group it does not touch identical to the base's" do
    variant.update!(form_configuration_excluded_elements: [field_a.attribute_name])

    expect(groups_of(variant)["people"]).to eq(groups_of(base)["people"])
    expect(groups_of(variant)["solo"]).to eq(groups_of(base)["solo"])
  end

  it "does not corrupt the base's memoized groups when narrowing them" do
    variant.update!(form_configuration_excluded_elements: [field_a.attribute_name])
    groups_of(variant)

    expect(groups_of(base)["details"]).to eq([field_a.attribute_name, field_b.attribute_name])
    expect(groups_of(base).keys).to include("solo")
  end

  it "reads its own configuration once switched to independent" do
    variant.attribute_groups = [["own", %w[assignee]]]
    variant.save!
    variant.unlink!(aspect)

    expect(groups_of(variant.reload)).to eq("own" => ["assignee"])
  end

  context "with a query group in the base's configuration" do
    let(:query) { create(:query) }

    def query_group_of(record)
      record.attribute_groups.detect { |group| group.group_type == :query }
    end

    before do
      base.attribute_groups = [
        ["details", [field_a.attribute_name, field_b.attribute_name]],
        ["Related work packages", [query]]
      ]
      base.save!
    end

    it "passes the query group through when it is not excluded" do
      variant.update!(form_configuration_excluded_elements: [field_a.attribute_name])

      expect(query_group_of(variant)).to be_present
      expect(query_group_of(variant).query).to eq(query)
      expect(groups_of(variant)["details"]).to eq([field_b.attribute_name])
    end

    it "drops the whole section when the query is excluded" do
      variant.update!(form_configuration_excluded_elements: ["query_#{query.id}"])

      expect(query_group_of(variant)).to be_nil
      expect(variant.attribute_groups.map(&:key)).not_to include("Related work packages")
    end

    it "leaves the base's query group in place" do
      variant.update!(form_configuration_excluded_elements: ["query_#{query.id}"])

      expect(query_group_of(base)).to be_present
      expect(query_group_of(base).query).to eq(query)
    end
  end
end
