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

RSpec.describe WorkPackageTypes::ConvertToGlobalService do
  let(:type) { create(:type) }
  let(:project) { create(:project) }
  let(:variant) { create(:project_owned_type_variant, type:, project:, variant_name: "Hardware") }

  subject(:service) { described_class.new(variant:) }

  describe "#call" do
    it "detaches the variant from its project, making it global" do
      expect(service.call).to be_success
      expect(variant.reload.project_id).to be_nil
      expect(variant).not_to be_project_owned
    end

    it "makes the variant available to every project" do
      other_project = create(:project)

      service.call

      expect(TypeVariant.available_in(other_project)).to include(variant)
    end

    context "when the project owns the workflow too" do
      let(:workflow) { create(:project_owned_workflow, project:, name: "Ours") }

      before { variant.update!(workflow:) }

      it "converts the workflow along with the variant" do
        expect(service.call).to be_success

        expect(workflow.reload.project_id).to be_nil
        expect(variant.reload.workflow_id).to eq(workflow.id)
      end

      it "renames it when a global workflow already carries the name" do
        create(:named_workflow, name: "Ours")

        expect(service.call).to be_success

        expect(workflow.reload).to have_attributes(project_id: nil, name: "Ours (2)")
      end

      it "converts it once and leaves the project's other variants pointing at it" do
        sharer = create(:project_owned_type_variant, type:, project:, variant_name: "Sharer", workflow:)

        expect(service.call).to be_success

        expect(workflow.reload.project_id).to be_nil
        expect(sharer.reload.workflow_id).to eq(workflow.id)
      end
    end

    it "leaves a global workflow alone" do
      global = create(:named_workflow, name: "Standard flow")
      variant.update!(workflow: global)

      expect(service.call).to be_success

      expect(global.reload).to have_attributes(project_id: nil, name: "Standard flow")
    end

    it "keeps the owning project using it unchanged" do
      project_type = create(:project_type, project:, type:, variant:)

      service.call

      expect(project_type.reload.variant_id).to eq(variant.id)
    end

    it "preserves the reuse links the variant holds" do
      variant.link!(TypeVariant::DEFAULTS)

      service.call

      expect(variant.reload).to be_linked(TypeVariant::DEFAULTS)
      expect(variant.source_for(TypeVariant::DEFAULTS)).to eq(type.default_variant)
    end

    context "when a global sibling already carries the name" do
      before { create(:type_variant, type:, variant_name: "Hardware") }

      it "fails and leaves the variant project-owned" do
        result = service.call

        expect(result).to be_failure
        expect(result.errors).to be_of_kind(:variant_name, :taken)
        expect(variant.reload.project_id).to eq(project.id)
      end

      it "renames and detaches it when given a free name" do
        expect(service.call(name: "Firmware")).to be_success
        expect(variant.reload).to have_attributes(variant_name: "Firmware", project_id: nil)
      end
    end
  end
end
