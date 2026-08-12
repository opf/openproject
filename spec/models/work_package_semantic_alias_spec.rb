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

RSpec.describe WorkPackageSemanticAlias do
  let(:work_package) { create(:work_package) }

  describe "validations" do
    it "is valid with an identifier and work_package" do
      record = described_class.new(identifier: "PROJ-1", work_package:)
      expect(record).to be_valid
    end

    it "requires identifier" do
      record = described_class.new(work_package:)
      expect(record).not_to be_valid
      expect(record.errors[:identifier]).to be_present
    end

    it "requires work_package" do
      record = described_class.new(identifier: "PROJ-1")
      expect(record).not_to be_valid
      expect(record.errors[:work_package]).to be_present
    end

    it "enforces identifier uniqueness" do
      described_class.create!(identifier: "PROJ-1", work_package:)
      duplicate = described_class.new(identifier: "PROJ-1", work_package:)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:identifier]).to be_present
    end
  end

  describe "associations" do
    it "belongs to a work_package" do
      record = described_class.create!(identifier: "PROJ-1", work_package:)
      expect(record.work_package).to eq(work_package)
    end
  end

  describe ".for_slug_prefix" do
    def alias_for(identifier)
      described_class.create!(identifier:, work_package:)
    end

    it "matches identifiers of the exact form <slug>-<digits>" do
      matching = alias_for("my-1")
      alias_for("my-abc")

      expect(described_class.for_slug_prefix("my")).to contain_exactly(matching)
    end

    it "does not over-match when another slug starts with the given slug plus a dash" do
      matching = alias_for("my-2")
      alias_for("my-project-42")

      expect(described_class.for_slug_prefix("my")).to contain_exactly(matching)
    end

    it "matches case-sensitively" do
      matching = alias_for("PROJ-1")
      alias_for("proj-1")

      expect(described_class.for_slug_prefix("PROJ")).to contain_exactly(matching)
    end
  end

  describe WorkPackage do
    describe "#semantic_aliases" do
      let(:wp) { create(:work_package) }

      it "exposes all registry entries" do
        entry1 = WorkPackageSemanticAlias.create!(identifier: "PROJ-1", work_package: wp)
        entry2 = WorkPackageSemanticAlias.create!(identifier: "OLD-1", work_package: wp)

        expect(wp.semantic_aliases).to contain_exactly(entry1, entry2)
      end
    end
  end
end
