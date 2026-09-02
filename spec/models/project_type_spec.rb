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
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:variant) { create(:type_variant, type: bug, variant_name: "Mobile") }

  describe "validations" do
    it "is valid using a type's base variant" do
      expect(build(:project_type, project:, type: bug, variant: bug.default_variant)).to be_valid
    end

    it "is valid using one of the type's named variants" do
      expect(build(:project_type, project:, type: bug, variant:)).to be_valid
    end

    it "falls back to the type's base variant when none is named" do
      project_type = build(:project_type, project:, type: bug, variant: nil)

      expect(project_type).to be_valid
      expect(project_type.variant).to eq(bug.default_variant)
    end

    it "requires a variant when there is no type to take one from" do
      project_type = build(:project_type, project:, type: nil, variant: nil)

      expect(project_type).not_to be_valid
      expect(project_type.errors).to be_of_kind(:variant, :blank)
    end

    it "rejects a variant of another type" do
      other = create(:type_variant, type: create(:type, name: "Risk"), variant_name: "Blocker")
      project_type = build(:project_type, project:, type: bug, variant: other)

      expect(project_type).not_to be_valid
      expect(project_type.errors).to be_of_kind(:variant, :must_belong_to_the_type)
    end

    it "uses a type at most once per project" do
      create(:project_type, project:, type: bug)
      duplicate = build(:project_type, project:, type: bug, variant:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors).to be_of_kind(:type_id, :taken)
    end

    it "uses the same type in another project" do
      create(:project_type, project:, type: bug)

      expect(build(:project_type, project: create(:project), type: bug)).to be_valid
    end
  end

  describe "dropping a variant in use" do
    it "is refused" do
      create(:project_type, project:, type: bug, variant:)

      expect { variant.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end
  end
end
