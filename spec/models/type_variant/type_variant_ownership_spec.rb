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

RSpec.describe TypeVariant, "ownership" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }

  describe "#project_owned?" do
    it "is false for a variant every project may use" do
      expect(create(:type_variant, type:)).not_to be_project_owned
    end

    it "is true for a variant belonging to one project" do
      expect(create(:project_owned_type_variant, type:, project:)).to be_project_owned
    end

    it "is false for a type's own base configuration" do
      expect(type.default_variant).not_to be_project_owned
    end
  end

  describe "scopes" do
    shared_let(:global) { create(:type_variant, type:, variant_name: "Global") }
    shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
    shared_let(:theirs) { create(:project_owned_type_variant, type:, project: other_project, variant_name: "Theirs") }

    it "counts only unowned variants as global" do
      expect(described_class.global).to include(global)
      expect(described_class.global).not_to include(ours, theirs)
    end

    it "counts a type's base configuration as global" do
      expect(described_class.global).to include(type.default_variant)
    end

    it "returns just one project's own variants" do
      expect(described_class.owned_by(project)).to contain_exactly(ours)
    end

    # What a project may configure with or switch onto: everything global, plus its own.
    it "offers a project the global variants and its own" do
      available = described_class.available_in(project)

      expect(available).to include(global, ours, type.default_variant)
      expect(available).not_to include(theirs)
    end
  end

  describe "validations" do
    it "lets two projects each own a variant of the same name" do
      create(:project_owned_type_variant, type:, project:, variant_name: "Internal")
      theirs = build(:project_owned_type_variant, type:, project: other_project, variant_name: "Internal")

      expect(theirs).to be_valid
    end

    it "still refuses two variants of one name inside a project" do
      create(:project_owned_type_variant, type:, project:, variant_name: "Internal")
      duplicate = build(:project_owned_type_variant, type:, project:, variant_name: "Internal")

      expect(duplicate).not_to be_valid
    end

    it "still refuses two global variants of one name" do
      create(:type_variant, type:, variant_name: "Internal")
      duplicate = build(:type_variant, type:, variant_name: "Internal")

      expect(duplicate).not_to be_valid
    end

    # A name may be taken globally and owned at once: they are told apart in the UI by the
    # owning project, and neither project can see the other's.
    it "lets a project own a variant whose name a global variant already has" do
      create(:type_variant, type:, variant_name: "Internal")
      owned = build(:project_owned_type_variant, type:, project:, variant_name: "Internal")

      expect(owned).to be_valid
    end

    it "refuses to let a project own a type's base configuration" do
      base = type.default_variant
      base.project = project

      expect(base).not_to be_valid
      expect(base.errors[:project]).to be_present
    end
  end

  describe "when the owning project goes away" do
    it "takes the variant with it" do
      owned = create(:project_owned_type_variant, type:, project: create(:project))

      owned.project.destroy

      expect(described_class).not_to exist(owned.id)
    end
  end
end
