#  OpenProject is an open source project management software.
#  Copyright (C) the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require "spec_helper"

RSpec.describe WorkPackages::Scopes::Relatable, ".relatable scope" do
  create_shared_association_defaults_for_work_package_factory

  let(:origin) { create(:work_package) }
  let(:unrelated_work_package) { create(:work_package) }

  let(:directly_related_work_package) do
    create(:work_package).tap do |related_wp|
      create(:relation,
             relation_type: directly_related_work_package_type,
             from: origin,
             to: related_wp)
    end
  end
  let(:directly_related_work_package_type) { relation_type }
  let(:transitively_related_work_package) do
    create(:work_package).tap do |related_wp|
      create(:relation,
             relation_type: transitively_related_work_package_type,
             from: directly_related_work_package,
             to: related_wp)
    end
  end
  let(:transitively_related_work_package_type) { relation_type }

  let(:parent) do
    create(:work_package).tap do |p|
      origin.update(parent: p)
    end
  end
  let(:sibling) do
    create(:work_package, parent:)
  end
  let(:grandparent) do
    create(:work_package).tap do |p|
      parent.update(parent: p)
    end
  end
  let(:aunt) do
    create(:work_package, parent: grandparent)
  end
  let(:origin_child) do
    create(:work_package, parent: origin)
  end
  let(:existing_work_packages) { [] }

  let(:relation_type) { Relation::TYPE_FOLLOWS }
  let(:ignored_relation) { nil }

  subject(:relatable) { WorkPackage.relatable(origin, relation_type, ignored_relation:) }

  it "is an AR scope" do
    expect(relatable)
      .to be_a ActiveRecord::Relation
  end

  context "for an unpersisted work package" do
    let(:origin) { WorkPackage.new }
    let!(:existing_work_packages) { [unrelated_work_package] }

    it "contains every other work package" do
      expect(relatable)
        .to contain_exactly(unrelated_work_package)
    end
  end

  context "with a completely unrelated work package" do
    let!(:existing_work_packages) { [unrelated_work_package] }

    Relation::TYPES.each_key do |current_type|
      context "for the '#{current_type}' type" do
        let(:relation_type) { current_type }

        it "contains the unrelated_work_package" do
          expect(relatable)
            .to contain_exactly(unrelated_work_package)
        end
      end

      context "for the '#{current_type}' type with the other project being in a different project " \
              "and having cross project relations disabled", with_settings: { cross_project_work_package_relations: false } do
        let(:relation_type) { current_type }
        let(:unrelated_work_package) { create(:work_package, project: create(:project)) }

        it "contains the unrelated_work_package" do
          expect(relatable)
            .to be_empty
        end
      end

      context "for the '#{current_type}' type with the other project being in a different project " \
              "and having cross project relations enabled", with_settings: { cross_project_work_package_relations: true } do
        let(:relation_type) { current_type }
        let(:unrelated_work_package) { create(:work_package, project: create(:project)) }

        it "contains the unrelated_work_package" do
          expect(relatable)
            .to contain_exactly(unrelated_work_package)
        end
      end
    end
  end

  context "with a directly related work package" do
    let!(:existing_work_packages) { [directly_related_work_package] }

    Relation::TYPES.each_key do |current_type|
      context "with the existing relation and the queried being '#{current_type}' typed" do
        let(:relation_type) { current_type }

        it "is empty" do
          expect(relatable)
            .to be_empty
        end
      end

      context "with the queried for relation being '#{current_type}' and the existing one something different" do
        let(:relation_type) { current_type }
        let(:directly_related_work_package_type) { Relation::TYPES.keys[(Relation::TYPES.keys.find_index(current_type) + 1)] }

        it "is empty" do
          expect(relatable)
            .to be_empty
        end
      end

      context "with the existing relation and the queried being '#{current_type}' typed but explicitly ignoring the existing" do
        let(:relation_type) { current_type }
        let(:ignored_relation) { directly_related_work_package.relations.first }

        it "contains the directly related work package" do
          expect(relatable)
            .to contain_exactly directly_related_work_package
        end
      end
    end
  end

  context "with a parent and a sibling" do
    let!(:existing_work_packages) { [parent, sibling] }

    Relation::TYPES.each_key do |current_type|
      context "for the '#{current_type}' type" do
        let(:relation_type) { current_type }

        it "contains the sibling" do
          expect(relatable)
            .to contain_exactly(sibling)
        end
      end
    end
  end

  context "with a transitively related work package" do
    let!(:existing_work_packages) { [directly_related_work_package, transitively_related_work_package] }

    context "for a 'follows' relation and the existing relations being in the same direction" do
      it "contains the transitively related work package" do
        expect(relatable)
          .to contain_exactly(transitively_related_work_package)
      end
    end

    context "for a 'follows' relation and the existing relations being in the opposite direction" do
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'precedes' relation and the existing relations being in the opposite direction" do
      let(:relation_type) { Relation::TYPE_PRECEDES }
      let(:directly_related_work_package_type) { Relation::TYPE_FOLLOWS }
      let(:transitively_related_work_package_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'related' relation and the existing relations being in the opposite direction" do
      let(:relation_type) { Relation::TYPE_RELATES }
      let(:directly_related_work_package_type) { Relation::TYPE_RELATES }
      let(:transitively_related_work_package_type) { Relation::TYPE_RELATES }

      # Switching the origin for transitively_related_work_package here since it would be more
      # complicated to switch around the relations
      subject(:relatable) { WorkPackage.relatable(transitively_related_work_package, relation_type) }

      it "includes the not directly related work package" do
        expect(relatable)
          .to contain_exactly(origin)
      end
    end

    context "for a 'parent' relation and the existing relations being 'follows'" do
      let(:relation_type) { Relation::TYPE_PARENT }
      let(:directly_related_work_package_type) { Relation::TYPE_FOLLOWS }
      let(:transitively_related_work_package_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'parent' relation and the existing relations being 'precedes'" do
      let(:relation_type) { Relation::TYPE_PARENT }
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'child' relation and the existing relations being 'follows'" do
      let(:relation_type) { Relation::TYPE_CHILD }
      let(:directly_related_work_package_type) { Relation::TYPE_FOLLOWS }
      let(:transitively_related_work_package_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'child' relation and the existing relations being 'precedes'" do
      let(:relation_type) { Relation::TYPE_CHILD }
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'parent' relation and the existing relations being 'blocks'" do
      let(:relation_type) { Relation::TYPE_PARENT }
      let(:directly_related_work_package_type) { Relation::TYPE_BLOCKS }
      let(:transitively_related_work_package_type) { Relation::TYPE_BLOCKS }

      # This leads to a relationship that, on the domain level does not really make sense where at least
      # transitively, the child blocks the parent. But since such a relation does not strictly carry that
      # semantic in the system, the relationship is not prohibited.
      it "contains the transitively related work package" do
        expect(relatable)
          .to contain_exactly(transitively_related_work_package)
      end
    end

    context "for a 'blocks' relation and the existing relations being 'blocks'" do
      let(:relation_type) { Relation::TYPE_BLOCKS }
      let(:directly_related_work_package_type) { Relation::TYPE_BLOCKS }
      let(:transitively_related_work_package_type) { Relation::TYPE_BLOCKS }

      it "contains the transitively related work package" do
        expect(relatable)
          .to contain_exactly(transitively_related_work_package)
      end
    end

    context "for a 'child' relation and the existing relations being 'blocks'" do
      let(:relation_type) { Relation::TYPE_CHILD }
      let(:directly_related_work_package_type) { Relation::TYPE_BLOCKS }
      let(:transitively_related_work_package_type) { Relation::TYPE_BLOCKS }

      # This leads to a relationship that, on the domain level does not really make sense where at least
      # transitively, the parent blocks the child. But since such a relation does not strictly carry that
      # semantic in the system, the relationship is not prohibited.
      it "contains the transitively related work package" do
        expect(relatable)
          .to contain_exactly(transitively_related_work_package)
      end
    end

    context "for a 'blocks' relation and the existing relations being 'blocks' when ignoring origin`s relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }
      let(:directly_related_work_package_type) { Relation::TYPE_BLOCKS }
      let(:transitively_related_work_package_type) { Relation::TYPE_BLOCKS }
      let(:ignored_relation) { origin.relations.first }

      it "contains the related work packages" do
        expect(relatable)
          .to contain_exactly(directly_related_work_package, transitively_related_work_package)
      end
    end

    context "for a 'follows' relation and the existing relations being of opposite direction but ignoring origin`s relation" do
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:ignored_relation) { origin.relations.first }

      it "contains the related work packages" do
        expect(relatable)
          .to contain_exactly(directly_related_work_package, transitively_related_work_package)
      end
    end
  end

  context "with a child" do
    let!(:existing_work_packages) { [origin_child] }

    Relation::TYPES.each_key do |current_type|
      context "for a '#{current_type}' type" do
        let(:relation_type) { current_type }

        it "is empty" do
          expect(relatable)
            .to be_empty
        end
      end
    end
  end

  context "with two parent child pairs connected by a relation" do
    let(:other_parent) do
      create(:work_package)
    end
    let(:other_child) do
      create(:work_package, parent: other_parent).tap do |wp|
        create(:relation, from: wp, to: origin_child, relation_type: existing_relation_type)
      end
    end
    let!(:existing_work_packages) { [origin_child, other_parent, other_child] }

    context "for a 'follows' and the existing relation being a follows in the opposite direction" do
      let(:existing_relation_type) { Relation::TYPE_FOLLOWS }
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' and the existing relation being a follows in the same direction" do
      # Using precedes will lead to the relation being reversed
      let(:existing_relation_type) { Relation::TYPE_PRECEDES }
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the work packages in the other hierarchy" do
        expect(relatable)
          .to contain_exactly(other_parent, other_child)
      end
    end

    context "for a 'blocks' and the existing relation being a blocks in the same direction" do
      # Using blocked will lead to the relation being reversed
      let(:existing_relation_type) { Relation::TYPE_BLOCKED }
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the work packages in the other hierarchy" do
        expect(relatable)
          .to contain_exactly(other_parent, other_child)
      end
    end

    context "for a 'blocks' and the existing relation being a blocks in the opposite direction" do
      let(:existing_relation_type) { Relation::TYPE_BLOCKS }
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "with a child, parent, grandparent and aunt" do
    let!(:existing_work_packages) { [origin, origin_child, parent, grandparent, aunt] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains grandparent and aunt" do
        expect(relatable)
          .to contain_exactly(grandparent, aunt)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains aunt" do
        expect(relatable)
          .to contain_exactly(aunt)
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains aunt" do
        expect(relatable)
          .to contain_exactly(aunt)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains aunt" do
        expect(relatable)
          .to contain_exactly(aunt)
      end
    end

    context "for a 'parent' relation with a follows relation between child and aunt" do
      let(:relation_type) { Relation::TYPE_PARENT }

      before do
        create(:follows_relation, from: origin_child, to: aunt)
      end

      it "contains grandparent" do
        expect(relatable)
          .to contain_exactly(grandparent)
      end
    end

    context "for a 'child' relation with a follows relation between child and aunt" do
      let(:relation_type) { Relation::TYPE_CHILD }

      before do
        create(:follows_relation, from: origin_child, to: aunt)
      end

      it "contains aunt" do
        expect(relatable)
          .to contain_exactly(aunt)
      end
    end

    context "for a 'relates' relation with a follows relation between child and aunt" do
      let(:relation_type) { Relation::TYPE_RELATES }

      before do
        create(:follows_relation, from: origin_child, to: aunt)
      end

      it "contains aunt and grandparent" do
        expect(relatable)
          .to contain_exactly(aunt, grandparent)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains aunt and grandparent" do
        expect(relatable)
          .to contain_exactly(aunt, grandparent)
      end
    end
  end

  context "with an ancestor chain of 3 work packages" do
    let(:grand_grandparent) do
      create(:work_package).tap do |par|
        grandparent.update(parent: par)
      end
    end

    let!(:existing_work_packages) { [parent, grandparent, grand_grandparent] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains grandparent and grand_grandparent" do
        expect(relatable)
          .to contain_exactly(grandparent, grand_grandparent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "with a descendant chain of 3 work packages" do
    let(:grandchild) do
      create(:work_package, parent: origin_child)
    end
    let(:grand_grandchild) do
      create(:work_package, parent: grandchild)
    end

    let!(:existing_work_packages) { [origin, origin_child, grandchild, grand_grandchild] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains grandchild and grand_grandchild" do
        expect(relatable)
          .to contain_exactly(grandchild, grand_grandchild)
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "with a predecessor having a parent" do
    let(:predecessor_parent) do
      create(:work_package)
    end
    let(:predecessor) do
      create(:work_package, parent: predecessor_parent).tap do |pre|
        create(:relation, from: origin, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [predecessor_parent, predecessor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the predecessor's parent" do
        expect(relatable)
          .to contain_exactly(predecessor_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "with two predecessors being in a hierarchy" do
    let(:predecessor_parent) do
      create(:work_package).tap do |pre|
        create(:relation, from: origin, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let(:predecessor) do
      create(:work_package, parent: predecessor_parent).tap do |pre|
        create(:relation, from: origin, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [predecessor_parent, predecessor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "with a predecessor having a parent that has a predecessor" do
    let(:predecessor_parent_predecessor) do
      create(:work_package).tap do |pre|
        create(:relation, from: predecessor_parent, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let(:predecessor_parent) do
      create(:work_package)
    end
    let(:predecessor) do
      create(:work_package, parent: predecessor_parent).tap do |pre|
        create(:relation, from: origin, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [predecessor_parent_predecessor, predecessor_parent, predecessor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the predecessor's parent" do
        expect(relatable)
          .to contain_exactly(predecessor_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the predecessor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_predecessor)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the predecessor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_predecessor)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "contains the predecessor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_predecessor)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the predecessor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_predecessor)
      end
    end
  end

  context "with a predecessor having a parent that has a successor" do
    let(:predecessor_parent_successor) do
      create(:work_package).tap do |suc|
        create(:relation, to: predecessor_parent, from: suc, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let(:predecessor_parent) do
      create(:work_package)
    end
    let(:predecessor) do
      create(:work_package, parent: predecessor_parent).tap do |pre|
        create(:relation, from: origin, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [predecessor_parent_successor, predecessor_parent, predecessor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the predecessor's parent and its successor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_successor)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the successor of the predecessor's parent" do
        expect(relatable)
          .to contain_exactly(predecessor_parent_successor)
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the predecessor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_successor)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "contains the predecessor's parent's successor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent_successor)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the predecessor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_successor)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "contains the predecessor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_successor)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the predecessor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(predecessor_parent, predecessor_parent_successor)
      end
    end
  end

  context "with a successor having a parent that has a successor" do
    let(:successor_parent_successor) do
      create(:work_package).tap do |suc|
        create(:relation, to: successor_parent, from: suc, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let(:successor_parent) do
      create(:work_package)
    end
    let(:successor) do
      create(:work_package, parent: successor_parent).tap do |suc|
        create(:relation, to: origin, from: suc, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [successor_parent_successor, successor_parent, successor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the successor's parent" do
        expect(relatable)
          .to contain_exactly(successor_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "is contains the successor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_successor)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the successor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_successor)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "contains the successor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_successor)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the successor's parent and that parent's successor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_successor)
      end
    end
  end

  context "with a successor having a parent that has a predecessor" do
    let(:successor_parent_predecessor) do
      create(:work_package).tap do |pre|
        create(:relation, from: successor_parent, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let(:successor_parent) do
      create(:work_package)
    end
    let(:successor) do
      create(:work_package, parent: successor_parent).tap do |suc|
        create(:relation, to: origin, from: suc, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [successor_parent_predecessor, successor_parent, successor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the successor's parent and its predecessor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_predecessor)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the predecessor of the successor's parent" do
        expect(relatable)
          .to contain_exactly(successor_parent_predecessor)
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is contains the successor's parent's predecessor" do
        expect(relatable)
          .to contain_exactly(successor_parent_predecessor)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "is contains the successor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_predecessor)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the successor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_predecessor)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "contains the successor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_predecessor)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the successor's parent and that parent's predecessor" do
        expect(relatable)
          .to contain_exactly(successor_parent, successor_parent_predecessor)
      end
    end
  end

  context "with a parent that has a predecessor" do
    let(:parent_predecessor) do
      create(:work_package).tap do |pre|
        create(:follows_relation, from: parent, to: pre)
      end
    end
    let!(:existing_work_packages) { [parent, parent_predecessor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent's predecessor" do
        expect(relatable)
          .to contain_exactly(parent_predecessor)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the parent's predecessor" do
        expect(relatable)
          .to contain_exactly(parent_predecessor)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the parent's predecessor" do
        expect(relatable)
          .to contain_exactly(parent_predecessor)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the parent's predecessor" do
        expect(relatable)
          .to contain_exactly(parent_predecessor)
      end
    end
  end

  context "with a parent that has a successor" do
    let(:parent_successor) do
      create(:work_package).tap do |suc|
        create(:follows_relation, to: parent, from: suc)
      end
    end
    let!(:existing_work_packages) { [parent, parent_successor] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent's successor" do
        expect(relatable)
          .to contain_exactly(parent_successor)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "contains the parent's successor" do
        expect(relatable)
          .to contain_exactly(parent_successor)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the parent's successor" do
        expect(relatable)
          .to contain_exactly(parent_successor)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the parent's successor" do
        expect(relatable)
          .to contain_exactly(parent_successor)
      end
    end
  end

  context "with a child that has a successor that has a parent and a grandparent" do
    let(:child_successor) do
      create(:work_package, parent: child_successor_parent).tap do |suc|
        create(:follows_relation, from: suc, to: origin_child)
      end
    end
    let(:child_successor_parent) do
      create(:work_package, parent: child_successor_grandparent)
    end
    let(:child_successor_grandparent) do
      create(:work_package)
    end
    let!(:existing_work_packages) { [origin_child, child_successor, child_successor_parent, child_successor_grandparent] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent of the child's successor and the grandparent" do
        expect(relatable)
          .to contain_exactly(child_successor_parent, child_successor_grandparent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the child's successor and that's ancestors" do
        expect(relatable)
          .to contain_exactly(child_successor, child_successor_parent, child_successor_grandparent)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "contains the child's successor and the parent of that" do
        expect(relatable)
          .to contain_exactly(child_successor, child_successor_parent, child_successor_grandparent)
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the child's successor and the parent of that" do
        expect(relatable)
          .to contain_exactly(child_successor, child_successor_parent, child_successor_grandparent)
      end
    end
  end

  context "with a child that has a predecessor that has a parent and a grandparent" do
    let(:child_predecessor) do
      create(:work_package, parent: child_predecessor_parent).tap do |pre|
        create(:follows_relation, from: origin_child, to: pre)
      end
    end
    let(:child_predecessor_parent) do
      create(:work_package, parent: child_predecessor_grandparent)
    end
    let(:child_predecessor_grandparent) do
      create(:work_package)
    end
    let!(:existing_work_packages) { [origin_child, child_predecessor, child_predecessor_parent, child_predecessor_grandparent] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent of the child's predecessor" do
        expect(relatable)
          .to contain_exactly(child_predecessor_parent, child_predecessor_grandparent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the child's predecessor and that's ancestors" do
        expect(relatable)
          .to contain_exactly(child_predecessor, child_predecessor_parent, child_predecessor_grandparent)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the child's predecessor and the parent of that" do
        expect(relatable)
          .to contain_exactly(child_predecessor, child_predecessor_parent, child_predecessor_grandparent)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the child's predecessor and the parent of that" do
        expect(relatable)
          .to contain_exactly(child_predecessor, child_predecessor_parent, child_predecessor_grandparent)
      end
    end
  end

  context "with a child that blocks a work package that has a parent and a grandparent" do
    let(:child_blocked) do
      create(:work_package, parent: child_blocked_parent).tap do |wp|
        create(:relation, relation_type: Relation::TYPE_BLOCKS, from: origin_child, to: wp)
      end
    end
    let(:child_blocked_parent) do
      create(:work_package, parent: child_blocked_grandparent)
    end
    let(:child_blocked_grandparent) do
      create(:work_package)
    end
    let!(:existing_work_packages) { [origin_child, child_blocked, child_blocked_parent, child_blocked_grandparent] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent of the child's blocked work package" do
        expect(relatable)
          .to contain_exactly(child_blocked_parent, child_blocked_grandparent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the work package blocked by the child and that's ancestors" do
        expect(relatable)
          .to contain_exactly(child_blocked, child_blocked_parent, child_blocked_grandparent)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "contains the child's blocked work package and its ancestors" do
        expect(relatable)
          .to contain_exactly(child_blocked, child_blocked_parent, child_blocked_grandparent)
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the child's blocked work package and its ancestors" do
        expect(relatable)
          .to contain_exactly(child_blocked, child_blocked_parent, child_blocked_grandparent)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the child's blocked work package and its ancestors" do
        expect(relatable)
          .to contain_exactly(child_blocked, child_blocked_parent, child_blocked_grandparent)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the child's blocked work package and its ancestors" do
        expect(relatable)
          .to contain_exactly(child_blocked, child_blocked_parent, child_blocked_grandparent)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "with a predecessor that has a child" do
    let(:predecessor_child) do
      create(:work_package, parent: predecessor)
    end
    let(:predecessor) do
      create(:work_package).tap do |pre|
        create(:relation, from: origin, to: pre, relation_type: Relation::TYPE_FOLLOWS)
      end
    end
    let!(:existing_work_packages) { [origin, predecessor, predecessor_child] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the predecessor's child" do
        expect(relatable)
          .to contain_exactly(predecessor_child)
      end
    end

    context "for a 'precedes' relation" do
      let(:relation_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation" do
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it "contains the predecessor's child" do
        expect(relatable)
          .to contain_exactly(predecessor_child)
      end
    end

    context "for a 'relates' relation" do
      let(:relation_type) { Relation::TYPE_RELATES }

      it "contains the predecessor's child" do
        expect(relatable)
          .to contain_exactly(predecessor_child)
      end
    end

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the predecessor's child" do
        expect(relatable)
          .to contain_exactly(predecessor_child)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "contains the predecessor's child" do
        expect(relatable)
          .to contain_exactly(predecessor_child)
      end
    end
  end

  context "with a blocks work package that has a child and a parent" do
    let(:blocks_child) do
      create(:work_package, parent: blocks)
    end
    let(:blocks) do
      create(:work_package, parent: blocks_parent).tap do |bl|
        create(:relation, from: origin, to: bl, relation_type: Relation::TYPE_BLOCKS)
      end
    end
    let(:blocks_parent) do
      create(:work_package)
    end
    let!(:existing_work_packages) { [origin, blocks, blocks_parent, blocks_child] }

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "contains the parent and the child" do
        expect(relatable)
          .to contain_exactly(blocks_parent, blocks_child)
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent" do
        expect(relatable)
          .to contain_exactly(blocks_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the child" do
        expect(relatable)
          .to contain_exactly(blocks_child)
      end
    end
  end

  context "with a blocked work package that has a child and a parent" do
    let(:blocked_child) do
      create(:work_package, parent: blocked)
    end
    let(:blocked) do
      create(:work_package, parent: blocked_parent).tap do |bl|
        create(:relation, from: origin, to: bl, relation_type: Relation::TYPE_BLOCKED)
      end
    end
    let(:blocked_parent) do
      create(:work_package)
    end
    let!(:existing_work_packages) { [origin, blocked, blocked_parent, blocked_child] }

    context "for a 'blocks' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKS }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'blocked' relation" do
      let(:relation_type) { Relation::TYPE_BLOCKED }

      it "contains the parent and the child" do
        expect(relatable)
          .to contain_exactly(blocked_parent, blocked_child)
      end
    end

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent" do
        expect(relatable)
          .to contain_exactly(blocked_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the child" do
        expect(relatable)
          .to contain_exactly(blocked_child)
      end
    end
  end

  context "with a predecessor chain where the first has parent and child and that child has a predecessor" do
    let(:direct_predecessor) do
      create(:work_package).tap do |pre|
        create(:follows_relation, from: origin, to: pre)
      end
    end
    let(:transitive_predecessor) do
      create(:work_package, parent: transitive_predecessor_parent).tap do |pre|
        create(:follows_relation, from: direct_predecessor, to: pre)
      end
    end
    let(:transitive_predecessor_parent) do
      create(:work_package)
    end
    let(:transitive_predecessor_child) do
      create(:work_package, parent: transitive_predecessor)
    end
    let(:transitive_predecessor_child_predecessor) do
      create(:work_package).tap do |pre|
        create(:follows_relation, from: transitive_predecessor_child, to: pre)
      end
    end
    let!(:existing_work_packages) do
      [direct_predecessor,
       transitive_predecessor,
       transitive_predecessor_parent,
       transitive_predecessor_child,
       transitive_predecessor_child_predecessor]
    end

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent at the beginning of the chain" do
        expect(relatable)
          .to contain_exactly(transitive_predecessor_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the child at the beginning of the chain" do
        expect(relatable)
          .to contain_exactly(transitive_predecessor_child)
      end
    end
  end

  context "with a successor chain where the last has parent and child" do
    let(:direct_successor) do
      create(:work_package).tap do |suc|
        create(:follows_relation, to: origin, from: suc)
      end
    end
    let(:transitive_successor) do
      create(:work_package, parent: transitive_successor_parent).tap do |suc|
        create(:follows_relation, to: direct_successor, from: suc)
      end
    end
    let(:transitive_successor_parent) do
      create(:work_package)
    end
    let(:transitive_successor_child) do
      create(:work_package, parent: transitive_successor)
    end
    let!(:existing_work_packages) do
      [direct_successor, transitive_successor, transitive_successor_parent, transitive_successor_child]
    end

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it "contains the parent at the beginning of the chain" do
        expect(relatable)
          .to contain_exactly(transitive_successor_parent)
      end
    end

    context "for a 'child' relation" do
      let(:relation_type) { Relation::TYPE_CHILD }

      it "contains the child at the beginning of the chain" do
        expect(relatable)
          .to contain_exactly(transitive_successor_child)
      end
    end
  end

  context "with a transitively related work package that is also directly related" do
    let!(:existing_work_packages) { [directly_related_work_package, transitively_related_work_package] }
    let!(:additional_direct_relation) do
      create(:relation,
             relation_type: transitively_related_work_package_type,
             from: origin,
             to: transitively_related_work_package)
    end

    context "for a 'follows' relation and the existing relations being in the same direction" do
      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation and the existing relations being in the opposite direction" do
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' relation and the existing relations being of opposite direction and ignoring the direct relation" do
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:ignored_relation) { additional_direct_relation }

      it "is empty" do
        expect(relatable)
          .to be_empty
      end
    end
  end

  context "when ignoring anything else than a single relation" do
    let(:ignored_relation) { transitively_related_work_package.relations }

    it "raises an error" do
      expect { relatable }
        .to raise_error ArgumentError
    end
  end

  context "when ignoring with a relation neither starting nor ending in the work package queried for" do
    let!(:existing_work_packages) { [directly_related_work_package, transitively_related_work_package] }
    let(:ignored_relation) { transitively_related_work_package.relations.first }

    it "raises an error" do
      expect { relatable }
        .to raise_error ArgumentError
    end
  end
end
