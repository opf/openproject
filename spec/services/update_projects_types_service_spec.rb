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

require "spec_helper"

RSpec.describe UpdateProjectsTypesService do
  subject(:service_call) { described_class.new(project).call(ids) }

  let(:project) { create(:project, no_types: true) }

  shared_examples "activating custom fields" do
    let!(:custom_field) { create(:text_wp_custom_field, type_variants: types.map(&:default_variant)) }

    it "updates the active custom fields" do
      expect { service_call }
        .to change { project.reload.work_package_custom_field_ids }
        .from([])
        .to([custom_field.id])
    end

    it "does not activate the same custom field twice" do
      expect { service_call }.to change { project.reload.work_package_custom_field_ids }
      expect { described_class.new(project).call(ids) }.not_to change { project.reload.work_package_custom_field_ids }
    end

    context "for a project already using those types" do
      let(:project) { create(:project, types:, work_package_custom_fields: [create(:text_wp_custom_field)]) }

      it "does not change custom fields" do
        expect { service_call }.not_to change { project.reload.work_package_custom_field_ids }
      end
    end
  end

  context "with ids provided" do
    let(:types) { create_list(:type, 2) }
    let(:ids) { types.map(&:id) }

    it "enables exactly those types, each on its base variant" do
      expect(service_call).to be_truthy
      expect(project.enabled_types).to match_array(types)
      expect(project.project_types.map(&:variant)).to match_array(types.map(&:default_variant))
    end

    include_examples "activating custom fields"
  end

  context "with no id passed" do
    let(:ids) { [] }
    let(:project) { create(:project) }

    it "leaves the project without any type" do
      expect(service_call).to be_truthy
      expect(project.enabled_types).to be_empty
    end
  end

  context "with nil passed" do
    let(:ids) { nil }
    let(:project) { create(:project) }

    it "leaves the project without any type" do
      expect(service_call).to be_truthy
      expect(project.enabled_types).to be_empty
    end
  end

  # A project applies one variant per type, and the bulk form names types only, so a type it
  # already runs through a named variant keeps that variant rather than being reset to the base.
  context "when the project applies a named variant of a type it keeps" do
    shared_let(:type) { create(:type) }
    shared_let(:variant) { create(:type_variant, type:) }

    let(:project) { create(:project, types: [variant]) }
    let(:ids) { [type.id] }

    it "leaves the applied variant alone" do
      expect(service_call).to be_truthy
      expect(project.reload.project_types.sole.variant).to eq(variant)
    end
  end

  context "when the id of a type in use is not provided" do
    shared_let(:used_type) { create(:type, name: "In use") }
    shared_let(:other_type) { create(:type, name: "Other") }

    let(:project) { create(:project, types: [used_type, other_type]) }
    let(:ids) { [other_type.id] }

    before { create(:work_package, project:, type: used_type) }

    it "returns false and sets an error message" do
      expect(service_call).to be_falsey
      expect(project.errors.symbols_for(:types)).to contain_exactly(:in_use_by_work_packages)
      expect(project.enabled_types).to contain_exactly(used_type, other_type)
    end
  end
end
