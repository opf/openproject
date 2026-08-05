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

RSpec.describe WorkPackage::Categories do
  shared_let(:project) { create(:project) }
  shared_let(:category_a) { create(:category, project:, name: "Alpha") }
  shared_let(:category_b) { create(:category, project:, name: "Beta") }
  shared_let(:category_c) { create(:category, project:, name: "Gamma") }

  let(:work_package) { create(:work_package, project:) }

  describe "#category_ids_replacements" do
    it "replaces the whole set on save" do
      work_package.category_ids_replacements = [category_b.id, category_a.id]
      work_package.save!

      expect(work_package.reload.categories).to eq([category_a, category_b])
    end

    it "clears the set when assigned an empty array" do
      work_package.category_ids_replacements = [category_a.id]
      work_package.save!

      work_package.category_ids_replacements = []
      work_package.save!

      expect(work_package.reload.categories).to be_empty
    end

    it "leaves the set untouched when nil" do
      work_package.category_ids_replacements = [category_a.id]
      work_package.save!

      work_package.subject = "Changed"
      work_package.save!

      expect(work_package.reload.categories).to eq([category_a])
    end

    it "is consumed by a single save" do
      work_package.category_ids_replacements = [category_a.id]
      work_package.save!

      expect(work_package.category_ids_replacements).to be_nil
    end

    it "only touches the rows that actually change" do
      work_package.category_ids_replacements = [category_a.id, category_b.id]
      work_package.save!
      untouched = work_package.work_package_categories.find_by(category_id: category_a.id)

      work_package.category_ids_replacements = [category_a.id, category_c.id]
      work_package.save!

      expect(work_package.reload.categories).to eq([category_a, category_c])
      expect(work_package.work_package_categories.find_by(category_id: category_a.id).id)
        .to eq(untouched.id)
    end
  end

  describe "the deprecated category_id column" do
    it "mirrors the alphabetically first category of an override" do
      work_package.category_ids_replacements = [category_c.id, category_b.id]
      work_package.save!

      expect(work_package.reload.category).to eq(category_b)
    end

    it "is cleared when the set is cleared" do
      work_package.category_ids_replacements = [category_a.id]
      work_package.save!

      work_package.category_ids_replacements = []
      work_package.save!

      expect(work_package.reload.category).to be_nil
    end

    it "is mirrored into the association when written on its own" do
      work_package.category = category_b
      work_package.save!

      expect(work_package.reload.categories).to eq([category_b])
    end

    it "always agrees with the first category" do
      work_package.category_ids_replacements = [category_c.id, category_a.id, category_b.id]
      work_package.save!
      work_package.reload

      expect(work_package.category).to eq(work_package.categories.first)
    end
  end

  describe "#effective_categories" do
    it "returns the written categories without a pending change" do
      work_package.category_ids_replacements = [category_a.id]
      work_package.save!

      expect(work_package.reload.effective_categories).to eq([category_a])
    end

    it "returns the pending override, name-ordered" do
      work_package.category_ids_replacements = [category_c.id, category_a.id]

      expect(work_package.effective_categories).to eq([category_a, category_c])
    end

    it "returns the pending legacy category_id change" do
      work_package.category = category_b

      expect(work_package.effective_categories).to eq([category_b])
    end

    it "prefers the override over a pending legacy change" do
      work_package.category = category_b
      work_package.category_ids_replacements = [category_a.id]

      expect(work_package.effective_categories).to eq([category_a])
    end
  end

  describe "#assignable_categories" do
    it "returns the project's categories, name-ordered" do
      expect(work_package.assignable_categories).to eq([category_a, category_b, category_c])
    end

    it "excludes categories of other projects" do
      other_project_category = create(:category, project: create(:project), name: "Aaa foreign")

      expect(work_package.assignable_categories).not_to include(other_project_category)
    end

    it "is empty without a project" do
      expect(WorkPackage.new.assignable_categories).to be_empty
    end
  end

  describe "scopes" do
    let!(:categorized) do
      create(:work_package, project:).tap do |wp|
        wp.category_ids_replacements = [category_a.id]
        wp.save!
      end
    end
    let!(:uncategorized) { create(:work_package, project:) }

    describe ".with_category" do
      it "returns only work packages carrying the given category" do
        expect(WorkPackage.with_category(category_a.id)).to contain_exactly(categorized)
      end

      it "returns nothing for an unassigned category" do
        expect(WorkPackage.with_category(category_b.id)).to be_empty
      end
    end

    describe ".without_category" do
      it "returns only work packages without any category" do
        expect(WorkPackage.without_category).to contain_exactly(uncategorized)
      end
    end
  end

  describe "#default_assign" do
    let(:member) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }

    before { category_a.update!(assigned_to: member) }

    it "takes the assignee from the primary category of a pending override" do
      work_package = build(:work_package, project:, assigned_to: nil)
      work_package.category_ids_replacements = [category_b.id, category_a.id]
      work_package.save!

      expect(work_package.assigned_to).to eq(member)
    end
  end
end
