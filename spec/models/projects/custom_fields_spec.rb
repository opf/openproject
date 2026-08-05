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

RSpec.describe Projects::CustomFields do
  describe "#available_custom_fields_for_type" do
    shared_let(:admin) { create(:admin) }

    let(:project) { create(:project) }
    let(:custom_field) { create(:project_custom_field, projects: [project]) }
    let(:parent) { create(:type) }
    let(:variant) { create(:type, parent:) }

    current_user { admin }

    subject(:available) { project.available_custom_fields_for_type(variant.id).to_a }

    before do
      parent.project_custom_fields << custom_field
    end

    context "when the type owns its project attributes (Independent)" do
      let(:variant) { create(:type) }

      it "returns the attributes enabled for that type" do
        variant.project_custom_fields << custom_field

        expect(available).to contain_exactly(custom_field)
      end

      it "returns nothing when the type has none enabled" do
        expect(available).to be_empty
      end
    end

    context "when the type is Linked for project attributes", with_flag: { type_variants: true } do
      it "resolves to the source type's enabled attributes" do
        # A freshly created variant is linked to its parent for PROJECT_ATTRIBUTES.
        expect(variant).to be_linked(Type::ConfigurationLink::PROJECT_ATTRIBUTES)
        expect(available).to contain_exactly(custom_field)
      end
    end

    context "when the link excludes an attribute", with_flag: { type_variants: true } do
      let(:kept_field) { create(:project_custom_field, projects: [project]) }

      before do
        parent.project_custom_fields << kept_field
        variant.configuration_links
               .find_by(aspect: Type::ConfigurationLink::PROJECT_ATTRIBUTES)
               .update!(excluded_elements: [custom_field.attribute_name])
      end

      it "drops it from the inherited attributes" do
        expect(available).to contain_exactly(kept_field)
      end

      it "leaves the owning type's attributes untouched" do
        expect(project.available_custom_fields_for_type(parent.id).to_a)
          .to contain_exactly(custom_field, kept_field)
      end

      # Links are independent of the parent/child hierarchy: any type can link to any other,
      # so a chain can be arbitrarily long regardless of nesting. A plain root type is used
      # here deliberately — no parent involved.
      it "accumulates the exclusions of a longer chain" do
        leaf = create(:type)
        create(:type_configuration_link, type: leaf, source: variant,
                                         aspect: Type::ConfigurationLink::PROJECT_ATTRIBUTES,
                                         excluded_elements: [kept_field.attribute_name])

        expect(project.available_custom_fields_for_type(leaf.id).to_a).to be_empty
      end
    end

    context "when the type is Linked but the feature flag is off", with_flag: { type_variants: false } do
      it "ignores the link and reads the type's own (empty) mappings" do
        variant.link!(Type::ConfigurationLink::PROJECT_ATTRIBUTES, source: parent)

        expect(available).to be_empty
      end
    end
  end
end
