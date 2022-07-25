#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
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

require 'spec_helper'

describe WorkPackages::Scopes::Relatable, '.relatable scope' do
  let(:project) { create(:project) }
  let(:origin) { create(:work_package, project:) }
  let(:unrelated_work_package) { create(:work_package, project:) }

  let(:directly_related_work_package) do
    create(:work_package, project:).tap do |related_wp|
      create(:relation,
             relation_type: directly_related_work_package_type,
             from: origin,
             to: related_wp)
    end
  end
  let(:directly_related_work_package_type) { relation_type }
  let(:transitively_related_work_package) do
    create(:work_package, project:).tap do |related_wp|
      create(:relation,
             relation_type: transitively_related_work_package_type,
             from: directly_related_work_package,
             to: related_wp)
    end
  end
  let(:transitively_related_work_package_type) { relation_type }

  let(:parent) do
    create(:work_package, project:).tap do |p|
      origin.update(parent: p)
    end
  end
  let(:sibling) do
    create(:work_package, project:, parent:)
  end
  let(:grandparent) do
    create(:work_package, project:).tap do |p|
      parent.update(parent: p)
    end
  end
  let(:aunt) do
    create(:work_package, project:, parent: grandparent)
  end
  let(:origin_child) do
    create(:work_package, project:, parent: origin)
  end
  let(:existing_work_packages) { [] }

  let(:relation_type) { Relation::TYPE_FOLLOWS }

  subject(:relatable) { WorkPackage.relatable(origin, relation_type) }

  it 'is an AR scope' do
    expect(relatable)
      .to be_a ActiveRecord::Relation
  end

  context 'for an unpersisted work package' do
    let(:origin) { WorkPackage.new }
    let!(:existing_work_packages) { [unrelated_work_package] }

    it 'contains every other work package' do
      expect(relatable)
        .to match_array([unrelated_work_package])
    end
  end

  context 'with a completely unrelated work package' do
    let!(:existing_work_packages) { [unrelated_work_package] }

    Relation::TYPES.each_key do |current_type|
      context "for the '#{current_type}' type" do
        let(:relation_type) { current_type }

        it 'contains the unrelated_work_package' do
          expect(relatable)
            .to match_array([unrelated_work_package])
        end
      end

      context "for the '#{current_type}' type with the other project being in a different project " \
              "and having cross project relations disabled", with_settings: { cross_project_work_package_relations: false } do
        let(:relation_type) { current_type }
        let(:unrelated_work_package) { create(:work_package, project: create(:project)) }

        it 'contains the unrelated_work_package' do
          expect(relatable)
            .to be_empty
        end
      end

      context "for the '#{current_type}' type with the other project being in a different project " \
              "and having cross project relations enabled", with_settings: { cross_project_work_package_relations: true } do
        let(:relation_type) { current_type }
        let(:unrelated_work_package) { create(:work_package, project: create(:project)) }

        it 'contains the unrelated_work_package' do
          expect(relatable)
            .to match_array([unrelated_work_package])
        end
      end
    end

    context "for the '#{Relation::TYPE_PARENT}'" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it 'contains the unrelated_work_package' do
        expect(relatable)
          .to match_array([unrelated_work_package])
      end
    end
  end

  context 'with a directly related work package' do
    let!(:existing_work_packages) { [directly_related_work_package] }

    Relation::TYPES.each_key do |current_type|
      context "with the existing relation and the queried being '#{current_type}' typed" do
        let(:relation_type) { current_type }

        it 'is empty' do
          expect(relatable)
            .to be_empty
        end
      end
    end
  end

  context 'with a parent and a sibling' do
    let!(:existing_work_packages) { [parent, sibling] }

    Relation::TYPES.each_key do |current_type|
      context "for the '#{current_type}' type" do
        let(:relation_type) { current_type }

        it 'contains the sibling' do
          expect(relatable)
            .to match_array([sibling])
        end
      end
    end
  end

  context 'with a transitively related work package' do
    let!(:existing_work_packages) { [directly_related_work_package, transitively_related_work_package] }

    context "for a 'follows' relation and the existing relations being in the same direction" do
      it 'contains the transitively related work package' do
        expect(relatable)
          .to match_array([transitively_related_work_package])
      end
    end

    context "for a 'follows' relation and the existing relations being in the opposite direction" do
      let(:directly_related_work_package_type) { Relation::TYPE_PRECEDES }
      let(:transitively_related_work_package_type) { Relation::TYPE_PRECEDES }

      it 'is empty' do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'precedes' relation and the existing relations being in the opposite direction" do
      let(:relation_type) { Relation::TYPE_PRECEDES }
      let(:directly_related_work_package_type) { Relation::TYPE_FOLLOWS }
      let(:transitively_related_work_package_type) { Relation::TYPE_FOLLOWS }

      it 'is empty' do
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

      it 'is empty' do
        expect(relatable)
          .to match_array [origin]
      end
    end
  end

  context "with a child" do
    let!(:existing_work_packages) { [origin_child] }

    Relation::TYPES.each_key do |current_type|
      context "for a '#{current_type}' type" do
        let(:relation_type) { current_type }

        it 'is empty' do
          expect(relatable)
            .to be_empty
        end
      end
    end
  end

  context "with two parent child pairs connected by a relation" do
    let(:other_parent) do
      create(:work_package, project:)
    end
    let(:other_child) do
      create(:work_package, project:, parent: other_parent).tap do |wp|
        create(:relation, from: wp, to: origin_child, relation_type: other_relation_type)
      end
    end
    let!(:existing_work_packages) { [origin_child, other_parent, other_child] }

    context "for a 'follows' and the existing relation being a follows in the opposite direction" do
      let(:other_relation_type) { Relation::TYPE_FOLLOWS }
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it 'is empty' do
        expect(relatable)
          .to be_empty
      end
    end

    context "for a 'follows' and the existing relation being a follows in the same direction" do
      # Using precedes will lead to the relation being reversed
      let(:other_relation_type) { Relation::TYPE_PRECEDES }
      let(:relation_type) { Relation::TYPE_FOLLOWS }

      it 'contains the work packages in the other hierarchy' do
        expect(relatable)
          .to match_array [other_parent, other_child]
      end
    end
  end

  context 'with a child, parent, grandparent and aunt' do
    let!(:existing_work_packages) { [origin, origin_child, parent, grandparent, aunt] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it 'contains grandparent and aunt' do
        expect(relatable)
          .to match_array [grandparent, aunt]
      end
    end

    context "for a 'parent' relation with a follows relation between child and aunt" do
      let(:relation_type) { Relation::TYPE_PARENT }

      before do
        create(:follows_relation, from: origin_child, to: aunt)
      end

      it 'contains grandparent' do
        expect(relatable)
          .to match_array [grandparent]
      end
    end

    context "for a 'relates' relation with a follows relation between child and aunt" do
      let(:relation_type) { Relation::TYPE_RELATES }

      before do
        create(:follows_relation, from: origin_child, to: aunt)
      end

      it 'contains aunt' do
        expect(relatable)
          .to match_array [aunt]
      end
    end
  end

  context 'with an ancestor chain of 3 work packages' do
    let(:grand_grandparent) do
      create(:work_package, project:).tap do |par|
        grandparent.update(parent: par)
      end
    end

    let!(:existing_work_packages) { [parent, grandparent, grand_grandparent] }

    context "for a 'parent' relation" do
      let(:relation_type) { Relation::TYPE_PARENT }

      it 'contains grandparent and grand_grandparent' do
        expect(relatable)
          .to match_array [grandparent, grand_grandparent]
      end
    end
  end
end
