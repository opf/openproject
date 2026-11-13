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

require "spec_helper"

RSpec.describe CustomField::Hierarchy::Item, :model, with_ee: [:custom_field_hierarchies] do
  let(:custom_field) { create(:custom_field, :hierarchy) }
  let(:root) { custom_field.hierarchy_root }

  context "when custom field is deleted" do
    let!(:luke) { create(:hierarchy_item, parent: root, label: "luke") }
    let!(:mara) { create(:hierarchy_item, parent: luke, label: "mara") }
    let!(:leia) { create(:hierarchy_item, parent: root, label: "leia") }
    let!(:kylo) { create(:hierarchy_item, parent: leia, label: "kylo") }

    before { custom_field.reload }

    it "removes the entire hierarchy tree" do
      expect { custom_field.destroy }.to change(described_class, :count).to(0)
    end
  end

  describe "#descendants_preordered" do
    let!(:luke) { create(:hierarchy_item, parent: root, label: "luke") }
    let!(:mara) { create(:hierarchy_item, parent: luke, label: "mara") }
    let!(:leia) { create(:hierarchy_item, parent: root, label: "leia") }
    let!(:kylo) { create(:hierarchy_item, parent: leia, label: "kylo") }

    it "returns all descendants depth-first in sort order without the item itself" do
      expect(root.descendants_preordered).to eq([luke, mara, leia, kylo])
    end

    it "returns only the descendants of the item" do
      expect(leia.descendants_preordered).to eq([kylo])
    end

    it "returns nothing for a leaf" do
      expect(mara.descendants_preordered).to be_empty
    end
  end
end
