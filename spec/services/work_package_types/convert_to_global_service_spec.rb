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

RSpec.describe WorkPackageTypes::ConvertToGlobalService, with_flag: { type_variants: true } do
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

    it "keeps the owning project using it unchanged" do
      project_type = create(:project_type, project:, type:, variant:)

      service.call

      expect(project_type.reload.variant_id).to eq(variant.id)
    end

    it "preserves the reuse links the variant holds" do
      source = create(:type_variant, type:, variant_name: "Base config")
      variant.update!(workflows_source: source)

      service.call

      expect(variant.reload.workflows_source_id).to eq(source.id)
      expect(variant.effective_source_for(TypeVariant::WORKFLOWS)).to eq(source)
    end

    it "keeps variants that reuse its configuration linked to it" do
      borrower = create(:project_owned_type_variant, type:, project:, variant_name: "Borrower")
      borrower.update!(workflows_source: variant)

      service.call

      expect(borrower.reload.workflows_source_id).to eq(variant.id)
      expect(borrower.effective_source_for(TypeVariant::WORKFLOWS)).to eq(variant)
      expect(borrower).to be_valid
    end

    context "when a global sibling already carries the name" do
      before { create(:type_variant, type:, variant_name: "Hardware") }

      it "fails and leaves the variant project-owned" do
        result = service.call

        expect(result).to be_failure
        expect(result.errors).to be_of_kind(:variant_name, :taken)
        expect(variant.reload.project_id).to eq(project.id)
      end
    end
  end
end
