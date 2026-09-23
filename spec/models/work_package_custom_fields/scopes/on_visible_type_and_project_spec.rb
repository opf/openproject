# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative "visible_setup"

RSpec.describe WorkPackageCustomFields::Scopes::OnVisibleTypeAndProject do
  include_context "given a visible setup"

  describe ".on_visible_type_and_project" do
    subject { WorkPackageCustomField.on_visible_type_and_project(user) }

    it "returns custom fields for types that are enabled in projects the user can see" do
      expect(subject).to contain_exactly(type_enabled_and_member_cf, type_enabled_for_all_cf)
    end

    context "with project: provided" do
      subject { WorkPackageCustomField.on_visible_type_and_project(user, project: project_with_user_and_feature) }

      it "returns only fields enabled in the given project" do
        expect(subject).to contain_exactly(type_enabled_and_member_cf, type_enabled_for_all_cf)
      end

      context "when the project has a different type than where the CF is active" do
        subject { WorkPackageCustomField.on_visible_type_and_project(user, project: project_with_user_and_bug) }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe ".on_visible_type_and_project when the project applies a named variant" do
    shared_let(:root_type) { create(:type) }
    shared_let(:variant) { create(:type_variant, type: root_type) }
    shared_let(:variant_project) { create(:project, types: [variant]) }
    shared_let(:variant_user) do
      create(:user, member_with_permissions: { variant_project => [] })
    end

    shared_let(:root_cf) do
      create(:integer_wp_custom_field, projects: [variant_project], type_variants: [root_type.default_variant])
    end
    shared_let(:variant_cf) do
      create(:integer_wp_custom_field, projects: [variant_project], type_variants: [variant])
    end

    subject { WorkPackageCustomField.on_visible_type_and_project(variant_user) }

    it "uses the type while applying the variant" do
      expect(variant_project.enabled_types).to contain_exactly(root_type)
      expect(variant_project.project_types.sole.variant).to eq(variant)
    end

    context "when the variant inherits its form configuration" do
      before { variant.link!(TypeVariant::FORM_CONFIGURATION) }

      it "surfaces the type's fields" do
        expect(subject).to include(root_cf)
      end

      it "does not surface the variant's own fields" do
        expect(subject).not_to include(variant_cf)
      end

      it "hides a field the variant excludes from what it inherits" do
        variant.update!(form_configuration_excluded_elements: [root_cf.attribute_name])

        expect(subject).not_to include(root_cf)
      end
    end

    context "when the variant owns its form configuration" do
      it "surfaces the variant's own fields" do
        expect(subject).to include(variant_cf)
      end

      it "does not surface the type's fields" do
        expect(subject).not_to include(root_cf)
      end
    end
  end
end
