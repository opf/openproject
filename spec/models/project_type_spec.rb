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

RSpec.describe ProjectType do
  shared_let(:project) { create(:project) }
  shared_let(:root) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type, name: "Mobile Bug", parent: root) }

  describe "validations" do
    it "is valid using a root without a variant" do
      expect(build(:project_type, project:, type: root)).to be_valid
    end

    it "is valid using a root with one of its variants" do
      expect(build(:project_type, project:, type: root, variant:)).to be_valid
    end

    it "rejects a variant of another family" do
      other_variant = create(:type, name: "Blocker", parent: create(:type, name: "Risk"))
      project_type = build(:project_type, project:, type: root, variant: other_variant)

      expect(project_type).not_to be_valid
      expect(project_type.errors).to be_of_kind(:variant, :must_belong_to_the_type)
    end

    it "rejects a root as the variant" do
      project_type = build(:project_type, project:, type: root, variant: root)

      expect(project_type).not_to be_valid
      expect(project_type.errors).to be_of_kind(:variant, :must_belong_to_the_type)
    end

    it "uses a type at most once per project" do
      create(:project_type, project:, type: root)
      duplicate = build(:project_type, project:, type: root, variant:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors).to be_of_kind(:type_id, :taken)
    end

    it "uses the same type in another project" do
      create(:project_type, project:, type: root)

      expect(build(:project_type, project: create(:project), type: root)).to be_valid
    end

    it "rejects a second member of a family already used" do
      create(:project_type, project:, type: root)
      duplicate = build(:project_type, project:, type: root, variant:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors).to be_of_kind(:type_id, :taken)
    end

    it "rejects a variant as the type" do
      project_type = build(:project_type, project:, type: variant)

      expect(project_type).not_to be_valid
      expect(project_type.errors).to be_of_kind(:type, :must_be_a_root_type)
    end

    it "rejects a variant assigned as a raw type_id" do
      project_type = build(:project_type, project:, type_id: variant.id)

      expect(project_type).not_to be_valid
      expect(project_type.errors).to be_of_kind(:type, :must_be_a_root_type)
    end
  end

  describe "#effective_type" do
    it "is the variant when the project resolves to one" do
      expect(build(:project_type, type: root, variant:).effective_type).to eq(variant)
    end

    it "is the root when it does not" do
      expect(build(:project_type, type: root).effective_type).to eq(root)
    end
  end

  describe "dropping a variant" do
    it "degrades the project to the root rather than removing the type" do
      project_type = create(:project_type, project:, type: root, variant:)

      variant.destroy!

      expect(project_type.reload.variant).to be_nil
      expect(project_type.type).to eq(root)
      expect(project_type.effective_type).to eq(root)
    end
  end
end
