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

  let!(:root) do
    create(:type, name: "Bug", custom_fields: [kept_field, dropped_field]).tap do |type|
      type.attribute_groups = [["custom group", %w[assignee] + [kept_field, dropped_field].map(&:attribute_name)]]
      type.save!
    end
  end
  let!(:type) { root }

  let!(:project) do
    create(:project, name: "Website Relaunch", work_package_custom_fields: [kept_field])
  end

  let(:form_configuration) { Type::ConfigurationLink::FORM_CONFIGURATION }

  subject(:service_call) { described_class.new(user: admin, type:).call(project:) }

  before do
    login_as(admin)
    RequestStore.clear!
  end

  context "when the project disables a custom field the type configures" do
    it "is successful and creates a variant" do
      expect { service_call }.to change(Type, :count).by(1)
      expect(service_call).to be_success
    end

    it "names the variant after the type and the project" do
      expect(service_call.result.own_name).to eq("Bug - Website Relaunch")
    end

    it "creates the variant under the type's root" do
      variant = service_call.result

      expect(variant).to be_variant
      expect(variant.parent_id).to eq(root.id)
    end

    it "links every aspect to the type" do
      variant = service_call.result

      Type::ConfigurationLink::ASPECTS.each do |aspect|
        expect(variant.source_for(aspect)).to eq(root)
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

    it "does not narrow the type it was built from" do
      service_call

      expect(root.reload.custom_fields).to contain_exactly(kept_field, dropped_field)
      expect(root.configuration_links).to be_empty
    end

    it "does not assign the variant to the project" do
      variant = service_call.result

      expect(project.reload.project_types.where(variant_id: variant.id)).to be_empty
    end

    context "when a variant of that name already exists" do
      before { create(:type, name: "Bug - Website Relaunch", parent: root) }

      it "appends a counter" do
        expect(service_call.result.own_name).to eq("Bug - Website Relaunch (2)")
      end
    end
  end

  context "when the project enables every custom field the type configures" do
    let(:project) do
      create(:project, name: "Website Relaunch", work_package_custom_fields: [kept_field, dropped_field])
    end

    it "returns the type unchanged without creating a variant" do
      expect { service_call }.not_to change(Type, :count)

      expect(service_call).to be_success
      expect(service_call.result).to eq(type)
    end
  end

  context "when the disabled custom field is available for all projects" do
    let(:dropped_field) { create(:work_package_custom_field, is_for_all: true) }

    it "returns the type unchanged, as the project does not narrow anything" do
      expect { service_call }.not_to change(Type, :count)
      expect(service_call.result).to eq(type)
    end
  end

  context "when the type configures no custom fields" do
    let(:root) { create(:type, name: "Bug") }

    it "returns the type unchanged" do
      expect { service_call }.not_to change(Type, :count)
      expect(service_call.result).to eq(type)
    end
  end

  context "when building from a variant" do
    let(:third_field) { create(:work_package_custom_field, is_for_all: false) }

    let(:root) do
      create(:type, name: "Bug", custom_fields: [kept_field, dropped_field, third_field]).tap do |type|
        type.attribute_groups = [
          ["custom group", %w[assignee] + [kept_field, dropped_field, third_field].map(&:attribute_name)]
        ]
        type.save!
      end
    end

    let(:type) do
      create(:type, name: "Regression", parent: root).tap do |variant|
        WorkPackageTypes::ExcludedElements::AddService
          .new(user: admin, type: variant)
          .call(aspect: form_configuration, elements: [third_field.attribute_name])
      end
    end

    it "creates the new variant under the root rather than under the source variant" do
      variant = service_call.result

      expect(variant.parent_id).to eq(root.id)
    end

    it "names the variant after the source variant's own name" do
      expect(service_call.result.own_name).to eq("Regression - Website Relaunch")
    end

    it "links every aspect to the source variant" do
      variant = service_call.result

      Type::ConfigurationLink::ASPECTS.each do |aspect|
        expect(variant.source_for(aspect)).to eq(type)
      end
    end

    it "accumulates the source variant's exclusions with the project's" do
      variant = service_call.result

      expect(variant.effective_excluded_elements(form_configuration))
        .to contain_exactly(dropped_field.attribute_name, third_field.attribute_name)
      expect(variant.custom_fields).to contain_exactly(kept_field)
    end
  end
end
