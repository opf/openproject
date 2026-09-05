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

RSpec.describe WorkPackageTypes::BuildVariantFromProjectService, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }

  let(:kept_field) { create(:work_package_custom_field, is_for_all: false) }
  let(:dropped_field) { create(:work_package_custom_field, is_for_all: false) }

  let!(:type) do
    create(:type,
           name: "Bug",
           custom_fields: [kept_field, dropped_field],
           attribute_groups: [["custom group", %w[assignee] + [kept_field, dropped_field].map(&:attribute_name)]])
  end

  let(:source) { type.default_variant }

  let!(:project) do
    create(:project, name: "Website Relaunch", work_package_custom_fields: [kept_field])
  end

  let(:form_configuration) { TypeVariant::FORM_CONFIGURATION }

  subject(:service_call) { described_class.new(user: admin, variant: source).call(project:) }

  before do
    login_as(admin)
    RequestStore.clear!
  end

  context "when the project disables a custom field the type configures" do
    it "is successful and creates a variant" do
      expect { service_call }.to change(TypeVariant, :count).by(1)
      expect(service_call).to be_success
    end

    it "names the variant after the type and the project" do
      expect(service_call.result.variant_name).to eq("Bug - Website Relaunch")
    end

    it "creates the variant on the type it was built from" do
      variant = service_call.result

      expect(variant).not_to be_is_default_variant
      expect(variant.type_id).to eq(type.id)
    end

    # It describes one project's narrowing and nothing else, so it is that project's to own and to
    # go on configuring, and no other project sees it.
    it "makes the variant the project's own" do
      expect(service_call.result.project).to eq(project)
    end

    # The narrowing predates the setting, so it is carried over rather than dropped on the floor.
    it "creates it even when the type disallows project-specific variants" do
      type.update!(allow_project_variants: false)

      expect { service_call }.to change(TypeVariant, :count).by(1)
      expect(service_call).to be_success
    end

    it "links every aspect to the type's base variant" do
      variant = service_call.result

      TypeVariant::ASPECTS.each do |aspect|
        expect(variant.source_for(aspect)).to eq(source)
      end
    end

    it "excludes only the disabled custom field from the form configuration" do
      variant = service_call.result

      expect(variant.effective_excluded_elements(form_configuration))
        .to contain_exactly(dropped_field.attribute_name)
    end

    it "leaves the disabled custom field off the variant's form configuration" do
      variant = service_call.result.reload

      expect(variant.attribute_groups.flat_map(&:attributes))
        .to contain_exactly("assignee", kept_field.attribute_name)
      expect(variant.custom_fields).to contain_exactly(kept_field)
    end

    it "does not narrow the variant it was built from" do
      service_call

      expect(source.reload.custom_fields).to contain_exactly(kept_field, dropped_field)
      expect(TypeVariant::ASPECTS.map { source.source_for(it) }).to all(be_nil)
    end

    it "does not assign the variant to the project" do
      variant = service_call.result

      expect(project.reload.project_types.where(variant_id: variant.id)).to be_empty
    end

    context "when the project already owns a variant of that name" do
      before { create(:project_owned_type_variant, type:, project:, variant_name: "Bug - Website Relaunch") }

      it "appends a counter" do
        expect(service_call.result.variant_name).to eq("Bug - Website Relaunch (2)")
      end
    end

    # A name is only taken within the project owning it, so the counter must not fire for one
    # nobody in this project can see.
    context "when a variant of that name exists outside the project" do
      before do
        create(:type_variant, type:, variant_name: "Bug - Website Relaunch")
        create(:project_owned_type_variant, type:, project: create(:project),
                                            variant_name: "Bug - Website Relaunch")
      end

      it "keeps the name" do
        expect(service_call.result.variant_name).to eq("Bug - Website Relaunch")
      end
    end
  end

  context "when the project enables every custom field the type configures" do
    let(:project) do
      create(:project, name: "Website Relaunch", work_package_custom_fields: [kept_field, dropped_field])
    end

    it "returns the variant unchanged without creating another" do
      expect { service_call }.not_to change(TypeVariant, :count)

      expect(service_call).to be_success
      expect(service_call.result).to eq(source)
    end
  end

  context "when the disabled custom field is available for all projects" do
    let(:dropped_field) { create(:work_package_custom_field, is_for_all: true) }

    it "returns the variant unchanged, as the project does not narrow anything" do
      expect { service_call }.not_to change(TypeVariant, :count)
      expect(service_call.result).to eq(source)
    end
  end

  context "when the type configures no custom fields" do
    let!(:type) { create(:type, name: "Bug") }

    it "returns the variant unchanged" do
      expect { service_call }.not_to change(TypeVariant, :count)
      expect(service_call.result).to eq(source)
    end
  end

  context "when building from a named variant" do
    let(:third_field) { create(:work_package_custom_field, is_for_all: false) }

    let!(:type) do
      create(:type,
             name: "Bug",
             custom_fields: [kept_field, dropped_field, third_field],
             attribute_groups: [
               ["custom group", %w[assignee] + [kept_field, dropped_field, third_field].map(&:attribute_name)]
             ])
    end

    let(:source) do
      WorkPackageTypes::CreateVariantService
        .new(user: admin, type:)
        .call(variant_name: "Regression")
        .result
        .tap do |variant|
          WorkPackageTypes::ExcludedElements::AddService
            .new(user: admin, variant:)
            .call(aspect: form_configuration, elements: [third_field.attribute_name])
        end
    end

    it "creates the new variant on the type rather than under the source variant" do
      variant = service_call.result

      expect(variant.type_id).to eq(type.id)
    end

    it "names the variant after the source variant's own name" do
      expect(service_call.result.variant_name).to eq("Regression - Website Relaunch")
    end

    it "links every aspect to the source variant" do
      variant = service_call.result

      TypeVariant::ASPECTS.each do |aspect|
        expect(variant.source_for(aspect)).to eq(source)
      end
    end

    # The source is a global variant and the new one is a project's. That is the combination a
    # variant may borrow from, so the links above have to survive validation.
    it "owns the variant while borrowing a configuration nobody owns" do
      expect(service_call.result.project).to eq(project)
      expect(source.project).to be_nil
    end

    it "accumulates the source variant's exclusions with the project's" do
      variant = service_call.result

      expect(variant.effective_excluded_elements(form_configuration))
        .to contain_exactly(dropped_field.attribute_name, third_field.attribute_name)
      expect(variant.custom_fields).to contain_exactly(kept_field)
    end
  end
end
