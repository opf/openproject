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

RSpec.describe Projects::Types::Switch::Impact, with_flag: { type_variants: true } do
  subject(:impact) { described_class.new(project:, source:, target:) }

  shared_let(:story_points) { create(:integer_wp_custom_field, name: "Story points") }
  shared_let(:design_stage) { create(:string_wp_custom_field, name: "Design stage") }

  # let, not shared_let: every example reassigns attribute_groups, and
  # Type#attribute_groups memoizes the parsed groups on the instance, so a
  # reused instance would carry one example's configuration into the next.
  # custom_fields has to be associated explicitly: naming a field in
  # attribute_groups does not activate it on the type, and a work package only
  # stores a value for a field its type carries.
  let(:epic) { create(:type, name: "Epic", custom_fields: [story_points]) }
  # A type owns a base variant holding the configuration it uses by default; a named variant is
  # an additional one. Both sides of the diff are variants, never the type.
  let(:epic_base) { epic.default_variant }
  let(:design) { create(:type_variant, type: epic, variant_name: "Design", custom_fields: [design_stage]) }

  let(:project) do
    create(:project, types: [epic], work_package_custom_fields: [story_points, design_stage])
  end
  let(:source) { epic_base }
  let(:target) { design }

  before do
    epic_base.attribute_groups = [["Details", ["assignee", "custom_field_#{story_points.id}"]]]
    epic_base.save!

    design.attribute_groups = [["Details", ["priority", "custom_field_#{design_stage.id}"]]]
    design.save!
  end

  describe "#work_package_count" do
    before do
      create_list(:work_package, 2, project:, type: epic)
      create(:work_package, project: create(:project, types: [epic]), type: epic)
    end

    it "counts only this project's work packages of the source type" do
      expect(impact.work_package_count).to eq(2)
    end

    # A work package stores the family's root whichever member the project resolves to, so
    # counting the source itself finds none of them as soon as the source is a variant.
    context "when the project already resolves the family to a variant" do
      let(:project) do
        create(:project, types: [design], work_package_custom_fields: [story_points, design_stage])
      end
      let(:source) { design }
      let(:target) { epic_base }

      it "counts the work packages storing the family's root" do
        expect(impact.work_package_count).to eq(2)
      end
    end
  end

  describe "#hidden_fields" do
    it "reports the built-ins and custom fields the target's form drops" do
      expect(impact.hidden_fields.map(&:label)).to contain_exactly("Assignee", "Story points")
    end

    it "tags each field so the preview can label it without re-deriving anything" do
      expect(impact.hidden_fields.map(&:kind)).to contain_exactly(:builtin, :custom_field)
    end
  end

  describe "#new_fields" do
    it "reports what the target's form adds" do
      expect(impact.new_fields.map(&:label)).to contain_exactly("Priority", "Design stage")
    end
  end

  # The form configuration collapses start and due date into a single "date"
  # member, which only the merged label map knows about.
  context "with a date group on the source only" do
    before do
      epic_base.attribute_groups = [["Details", ["date"]]]
      epic_base.save!
    end

    it "labels the merged date member instead of reporting a nameless field" do
      expect(impact.hidden_fields.map(&:label)).to contain_exactly("Date")
    end
  end

  context "with an embedded table on the source only" do
    shared_let(:query) { create(:query) }

    before do
      epic_base.attribute_groups = [["Details", %w[assignee]], ["Children", [:"query_#{query.id}"]]]
      epic_base.save!
    end

    it "names the table by its group heading rather than dropping it silently" do
      table = impact.hidden_fields.find { it.kind == :table }

      expect(table.label).to eq("Children")
    end
  end

  describe "#hidden_custom_field_counts" do
    before do
      work_packages = create_list(:work_package, 3, project:, type: epic)
      work_packages.first(2).each { it.update!(custom_field_values: { story_points.id => 5 }) }
    end

    it "counts only work packages that actually hold a value" do
      expect(impact.hidden_custom_field_counts[story_points.id]).to eq(2)
    end

    it "omits custom fields nobody filled in" do
      expect(impact.hidden_custom_field_counts).not_to have_key(design_stage.id)
    end

    it "answers per field, so the preview never derives an id from a label" do
      hidden = impact.hidden_fields.find { it.kind == :custom_field }

      expect(impact.value_count(hidden)).to eq(2)
    end

    it "has no count for a field that is becoming available rather than hidden" do
      appearing = impact.new_fields.find { it.kind == :custom_field }

      expect(impact.value_count(appearing)).to be_nil
    end
  end

  describe "#missing_statuses" do
    shared_let(:in_review) { create(:status, name: "In review") }
    shared_let(:blocked) { create(:status, name: "Blocked") }
    shared_let(:role) { create(:project_role) }

    before do
      create(:workflow, type: design, role:, old_status: in_review, new_status: blocked)
      create(:work_package, project:, type: epic, status: in_review)
      create(:work_package, project:, type: epic, status: create(:status, name: "On hold"))
    end

    it "reports statuses in use that the target's workflow does not contain, with their counts" do
      expect(impact.missing_statuses.transform_keys(&:name)).to eq("On hold" => 1)
    end
  end

  describe "#anything_affected?" do
    context "when the two types carry the same configuration" do
      shared_let(:role) { create(:project_role) }
      shared_let(:status) { create(:status, name: "New") }

      before do
        design.attribute_groups = [["Details", ["assignee", "custom_field_#{story_points.id}"]]]
        design.save!

        create(:workflow, type: design, role:, old_status: status, new_status: status)
        create(:work_package, project:, type: epic, status:)
      end

      it "is false, so the preview can say so instead of rendering three empty sections" do
        expect(impact).not_to be_anything_affected
      end
    end

    it "is true as soon as one field differs" do
      expect(impact).to be_anything_affected
    end
  end

  context "when the target is a variant linked to its parent's form configuration" do
    let(:bug) { create(:type, name: "Bug") }
    let(:bug_base) { bug.default_variant }

    let(:project) { create(:project, types: [bug], work_package_custom_fields: [story_points]) }
    let(:source) { bug_base }
    # Reloaded because the outer before assigned groups to this instance, and
    # the memoized objects would win over the link's effective source.
    let(:target) { design.reload }

    before do
      bug_base.attribute_groups = [["Details", %w[assignee]]]
      bug_base.save!

      # Restores the link the outer before severed, which is the state a variant
      # is created in.
      design.link!(TypeVariant::FORM_CONFIGURATION, source: epic_base)
    end

    # The variant stores no groups of its own, so the diff has to read the
    # configuration it borrows rather than an empty list.
    it "compares against the configuration the variant actually borrows" do
      expect(impact.new_fields.map(&:label)).to include("Story points")
    end
  end

  describe "how the work packages are scoped" do
    it "requires exactly one of project or work_packages" do
      expect { described_class.new(source:, target:) }.to raise_error(ArgumentError)
      expect { described_class.new(source:, target:, project:, work_packages: WorkPackage.all) }
        .to raise_error(ArgumentError)
    end

    it "is single-project only when scoped to a project" do
      expect(described_class.new(source:, target:, project:)).to be_single_project
      expect(described_class.new(source:, target:, work_packages: WorkPackage.all)).not_to be_single_project
    end

    describe "#project_ids" do
      it "is the one project when scoped to it" do
        expect(described_class.new(source:, target:, project:).project_ids).to contain_exactly(project.id)
      end

      it "is every project applying the source variant otherwise" do
        applied = design
        one = create(:project, types: [epic])
        two = create(:project, types: [epic])
        [one, two].each { |p| p.project_types.find_by(type: epic).update!(variant: applied) }

        impact = described_class.new(source: applied, target: epic_base, work_packages: applied.work_packages)

        expect(impact.project_ids).to contain_exactly(one.id, two.id)
      end
    end

    it "counts across the injected scope rather than a single project" do
      one = create(:project, types: [epic])
      two = create(:project, types: [epic])
      create(:work_package, project: one, type: epic)
      create_list(:work_package, 2, project: two, type: epic)

      impact = described_class.new(source: epic_base, target: design,
                                   work_packages: WorkPackage.where(type_id: epic.id))

      expect(impact.work_package_count).to eq(3)
    end
  end
end
