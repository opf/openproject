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

RSpec.describe WorkPackageRelationsTab::RelationsMediator do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) { create(:admin) }

  current_user { user }

  subject(:mediator) { described_class.new(work_package:) }

  context "with a work package having multiple kind of relations" do
    shared_let_work_packages(<<~TABLE)
      hierarchy         | predecessors | relates to
      predecessor       |              |
      related 1         |              |
      related 2         |              | work package
      successor         | work package |
      parent            |              |
        work package    | predecessor  | related 1
          child         |              |
    TABLE

    it "returns all relations of the work package" do
      expect(mediator.relation_group(Relation::TYPE_PARENT).all_relation_items).to contain_exactly(
        have_attributes(class: described_class::RelationItem, type: Relation::TYPE_PARENT, related: parent, visibility: :visible)
      )
      expect(mediator.relation_group(Relation::TYPE_CHILD).all_relation_items).to contain_exactly(
        have_attributes(class: described_class::RelationItem, type: Relation::TYPE_CHILD, related: child, visibility: :visible)
      )
      expect(mediator.relation_group(Relation::TYPE_PRECEDES).all_relation_items).to contain_exactly(
        have_attributes(class: described_class::RelationItem, type: Relation::TYPE_PRECEDES, related: successor,
                        visibility: :visible)
      )
      expect(mediator.relation_group(Relation::TYPE_FOLLOWS).all_relation_items).to contain_exactly(
        have_attributes(class: described_class::RelationItem, type: Relation::TYPE_FOLLOWS, related: predecessor,
                        visibility: :visible)
      )
      expect(mediator.relation_group(Relation::TYPE_RELATES).all_relation_items).to contain_exactly(
        have_attributes(class: described_class::RelationItem, type: Relation::TYPE_RELATES, related: related1,
                        visibility: :visible),
        have_attributes(class: described_class::RelationItem, type: Relation::TYPE_RELATES, related: related2,
                        visibility: :visible)
      )
    end

    describe "#all_relations_count" do
      it "returns the total number of relations" do
        expect(mediator.all_relations_count).to eq 6
      end
    end

    context "when the related work packages are not visible by the user " \
            "because they are in a project the user does not have access to" do
      let(:other_project) { create(:project) }
      let(:user) { create(:user, member_with_permissions: { other_project => %i[view_work_packages] }) }

      current_user { user }

      before do
        work_package.project = other_project
        work_package.save!
      end

      it "returns all relations of the work package as ghost relations (not visible)" do
        expect(mediator.relation_group(Relation::TYPE_PARENT).all_relation_items).to contain_exactly(
          have_attributes(class: described_class::RelationItem, type: Relation::TYPE_PARENT, related: parent,
                          visibility: :ghost)
        )
        expect(mediator.relation_group(Relation::TYPE_CHILD).all_relation_items).to contain_exactly(
          have_attributes(class: described_class::RelationItem, type: Relation::TYPE_CHILD, related: child, visibility: :ghost)
        )
        expect(mediator.relation_group(Relation::TYPE_PRECEDES).all_relation_items).to contain_exactly(
          have_attributes(class: described_class::RelationItem, type: Relation::TYPE_PRECEDES, related: successor,
                          visibility: :ghost)
        )
        expect(mediator.relation_group(Relation::TYPE_FOLLOWS).all_relation_items).to contain_exactly(
          have_attributes(class: described_class::RelationItem, type: Relation::TYPE_FOLLOWS, related: predecessor,
                          visibility: :ghost)
        )
        expect(mediator.relation_group(Relation::TYPE_RELATES).all_relation_items).to contain_exactly(
          have_attributes(class: described_class::RelationItem, type: Relation::TYPE_RELATES, related: related1,
                          visibility: :ghost),
          have_attributes(class: described_class::RelationItem, type: Relation::TYPE_RELATES, related: related2,
                          visibility: :ghost)
        )
      end

      describe "#all_relations_count" do
        it "returns the total number of relations" do
          expect(mediator.all_relations_count).to eq 6
        end
      end
    end
  end

  describe "RelationGroup" do
    shared_let(:work_package) { create(:work_package) }

    let(:group) { mediator.relation_group("follows") }

    describe "#type" do
      it "returns the type as String" do
        expect(group.type).to eq "follows"
      end

      it "defines a predicate method for the type" do
        expect(group.type).to be_follows
      end
    end

    context "having a closest relation" do
      shared_let_work_packages(<<~TABLE)
        hierarchy    | MTWTFSS    | scheduling mode | successors
        predecessor1 | XXX        | manual          | work_package with lag 2
        predecessor2 | XX         | manual          | work_package with lag 7
        predecessor3 | XX         | manual          | work_package with lag 7
        predecessor4 |            | manual          | work_package with lag 10
        work_package |          X | automatic       |
      TABLE

      describe "#closest_relation" do
        it "returns the closest follows relation of the group" do
          expect(group.closest_relation).to eq _table.relation(predecessor: predecessor2)
        end
      end

      describe "#closest_relation?(relation)" do
        it "returns true if the given relation is the closest one, false otherwise" do
          expect(group.closest_relation?(_table.relation(predecessor: predecessor2))).to be true
          expect(group.closest_relation?(_table.relation(predecessor: predecessor1))).to be false
        end
      end
    end

    context "without having a closest relation" do
      shared_let_work_packages(<<~TABLE)
        hierarchy    | MTWTFSS    | scheduling mode | predecessors
        predecessor1 |            | manual          |
        work_package |          X | automatic       | predecessor1 with lag 2
      TABLE

      describe "#closest_relation" do
        it "returns nil" do
          expect(group.closest_relation).to be_nil
        end
      end

      describe "#closest_relation?(relation)" do
        it "always returns false" do
          expect(group.closest_relation?(_table.relation(predecessor: predecessor1))).to be false
        end
      end
    end

    describe "#all_relation_items" do
      let(:work_package) { build_stubbed(:work_package) }

      it "returns all relations of the group as RelationItem instances, " \
         "ordered by oldest first (lowest id first), mixing visible and ghost relations" do
        relation_group = described_class::RelationGroup.new(
          type: Relation::TYPE_RELATES,
          work_package:,
          visible_relations: [
            build_stubbed(:relates_relation, id: 4, from: work_package),
            build_stubbed(:relates_relation, id: 2, from: work_package)
          ],
          ghost_relations: [
            build_stubbed(:relates_relation, id: 1, from: work_package),
            build_stubbed(:relates_relation, id: 3, from: work_package)
          ]
        )
        expect(relation_group.all_relation_items).to match(
          [
            have_attributes(class: described_class::RelationItem, relation: have_attributes(id: 1)),
            have_attributes(class: described_class::RelationItem, relation: have_attributes(id: 2)),
            have_attributes(class: described_class::RelationItem, relation: have_attributes(id: 3)),
            have_attributes(class: described_class::RelationItem, relation: have_attributes(id: 4))
          ]
        )
      end
    end
  end
end
