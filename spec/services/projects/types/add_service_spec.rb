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

RSpec.describe Projects::Types::AddService do
  subject(:service_call) { described_class.new(user:, model: project).call(variant:) }

  let(:user) { create(:admin) }
  let(:project) { create(:project, no_types: true) }

  context "with a type's base variant" do
    let(:type) { create(:type) }
    let(:variant) { type.default_variant }

    it "enables the type on the project" do
      expect(service_call).to be_success
      expect(project.enabled_types).to contain_exactly(type)
    end

    it "enables the type's work package custom fields on the project" do
      custom_field = create(:text_wp_custom_field, type_variants: [variant])

      expect { service_call }
        .to change { project.reload.work_package_custom_field_ids }
        .from([])
        .to([custom_field.id])
    end

    context "when the type is already enabled" do
      let(:project) { create(:project, types: [type]) }

      it "succeeds without enabling it twice" do
        expect(service_call).to be_success
        expect(project.enabled_types).to contain_exactly(type)
      end
    end
  end

  context "with a named variant" do
    let(:type) { create(:type) }
    let(:variant) { create(:type_variant, type:) }

    context "and the variants feature is not active", with_flag: { type_variants: false } do
      it "fails and does not enable the type" do
        expect(service_call).to be_failure
        expect(service_call.errors.symbols_for(:types)).to contain_exactly(:cannot_assign_variants_yet)
        expect(project.enabled_types).to be_empty
      end
    end

    context "and the variants feature is active", with_flag: { type_variants: true } do
      it "uses the type and applies the variant" do
        expect(service_call).to be_success
        expect(project.enabled_types).to contain_exactly(type)
        expect(project.project_types.sole.variant).to eq(variant)
      end

      context "when the variant is already the one applied" do
        let(:project) { create(:project, types: [variant]) }

        it "succeeds without adding a second row" do
          expect(service_call).to be_success
          expect(project.reload.project_types.sole.variant).to eq(variant)
        end
      end

      # Without this the work package form is empty for the variant: a variant inheriting its
      # form configuration owns no custom_fields_types rows of its own.
      context "when the variant inherits its form configuration" do
        let!(:type_custom_field) { create(:text_wp_custom_field, type_variants: [type.default_variant]) }

        before do
          variant.update!(form_configuration_source: type.default_variant)
        end

        it "enables the fields the variant actually shows, which are the type's" do
          expect { service_call }
            .to change { project.reload.work_package_custom_field_ids }
            .from([])
            .to([type_custom_field.id])
        end
      end

      context "when the variant owns its form configuration" do
        let!(:type_custom_field) { create(:text_wp_custom_field, type_variants: [type.default_variant]) }
        let!(:variant_custom_field) { create(:text_wp_custom_field, type_variants: [variant]) }

        it "enables its own fields rather than the type's" do
          expect { service_call }
            .to change { project.reload.work_package_custom_field_ids }
            .from([])
            .to([variant_custom_field.id])
        end
      end

      context "when a sibling variant is already enabled" do
        let(:sibling) { create(:type_variant, type:) }
        let(:project) { create(:project, types: [sibling]) }

        it "fails and keeps the sibling applied" do
          expect(service_call).to be_failure
          expect(service_call.errors.symbols_for(:types))
            .to contain_exactly(:cannot_assign_multiple_variants_of_parent)
          expect(project.reload.project_types.sole.variant).to eq(sibling)
        end
      end

      context "when the base variant is already enabled" do
        let(:project) { create(:project, types: [type]) }

        it "fails and keeps the base variant applied" do
          expect(service_call).to be_failure
          expect(service_call.errors.symbols_for(:types)).to contain_exactly(:cannot_assign_variant_and_parent)
          expect(project.reload.project_types.sole.variant).to eq(type.default_variant)
        end
      end
    end
  end

  context "with a base variant whose sibling is already enabled", with_flag: { type_variants: true } do
    let(:type) { create(:type) }
    let(:variant) { type.default_variant }
    let(:named_variant) { create(:type_variant, type:) }
    let(:project) { create(:project, types: [named_variant]) }

    it "fails and keeps the named variant applied" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:cannot_assign_variant_and_parent)
      expect(project.reload.project_types.sole.variant).to eq(named_variant)
    end
  end

  context "when the user is not allowed to manage types" do
    let(:variant) { create(:type).default_variant }

    let(:user) { create(:user) }

    it "fails without enabling the type" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
      expect(project.enabled_types).to be_empty
    end
  end
end
