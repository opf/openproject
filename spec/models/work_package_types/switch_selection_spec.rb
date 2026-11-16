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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe WorkPackageTypes::SwitchSelection do
  subject(:selection) { described_class.new(type:, projects:) }

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type:, variant_name: "Firmware") }

  shared_let(:on_base) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:on_hardware) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:also_on_hardware) { create(:project, name: "Forge", types: [hardware]) }
  shared_let(:owning) { create(:project, name: "Laboratory") }
  shared_let(:lab) { create(:project_owned_type_variant, type:, project: owning, variant_name: "Lab") }
  shared_let(:elsewhere) { create(:project_owned_type_variant, type:, project: on_base, variant_name: "Elsewhere") }

  before_all do
    create(:project_type, project: owning, type:, variant: lab)
  end

  context "with projects sharing their variant" do
    let(:projects) { [on_hardware, also_on_hardware] }

    it "has that one source" do
      expect(selection).to be_single_source
      expect(selection.source).to eq(hardware)
    end

    it "refuses the variant every project already uses" do
      expect(selection.refusal(hardware)).to eq("The selected projects already use this type or variant.")
    end

    it "previews a move elsewhere across the selected projects only" do
      impact = selection.impact(firmware)

      expect(impact.source).to eq(hardware)
      expect(impact.project_ids).to contain_exactly(on_hardware.id, also_on_hardware.id)
    end

    it "previews nothing for the variant in use" do
      expect(selection.impact(hardware)).to be_nil
    end
  end

  context "with projects on different variants" do
    let(:projects) { [on_base, on_hardware] }

    it "has several sources" do
      expect(selection).not_to be_single_source
      expect(selection.sources).to eq([type.default_variant, hardware])
    end

    it "refuses nothing a project already uses" do
      expect(selection.refusal(hardware)).to be_nil
    end

    it "previews nothing" do
      expect(selection.impact(firmware)).to be_nil
    end
  end

  context "with a single project" do
    let(:projects) { [owning] }

    it "offers its own variants too" do
      expect(selection.targets).to include(lab, hardware, type.default_variant)
    end

    it "refuses the variant it already uses" do
      expect(selection.refusal(lab)).to eq("The project already uses this type or variant.")
    end

    it "finds no target owned by another project" do
      expect(selection.target(elsewhere.id)).to be_nil
      expect(selection.target(hardware.id)).to eq(hardware)
    end

    it "refuses a target outside the offer" do
      expect(selection.refusal(nil)).to eq("Choose a type or variant that every selected project can use.")
    end
  end

  context "with several projects, one of them owning a variant" do
    let(:projects) { [owning, on_base] }

    it "offers the shared variants only" do
      expect(selection.targets).to contain_exactly(type.default_variant, hardware, firmware)
    end
  end
end
