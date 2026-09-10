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

RSpec.describe TypeVariant, "required attributes" do
  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  let(:field_a) { create(:integer_wp_custom_field) }
  let(:field_b) { create(:integer_wp_custom_field) }

  let(:owner) do
    create(:type).default_variant.tap do |variant|
      variant.attribute_groups = [["details", [field_a.attribute_name, field_b.attribute_name]]]
      variant.custom_field_ids = [field_a.id, field_b.id]
      variant.required_attributes = [field_a.attribute_name, field_b.attribute_name]
      variant.save!
    end
  end

  describe "a variant owning its form configuration" do
    it "reads back what it stores" do
      expect(owner.required_attributes).to contain_exactly(field_a.attribute_name, field_b.attribute_name)
    end

    it "maps the entries to custom field ids" do
      expect(owner.required_custom_field_ids).to contain_exactly(field_a.id, field_b.id)
    end

    it "ignores entries that name no custom field" do
      owner.update!(required_attributes: ["assignee", field_a.attribute_name])

      expect(owner.required_custom_field_ids).to contain_exactly(field_a.id)
    end

    it "starts out demanding nothing" do
      expect(create(:type).default_variant.required_attributes).to eq([])
    end
  end

  describe "a variant linking its form configuration" do
    let(:leaf) { create(:type).default_variant }

    before { link_configuration(leaf, source: owner, aspect:) }

    it "inherits the source's required attributes" do
      expect(leaf.required_attributes).to contain_exactly(field_a.attribute_name, field_b.attribute_name)
    end

    it "drops what the chain excludes, because an absent field cannot be demanded" do
      leaf.update!(form_configuration_excluded_elements: [field_a.attribute_name])

      expect(leaf.required_attributes).to contain_exactly(field_b.attribute_name)
      expect(leaf.required_custom_field_ids).to contain_exactly(field_b.id)
    end

    it "leaves the source untouched" do
      leaf.update!(form_configuration_excluded_elements: [field_a.attribute_name])

      expect(owner.reload.required_attributes)
        .to contain_exactly(field_a.attribute_name, field_b.attribute_name)
    end
  end

  describe "pruning when the form configuration changes" do
    it "drops an attribute removed from the groups" do
      owner.attribute_groups = [["details", [field_b.attribute_name]]]
      owner.save!

      expect(owner.reload.required_attributes).to contain_exactly(field_b.attribute_name)
    end

    it "drops everything when the groups are reset to the defaults" do
      owner.reset_attribute_groups
      owner.save!

      expect(owner.reload.required_attributes).to eq([])
    end

    it "keeps the set when only an unrelated attribute moves in" do
      owner.attribute_groups = [
        ["details", [field_a.attribute_name, field_b.attribute_name]],
        ["people", %w[assignee]]
      ]
      owner.save!

      expect(owner.reload.required_attributes)
        .to contain_exactly(field_a.attribute_name, field_b.attribute_name)
    end
  end
end
