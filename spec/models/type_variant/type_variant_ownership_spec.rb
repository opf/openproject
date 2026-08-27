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

  # Which variant new projects start with is an instance-wide decision, and a project's own
  # variant is visible in that project alone, so a new project could not use it.
  describe "activating a variant in new projects" do
    it "refuses a variant a project owns" do
      owned = build(:project_owned_type_variant, type:, project:, enabled_in_new_projects: true)

      expect(owned).not_to be_valid
      expect(owned.errors[:enabled_in_new_projects]).to be_present
    end

    it "refuses one that is already owned when the flag is set later" do
      owned = create(:project_owned_type_variant, type:, project:)

      expect(owned.update(enabled_in_new_projects: true)).to be(false)
    end

    it "still allows a global variant" do
      global = build(:type_variant, type:, variant_name: "Mobile", enabled_in_new_projects: true)

      expect(global).to be_valid
    end
  end

  # Every screen addresses a variant through this, so carrying the owner here is what keeps a
  # caller from reaching an owned variant at administration's address by forgetting to say so.
  describe "#path_args" do
    it "names the project owning the variant" do
      owned = create(:project_owned_type_variant, type:, project:)

      expect(owned.path_args).to eq(type_id: type.id, variant_id: owned.id, in_project_id: project)
    end

    it "names no project for one every project may use" do
      global = create(:type_variant, type:, variant_name: "Mobile")

      expect(global.path_args).to eq(type_id: type.id, variant_id: global.id)
    end

    # The base variant is the type's own configuration and can never be owned.
    it "names only the type for the base variant" do
      expect(type.default_variant.path_args).to eq(type_id: type.id)
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
