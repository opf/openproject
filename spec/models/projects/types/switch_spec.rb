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

RSpec.describe Projects::Types::Switch do
  subject(:switch) { described_class.new(project:, source:, target_id:) }

  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:design) { create(:type, name: "Design", parent: epic) }
  shared_let(:research) { create(:type, name: "Research", parent: epic) }
  shared_let(:bug) { create(:type, name: "Bug") }

  let(:project) { create(:project, types: [design]) }
  let(:source) { design }
  let(:target_id) { research.id }

  describe "#available_targets" do
    it "offers the whole family, the current member included, so the select can open on it" do
      expect(switch.available_targets).to contain_exactly(epic, design, research)
    end

    context "when the project uses the family parent" do
      let(:source) { epic }

      it "still offers the whole family" do
        expect(switch.available_targets).to contain_exactly(epic, design, research)
      end
    end
  end

  describe "#selected_target" do
    it "is the chosen target once one is submitted" do
      expect(switch.selected_target).to eq(research)
    end

    context "when nothing has been chosen yet" do
      let(:target_id) { nil }

      # The dialog opens on the member in use rather than on an empty field.
      it "falls back to the source" do
        expect(switch.selected_target).to eq(design)
      end
    end
  end

  describe "#target" do
    it "resolves the id" do
      expect(switch.target).to eq(research)
    end

    context "when no id was given" do
      let(:target_id) { nil }

      it "is nil rather than raising" do
        expect(switch.target).to be_nil
      end
    end
  end

  describe "validation" do
    it "accepts a sibling variant" do
      expect(switch).to be_valid
    end

    context "when the target is the family parent" do
      let(:target_id) { epic.id }

      it "is accepted, because adopting the parent is a legitimate switch" do
        expect(switch).to be_valid
      end
    end

    context "when nothing was chosen" do
      let(:target_id) { nil }

      it "reports a blank target" do
        expect(switch).not_to be_valid
        expect(switch.errors[:target_id]).to include("can't be blank")
      end
    end

    context "when the target is the member already in use" do
      let(:target_id) { design.id }

      it "is rejected with its own message, since applying it would change nothing" do
        expect(switch).not_to be_valid
        expect(switch.errors[:target_id]).to include("must be different from the one the project uses now")
      end
    end

    context "when the target belongs to another family" do
      let(:target_id) { bug.id }

      it "is rejected" do
        expect(switch).not_to be_valid
        expect(switch.errors[:target_id]).to include("must belong to the same type family")
      end
    end

    context "when the target does not exist" do
      let(:target_id) { 0 }

      it "is rejected without raising" do
        expect(switch).not_to be_valid
        expect(switch.errors[:target_id]).to include("must belong to the same type family")
      end
    end
  end
end
