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

RSpec.describe WorkPackageTypes::DeleteVariantService, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }

  let(:variant) { create(:type_variant, type: bug, variant_name: "Hardware") }
  let(:sibling) { create(:type_variant, type: bug, variant_name: "Firmware") }

  subject(:service) { described_class.new(user: admin, model: variant) }

  context "when no project applies the variant" do
    it "deletes it" do
      expect(service.call(target: nil)).to be_success
      expect { variant.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when projects apply the variant" do
    let(:project_a) { create(:project, types: [bug]) }
    let(:project_b) { create(:project, types: [bug]) }

    before do
      project_a.project_types.find_by(type: bug).update!(variant:)
      project_b.project_types.find_by(type: bug).update!(variant:)
    end

    context "without a target" do
      it "refuses, leaving the variant and the projects on it" do
        expect(service.call(target: nil)).to be_failure
        expect(variant.reload).to be_present
        expect(project_a.project_types.find_by(type: bug).variant).to eq(variant)
      end
    end

    context "with a sibling target" do
      it "switches every applying project to it and deletes the variant, without retyping work packages" do
        work_package = create(:work_package, project: project_a, type: bug)

        expect(service.call(target: sibling)).to be_success
        expect { variant.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(project_a.project_types.find_by(type: bug).variant).to eq(sibling)
        expect(project_b.project_types.find_by(type: bug).variant).to eq(sibling)
        expect(work_package.reload.type).to eq(bug)
      end
    end

    context "when deletion is refused because the variant is linked" do
      before do
        borrower = create(:type_variant, type: bug, variant_name: "Borrower")
        borrower.update_columns(workflows_source_id: variant.id)
      end

      it "rolls the switch back and reports why" do
        result = service.call(target: sibling)

        expect(result).to be_failure
        expect(result.errors.full_messages.to_sentence).to match(/reused/i)
        expect(variant.reload).to be_present
        expect(project_a.project_types.find_by(type: bug).variant).to eq(variant)
      end
    end
  end
end
